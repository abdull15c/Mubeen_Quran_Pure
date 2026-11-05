import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../controllers/app_controller.dart';
import '../data/quran_repository.dart';
import '../data/translation_manager.dart';
import '../models/quran_models.dart';
import '../theme/app_theme.dart';
import 'navigation_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.controller,
    required this.repository,
    this.translationManager,
    required this.onOpenLocation,
  });

  final AppController controller;
  final QuranRepository repository;
  final TranslationManager? translationManager;
  final OpenLocationCallback onOpenLocation;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;
  List<QuranSearchResult> _results = const <QuranSearchResult>[];
  List<ThematicTopic> _topics = const <ThematicTopic>[];
  bool _searching = false;
  String? _error;
  int _searchGeneration = 0;
  int? _startedGeneration;
  String _generationQuery = '';
  late String _translatorKey;

  static const List<String> _quickSuggestions = <String>[
    'Аят аль-Курси',
    'Тяжело на душе',
    'Терпение',
    'Родители',
    'Долги',
    'Ризк',
    '2:255',
    '112:1',
  ];

  @override
  void initState() {
    super.initState();
    _translatorKey = widget.controller.translatorKey;
    widget.controller.addListener(_handleControllerChanged);
    _loadThematicTopics();
  }

  Future<void> _loadThematicTopics() async {
    try {
      final List<ThematicTopic> topics = await widget.repository
          .getThematicTopics();
      if (mounted) {
        setState(() {
          _topics = topics;
        });
      }
    } catch (_) {
      // Fallback to empty list
    }
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    var shouldRestart = oldWidget.repository != widget.repository;
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _translatorKey = widget.controller.translatorKey;
      shouldRestart = true;
    } else if (_translatorKey != widget.controller.translatorKey) {
      _translatorKey = widget.controller.translatorKey;
      shouldRestart = true;
    }
    if (oldWidget.repository != widget.repository) {
      _loadThematicTopics();
    }
    if (shouldRestart) {
      _beginSearch(_queryController.text, debounce: false);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _debounce?.cancel();
    ++_searchGeneration;
    _queryController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final String translatorKey = widget.controller.translatorKey;
    if (_translatorKey == translatorKey) return;
    _translatorKey = translatorKey;
    if (mounted) {
      _beginSearch(_queryController.text, debounce: false);
    }
  }

  void _onQueryChanged(String value) {
    _beginSearch(value, debounce: true);
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    _debounce = null;
    final String query = value.trim();
    if (query != _generationQuery) {
      _beginSearch(value, debounce: false);
      return;
    }
    if (query.isNotEmpty && _startedGeneration == null) {
      unawaited(
        _search(query, _searchGeneration, _translatorKey, widget.repository),
      );
    }
  }

  void _beginSearch(String value, {required bool debounce}) {
    _debounce?.cancel();
    _debounce = null;
    final String query = value.trim();
    final int generation = ++_searchGeneration;
    _startedGeneration = null;
    _generationQuery = query;
    setState(() {
      _results = const <QuranSearchResult>[];
      _searching = query.isNotEmpty;
      _error = null;
    });
    if (query.isEmpty) return;

    if (debounce) {
      final QuranRepository repository = widget.repository;
      final String translatorKey = _translatorKey;
      _debounce = Timer(const Duration(milliseconds: 280), () {
        _debounce = null;
        unawaited(_search(query, generation, translatorKey, repository));
      });
    } else {
      unawaited(_search(query, generation, _translatorKey, widget.repository));
    }
  }

  Future<void> _search(
    String query,
    int generation,
    String translatorKey,
    QuranRepository repository,
  ) async {
    if (!mounted ||
        generation != _searchGeneration ||
        _startedGeneration == generation) {
      return;
    }
    _startedGeneration = generation;
    try {
      final List<QuranSearchResult> results = await repository.search(
        query,
        translatorKey: translatorKey,
      );

      // Also search downloaded translation cache if available
      final TranslationManager? tm = widget.translationManager;
      if (tm != null && query.trim().length >= 2) {
        final List<({int surahId, int ayahNumber, String text})> cachedMatches =
            await tm.searchCachedTranslations(
              translatorKey: translatorKey,
              query: query,
              limit: 40,
            );
        if (cachedMatches.isNotEmpty) {
          final List<QuranSearchResult> cachedResults = await repository
              .getAyahsBySurahAndNumbers(
                cachedMatches
                    .map(
                      (m) => (
                        surahId: m.surahId,
                        ayahNumber: m.ayahNumber,
                        matchText: m.text,
                        sourceKey: translatorKey,
                      ),
                    )
                    .toList(),
              );

          final Set<int> existingAyahIds = results
              .map((QuranSearchResult r) => r.ayahId)
              .toSet();
          final List<QuranSearchResult> combined = List<QuranSearchResult>.from(
            results,
          );
          for (final QuranSearchResult r in cachedResults) {
            if (existingAyahIds.add(r.ayahId)) {
              combined.add(r);
            }
          }
          if (!mounted || generation != _searchGeneration) return;
          if (combined.isNotEmpty) {
            widget.controller.addRecentSearch(query).ignore();
          }
          setState(() {
            _results = combined;
            _searching = false;
          });
          return;
        }
      }

      if (!mounted || generation != _searchGeneration) return;
      if (results.isNotEmpty) {
        widget.controller.addRecentSearch(query).ignore();
      }
      setState(() {
        _results = results;
        _searching = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      _startedGeneration = null;
      setState(() {
        _searching = false;
        _error = error.toString();
      });
    }
  }

  void _applyQuickSuggestion(String suggestion) {
    HapticFeedback.selectionClick();
    _queryController.text = suggestion;
    _queryController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _beginSearch(suggestion, debounce: false);
  }

  void _openTopic(ThematicTopic topic) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _ThematicTopicSheet(
        topic: topic,
        repository: widget.repository,
        translatorKey: _translatorKey,
        onOpenLocation: widget.onOpenLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool isQueryEmpty = _queryController.text.trim().isEmpty;
    final QuranThemeColors colors = context.quranColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.searchInQuran),
        actions: <Widget>[
          if (!isQueryEmpty)
            IconButton(
              tooltip: l.clearAll,
              onPressed: () {
                _queryController.clear();
                _onQueryChanged('');
              },
              icon: const Icon(Icons.clear_all_rounded),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: TextField(
              controller: _queryController,
              autofocus: false,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSubmitted,
              decoration: InputDecoration(
                hintText: l.searchHint,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isQueryEmpty ? colors.muted : colors.gold,
                ),
                suffixIcon: isQueryEmpty
                    ? null
                    : IconButton(
                        tooltip: l.clearAll,
                        onPressed: () {
                          _queryController.clear();
                          _onQueryChanged('');
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
              ),
            ),
          ),
          if (isQueryEmpty &&
              widget.controller.recentSearches.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    l.recentSearches,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: widget.controller.clearRecentSearches,
                    child: Text(
                      l.clearAll,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: widget.controller.recentSearches.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final String recent = widget.controller.recentSearches[index];
                  return InputChip(
                    avatar: Icon(
                      Icons.history_rounded,
                      size: 15,
                      color: colors.muted,
                    ),
                    label: Text(recent, style: const TextStyle(fontSize: 12)),
                    backgroundColor: colors.paper,
                    side: BorderSide(
                      color: colors.gold.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onPressed: () => _applyQuickSuggestion(recent),
                    onDeleted: () =>
                        widget.controller.removeRecentSearch(recent),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (isQueryEmpty) ...<Widget>[
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _quickSuggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final String suggestion = _quickSuggestions[index];
                  return ActionChip(
                    avatar: Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: colors.gold,
                    ),
                    label: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: colors.paper,
                    side: BorderSide(
                      color: colors.gold.withValues(alpha: 0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onPressed: () => _applyQuickSuggestion(suggestion),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ] else if (_topics.isNotEmpty) ...<Widget>[
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _topics.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final ThematicTopic topic = _topics[index];
                  return ActionChip(
                    avatar: Icon(
                      _getTopicIcon(topic.iconName),
                      size: 16,
                      color: colors.gold,
                    ),
                    label: Text(
                      topic.title,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    backgroundColor: colors.paper,
                    side: BorderSide(color: colors.gold.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => _openTopic(topic),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (_searching)
            LinearProgressIndicator(
              minHeight: 2.5,
              color: colors.gold,
              backgroundColor: colors.gold.withValues(alpha: 0.15),
              semanticsLabel: 'Поиск по Корану',
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: _buildResults(context, isQueryEmpty),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, bool isQueryEmpty) {
    if (_error != null) {
      return Center(
        key: const ValueKey<String>('error_view'),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: context.quranColors.muted,
              ),
              const SizedBox(height: 12),
              Text(
                'Поиск временно недоступен.\n$_error',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (isQueryEmpty) {
      return _SearchHint(
        key: const ValueKey<String>('hint_view'),
        translatorKey: widget.controller.translatorKey,
        topics: _topics,
        onTopicSelected: _openTopic,
        onQuickSuggestion: _applyQuickSuggestion,
      );
    }
    if (!_searching && _results.isEmpty) {
      return Center(
        key: const ValueKey<String>('empty_view'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.search_off_rounded,
                size: 52,
                color: context.quranColors.gold.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Совпадений не найдено',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Попробуйте изменить формулировку, ввести ключевое слово или тему (например, «грусть», «терпение», «родители»).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.quranColors.ink.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      key: ValueKey<int>(_searchGeneration),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final QuranSearchResult result = _results[index];
        void openResult() {
          FocusScope.of(context).unfocus();
          widget.onOpenLocation(
            ReaderLocation(
              surahId: result.surahId,
              ayahNumber: result.ayahNumber,
              page: result.page,
            ),
          );
        }

        void copyResult() {
          final String copyText =
              '${result.arabicText}\n\n'
              '${result.matchText}\n'
              'Коран (${result.surahNameRussian} ${result.surahId}:${result.ayahNumber})';
          Clipboard.setData(ClipboardData(text: copyText));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Аят ${result.surahNameRussian} ${result.surahId}:${result.ayahNumber} скопирован',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        final bool isThematic = result.kind == 'thematic';
        final bool isTranslation = result.kind == 'translation';
        final bool isSurah = result.kind == 'surah';
        final bool isSemantic = result.kind == 'semantic';

        final String badgeLabel = switch (result.kind) {
          'thematic' => 'По смыслу',
          'semantic' => 'Векторный',
          'translation' => 'Перевод',
          'surah' => 'Сура',
          _ => 'Аят',
        };

        return Semantics(
          button: true,
          label:
              'Открыть ${result.surahNameRussian}, аят '
              '${result.surahId}:${result.ayahNumber}, страница '
              '${result.page}. ${result.matchText}',
          onTap: openResult,
          excludeSemantics: true,
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: openResult,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '${result.surahNameRussian} · ${result.surahId}:${result.ayahNumber}',
                              style: TextStyle(
                                color: context.quranColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: isThematic
                                    ? context.quranColors.gold.withValues(
                                        alpha: 0.18,
                                      )
                                    : context.quranColors.deepGreen.withValues(
                                        alpha: 0.12,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      (isThematic
                                              ? context.quranColors.gold
                                              : context.quranColors.deepGreen)
                                          .withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                badgeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isThematic
                                      ? context.quranColors.gold
                                      : context.quranColors.deepGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'стр. ${result.page}',
                              style: TextStyle(
                                color: context.quranColors.muted,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Скопировать',
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: copyResult,
                              icon: const Icon(Icons.copy_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      _buildHighlightedText(
                        result.arabicText,
                        _queryController.text,
                        baseStyle: TextStyle(
                          fontFamily: context.quranType.arabicFamily,
                          fontSize: 25,
                          height: 1.8,
                          color: context.quranColors.ink,
                        ),
                        highlightStyle: TextStyle(
                          color: context.quranColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                    if (isTranslation ||
                        isThematic ||
                        isSurah ||
                        isSemantic) ...<Widget>[
                      const SizedBox(height: 10),
                      Text.rich(
                        _buildHighlightedText(
                          result.matchText,
                          _queryController.text,
                          baseStyle: TextStyle(
                            fontFamily: context.quranType.translationFamily,
                            fontSize: 14,
                            height: 1.5,
                            fontStyle: isThematic
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: context.quranColors.ink.withValues(
                              alpha: isThematic ? 0.95 : 0.85,
                            ),
                          ),
                          highlightStyle: TextStyle(
                            color: context.quranColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({
    super.key,
    required this.translatorKey,
    required this.topics,
    required this.onTopicSelected,
    required this.onQuickSuggestion,
  });

  final String translatorKey;
  final List<ThematicTopic> topics;
  final ValueChanged<ThematicTopic> onTopicSelected;
  final ValueChanged<String> onQuickSuggestion;

  @override
  Widget build(BuildContext context) {
    final String translator = switch (translatorKey) {
      'kuliev' => 'Э. Кулиев',
      'abu_adel' => 'Абу Адель',
      'ru_saadi' => 'Тафсир ас-Саади',
      'en_sahih' => 'Saheeh International',
      'tj_mirof' => 'М. О. Османов (TJ)',
      'uz_sodiq' => 'Шайх Муҳаммад Содиқ',
      'az_musayev' => 'Alixan Musayev',
      _ => translatorKey,
    };
    final QuranThemeColors colors = context.quranColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 40,
                  color: colors.gold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Смысловой и точный поиск',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ищите по чувствам («тяжело на душе»), жизненным ситуациям («родители», «долги», «брак»), арабскому тексту, переводу ($translator) или ссылке (2:255).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.ink.withValues(alpha: 0.8),
                  height: 1.4,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
        if (topics.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Icon(Icons.category_outlined, size: 18, color: colors.gold),
              const SizedBox(width: 8),
              Text(
                'Темы и жизненные ситуации',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.1,
            ),
            itemCount: topics.length,
            itemBuilder: (BuildContext context, int index) {
              final ThematicTopic topic = topics[index];
              return Card(
                elevation: 0,
                color: colors.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.gold.withValues(alpha: 0.25)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onTopicSelected(topic),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: colors.gold.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTopicIcon(topic.iconName),
                            size: 20,
                            color: colors.gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                topic.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${topic.ayahCount} аятов',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.ink.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ThematicTopicSheet extends StatefulWidget {
  const _ThematicTopicSheet({
    required this.topic,
    required this.repository,
    required this.translatorKey,
    required this.onOpenLocation,
  });

  final ThematicTopic topic;
  final QuranRepository repository;
  final String translatorKey;
  final OpenLocationCallback onOpenLocation;

  @override
  State<_ThematicTopicSheet> createState() => _ThematicTopicSheetState();
}

class _ThematicTopicSheetState extends State<_ThematicTopicSheet> {
  List<ThematicAyahItem>? _ayahs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAyahs();
  }

  Future<void> _loadAyahs() async {
    try {
      final List<ThematicAyahItem> items = await widget.repository
          .getThematicAyahs(
            widget.topic.id,
            translatorKey: widget.translatorKey,
          );
      if (mounted) {
        setState(() {
          _ayahs = items;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThematicTopic topic = widget.topic;
    final QuranThemeColors colors = context.quranColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: colors.gold.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: colors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTopicIcon(topic.iconName),
                    size: 24,
                    color: colors.gold,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            topic.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              topic.category,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: colors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        topic.description,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.ink.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildAyahsList(context)),
        ],
      ),
    );
  }

  Widget _buildAyahsList(BuildContext context) {
    final QuranThemeColors colors = context.quranColors;

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Ошибка загрузки темы: $_error'),
        ),
      );
    }
    if (_ayahs == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_ayahs!.isEmpty) {
      return const Center(child: Text('В этой теме пока нет аятов'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _ayahs!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (BuildContext context, int index) {
        final ThematicAyahItem item = _ayahs![index];
        final QuranAyah ayah = item.ayah;
        final String? translation = ayah.translations[widget.translatorKey];

        void copyAyah() {
          final String copyText =
              '${ayah.text}\n\n'
              '${translation ?? ""}\n'
              'Коран (Сура ${ayah.surah}, аят ${ayah.number})';
          Clipboard.setData(ClipboardData(text: copyText));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Аят ${ayah.surah}:${ayah.number} скопирован'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.gold.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Сура ${ayah.surah}, аят ${ayah.number}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.gold,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Скопировать',
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          onPressed: copyAyah,
                          icon: const Icon(Icons.copy_rounded),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onOpenLocation(
                              ReaderLocation(
                                surahId: ayah.surah,
                                ayahNumber: ayah.number,
                                page: ayah.page,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                          label: Text('Стр. ${ayah.page}'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (item.note != null && item.note!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.gold.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('💡 ', style: const TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            item.note!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: colors.ink.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  ayah.text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: context.quranType.arabicFamily,
                    fontSize: 24,
                    height: 1.8,
                    color: colors.ink,
                  ),
                ),
                if (translation != null && translation.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    translation,
                    style: TextStyle(
                      fontFamily: context.quranType.translationFamily,
                      fontSize: 14,
                      height: 1.5,
                      color: colors.ink.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

IconData _getTopicIcon(String iconName) {
  return switch (iconName) {
    'spa_rounded' => Icons.spa_rounded,
    'volunteer_activism_rounded' => Icons.volunteer_activism_rounded,
    'balance_rounded' => Icons.balance_rounded,
    'family_restroom_rounded' => Icons.family_restroom_rounded,
    'favorite_rounded' => Icons.favorite_rounded,
    'auto_awesome_rounded' => Icons.auto_awesome_rounded,
    'mosque_rounded' => Icons.mosque_rounded,
    'grain_rounded' => Icons.grain_rounded,
    'receipt_long_rounded' => Icons.receipt_long_rounded,
    'handshake_rounded' => Icons.handshake_rounded,
    'healing_rounded' => Icons.healing_rounded,
    'menu_book_rounded' => Icons.menu_book_rounded,
    'brightness_high_rounded' => Icons.brightness_high_rounded,
    'psychology_rounded' => Icons.psychology_rounded,
    'shield_rounded' => Icons.shield_rounded,
    _ => Icons.bookmark_border_rounded,
  };
}

TextSpan _buildHighlightedText(
  String text,
  String query, {
  required TextStyle baseStyle,
  required TextStyle highlightStyle,
}) {
  final String trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  final _NormalizedText normalizedText = _normalizeForMatching(text);
  final Set<String> terms = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true)
      .allMatches(trimmedQuery)
      .map((RegExpMatch match) => _normalizeForMatching(match.group(0)!).value)
      .where((String term) => term.isNotEmpty)
      .toSet();
  if (terms.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  final List<TextRange> matches = <TextRange>[];
  for (final String term in terms) {
    var searchStart = 0;
    while (searchStart < normalizedText.value.length) {
      final int matchStart = normalizedText.value.indexOf(term, searchStart);
      if (matchStart < 0) break;
      final int matchEnd = matchStart + term.length;
      matches.add(
        TextRange(
          start: normalizedText.originalStarts[matchStart],
          end: normalizedText.originalEnds[matchEnd - 1],
        ),
      );
      searchStart = matchStart + term.length;
    }
  }
  if (matches.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  matches.sort((TextRange first, TextRange second) {
    final int byStart = first.start.compareTo(second.start);
    return byStart != 0 ? byStart : first.end.compareTo(second.end);
  });
  final List<TextRange> mergedMatches = <TextRange>[];
  for (final TextRange match in matches) {
    if (mergedMatches.isEmpty || match.start > mergedMatches.last.end) {
      mergedMatches.add(match);
      continue;
    }
    final TextRange previous = mergedMatches.removeLast();
    mergedMatches.add(
      TextRange(
        start: previous.start,
        end: match.end > previous.end ? match.end : previous.end,
      ),
    );
  }

  final List<InlineSpan> spans = <InlineSpan>[];
  var start = 0;
  for (final TextRange match in mergedMatches) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
    }
    spans.add(
      TextSpan(
        text: text.substring(match.start, match.end),
        style: highlightStyle,
      ),
    );
    start = match.end;
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start)));
  }

  return TextSpan(style: baseStyle, children: spans);
}

final class _NormalizedText {
  const _NormalizedText({
    required this.value,
    required this.originalStarts,
    required this.originalEnds,
  });

  final String value;
  final List<int> originalStarts;
  final List<int> originalEnds;
}

_NormalizedText _normalizeForMatching(String text) {
  final StringBuffer normalized = StringBuffer();
  final List<int> originalStarts = <int>[];
  final List<int> originalEnds = <int>[];
  var originalOffset = 0;

  for (final int rune in text.runes) {
    final int runeLength = rune > 0xFFFF ? 2 : 1;
    final int originalEnd = originalOffset + runeLength;
    final String replacement = _normalizeRune(rune);
    if (replacement.isEmpty) {
      if (originalEnds.isNotEmpty) {
        originalEnds[originalEnds.length - 1] = originalEnd;
      }
    } else {
      normalized.write(replacement);
      for (var index = 0; index < replacement.length; index++) {
        originalStarts.add(originalOffset);
        originalEnds.add(originalEnd);
      }
    }
    originalOffset = originalEnd;
  }

  return _NormalizedText(
    value: normalized.toString(),
    originalStarts: originalStarts,
    originalEnds: originalEnds,
  );
}

String _normalizeRune(int rune) {
  if (rune == 0x0640 ||
      (rune >= 0x0610 && rune <= 0x061A) ||
      (rune >= 0x064B && rune <= 0x065F) ||
      rune == 0x0670 ||
      (rune >= 0x06D6 && rune <= 0x06ED) ||
      (rune >= 0x08D3 && rune <= 0x08FF)) {
    return '';
  }
  return switch (rune) {
    0x0622 || 0x0623 || 0x0625 || 0x0671 => String.fromCharCode(0x0627),
    0x0649 || 0x0626 => String.fromCharCode(0x064A),
    0x0624 => String.fromCharCode(0x0648),
    0x0451 || 0x0401 => 'е',
    _ => String.fromCharCode(rune).toLowerCase(),
  };
}
