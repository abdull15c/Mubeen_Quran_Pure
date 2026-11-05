import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../audio/quran_audio_service.dart';
import '../models/quran_models.dart';
import '../recitation/quran_recitation_matcher.dart';
import '../recitation/quran_speech_engine.dart';
import '../recitation/speech_recitation_service.dart';
import '../recitation/tajweed_audio_analyzer.dart';
import '../recitation/tajweed_rule_detector.dart';
import '../theme/app_theme.dart';

class RecitationTrainerSheet extends StatefulWidget {
  const RecitationTrainerSheet({
    super.key,
    required this.surah,
    required this.ayah,
    required this.audioService,
    this.onNextAyah,
  });

  final Surah surah;
  final QuranAyah ayah;
  final QuranAudioService audioService;
  final VoidCallback? onNextAyah;

  static Future<void> show(
    BuildContext context, {
    required Surah surah,
    required QuranAyah ayah,
    required QuranAudioService audioService,
    VoidCallback? onNextAyah,
  }) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD4AF37),
            size: 32,
          ),
          title: Text(l.recitationDisclaimerTitle, textAlign: TextAlign.center),
          content: Text(l.recitationDisclaimerBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.recitationDisclaimerAccept),
            ),
          ],
        );
      },
    );

    if (accepted != true || !context.mounted) return;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return RecitationTrainerSheet(
          surah: surah,
          ayah: ayah,
          audioService: audioService,
          onNextAyah: onNextAyah,
        );
      },
    );
  }

  @override
  State<RecitationTrainerSheet> createState() => _RecitationTrainerSheetState();
}

class _RecitationTrainerSheetState extends State<RecitationTrainerSheet> {
  final SpeechRecitationService _speechService = SpeechRecitationService();

  late QuranAyah _currentAyah;
  List<QuranAyah> _surahAyahs = <QuranAyah>[];
  late List<AyahWordToken> _tokens;
  late Map<int, List<TajweedRuleOccurrence>> _tajweedRules;
  RecitationResult? _result;
  bool _hifzMode = false; // Blur text until pronounced correctly
  bool _continuousMode = false; // Continuous live VAD mode

  @override
  void initState() {
    super.initState();
    _currentAyah = widget.ayah;
    _tokens = QuranRecitationMatcher.tokenizeAyah(_currentAyah.text);
    _tajweedRules = TajweedRuleDetector.analyzeAyah(_currentAyah.text);
    _speechService.addListener(_onSpeechStateChanged);
    _speechService.initialize();
    _loadSurahAyahs();
  }

  void _onSpeechStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant RecitationTrainerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayah.id != widget.ayah.id) {
      _setAyah(widget.ayah);
    }
  }

  Future<void> _loadSurahAyahs() async {
    try {
      final List<QuranAyah> ayahs = await widget.audioService.repository
          .getAyahsForSurah(widget.surah.id, 'kuliev');
      if (mounted) {
        setState(() {
          _surahAyahs = ayahs;
        });
      }
    } catch (_) {}
  }

  void _setAyah(QuranAyah ayah) {
    setState(() {
      _currentAyah = ayah;
      _tokens = QuranRecitationMatcher.tokenizeAyah(ayah.text);
      _tajweedRules = TajweedRuleDetector.analyzeAyah(ayah.text);
      _result = null;
    });
    _speechService.setExpectedAyahText(ayah.text);
  }

  bool get _canAdvanceToNextAyah {
    if (widget.onNextAyah != null) return true;
    if (_surahAyahs.isNotEmpty) {
      final int currentIndex = _surahAyahs.indexWhere(
        (QuranAyah a) => a.number == _currentAyah.number,
      );
      return currentIndex >= 0 && currentIndex + 1 < _surahAyahs.length;
    }
    return false;
  }

  void _advanceToNextAyah() {
    if (_surahAyahs.isNotEmpty) {
      final int currentIndex = _surahAyahs.indexWhere(
        (QuranAyah a) => a.number == _currentAyah.number,
      );
      if (currentIndex >= 0 && currentIndex + 1 < _surahAyahs.length) {
        final QuranAyah nextAyah = _surahAyahs[currentIndex + 1];
        _setAyah(nextAyah);
        widget.onNextAyah?.call();
        return;
      } else {
        // Last Ayah in the Surah reached - stop continuous listening
        if (_continuousMode && _speechService.isListening) {
          _speechService.stopListening();
        }
      }
    }
    widget.onNextAyah?.call();
  }

  void _onRecognizedSpeech(SpeechResult result) {
    if (!mounted) return;
    setState(() {
      if (result.hasTimestamps) {
        _result = QuranRecitationMatcher.evaluateWithTimestamps(
          tokens: _tokens,
          speechResult: result,
          tajweedRules: _tajweedRules,
        );
      } else {
        _result = QuranRecitationMatcher.evaluateSpokenText(
          tokens: _tokens,
          recognizedArabicSpeech: result.fullText,
        );
      }
    });

    if (_result?.isCompleted == true) {
      HapticFeedback.mediumImpact().ignore();
      if (_continuousMode) {
        // Мгновенный переход к следующему аяту без задержки
        if (mounted && _continuousMode && _speechService.isListening) {
          _advanceToNextAyah();
        }
      } else if (_speechService.isListening) {
        _speechService.stopListening();
      }
    }
  }

  void _onContinuousChunk(SpeechResult result) {
    if (!mounted) return;
    _onRecognizedSpeech(result);
  }

  bool _isStarting = false;

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact().ignore();
    if (_isStarting) return;

    if (_speechService.isProcessing) {
      // Allow user to cancel while processing
      await _speechService.cancelListening();
      return;
    }

    if (_speechService.isListening) {
      await _speechService.stopListening(
        onResult: _onRecognizedSpeech,
        expectedText: _currentAyah.text,
      );
      return;
    }

    if (!_speechService.isWhisperAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Сервер распознавания речи не настроен (отсутствует ключ API).',
          ),
        ),
      );
      return;
    }

    if (widget.audioService.isPlaying) {
      await widget.audioService.pause();
    }

    _isStarting = true;
    try {
      if (_continuousMode) {
        await _speechService.startContinuousRecitation(
          onChunkRecognized: _onContinuousChunk,
          expectedText: _currentAyah.text,
        );
      } else {
        await _speechService.startListening(
          onRecognized: _onRecognizedSpeech,
          expectedText: _currentAyah.text,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _resetAyah() async {
    HapticFeedback.lightImpact().ignore();
    await _speechService.cancelListening();
    if (!mounted) return;
    setState(() {
      QuranRecitationMatcher.resetTokens(_tokens);
      _result = null;
    });
  }

  void _showAyahTajweedSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final AppLocalizations l = AppLocalizations.of(context)!;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.quranColors.gold.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.tajweedRules,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_tajweedRules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'В этом аяте нет сложных правил Мадда или Калькаля.',
                      ),
                    )
                  else
                    ..._tajweedRules.values
                        .expand((List<TajweedRuleOccurrence> list) => list)
                        .map(
                          (TajweedRuleOccurrence rule) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: rule.rule.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: rule.rule.color.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: rule.rule.color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    rule.rule.nameArabic,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        rule.rule.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        rule.explanation,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.quranColors.ink
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onWordTapped(int index) {
    if (index < 0 || index >= _tokens.length) return;
    final AyahWordToken token = _tokens[index];
    final List<TajweedRuleOccurrence>? rules = _tajweedRules[index];
    HapticFeedback.selectionClick().ignore();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            token.originalText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: context.quranType.arabicFamily,
              fontSize: 34,
              color: context.quranColors.gold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (token.mismatchHint != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x22C62828),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x66C62828)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFC62828),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          token.mismatchHint!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (rules != null && rules.isNotEmpty) ...<Widget>[
                ...rules.map(
                  (TajweedRuleOccurrence rule) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: rule.rule.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: rule.rule.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: rule.rule.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rule.rule.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: rule.rule.color,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rule.explanation,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Слово ${index + 1} из ${_tokens.length}',
                style: TextStyle(
                  color: context.quranColors.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  token.status = RecitationWordStatus.hinted;
                });
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Открыть слово'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: context.quranColors.deepGreen,
                foregroundColor: const Color(0xFFE3C47D),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                widget.audioService.playAyah(
                  _currentAyah.surah,
                  _currentAyah.number,
                  totalAyahsInSurah: widget.surah.ayahCount,
                );
              },
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              label: const Text('Послушать аят'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _speechService.removeListener(_onSpeechStateChanged);
    _speechService.cancelListening();
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool isCompleted = _result?.isCompleted == true;
    final int accuracy = _result?.scorePercentage ?? 0;

    // Find first active mismatch hint if any
    final String? activeHint = _tokens
        .cast<AyahWordToken?>()
        .firstWhere(
          (AyahWordToken? t) => t?.mismatchHint != null,
          orElse: () => null,
        )
        ?.mismatchHint;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: context.quranColors.gold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.mic_rounded,
                            size: 18,
                            color: Color(0xFFE3C47D),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.hifzTrainerTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AI Whisper Turbo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.hifzAyahInfo(
                          widget.surah.id,
                          widget.surah.nameRussian,
                          _currentAyah.number,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.quranColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l.tajweedRules,
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFE3C47D),
                    ),
                    onPressed: _showAyahTajweedSheet,
                  ),
                  IconButton(
                    tooltip: l.close,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Mode toggle row (Hifz Memory Mode + Continuous VAD Stream)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.selectionClick().ignore();
                        setState(() => _hifzMode = !_hifzMode);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _hifzMode
                              ? context.quranColors.gold.withValues(alpha: 0.18)
                              : context.quranColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _hifzMode
                                ? context.quranColors.gold
                                : context.quranColors.gold.withValues(
                                    alpha: 0.25,
                                  ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              _hifzMode
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 16,
                              color: context.quranColors.gold,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _hifzMode ? l.byMemory : l.withText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.selectionClick().ignore();
                        if (_speechService.isListening) {
                          _speechService.cancelListening();
                        }
                        setState(() => _continuousMode = !_continuousMode);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _continuousMode
                              ? const Color(0x224CAF50)
                              : context.quranColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _continuousMode
                                ? const Color(0xFF4CAF50)
                                : context.quranColors.gold.withValues(
                                    alpha: 0.25,
                                  ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.all_inclusive_rounded,
                              size: 16,
                              color: _continuousMode
                                  ? const Color(0xFF4CAF50)
                                  : context.quranColors.gold,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _continuousMode
                                    ? l.continuousMode
                                    : l.oneAyahMode,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _continuousMode
                                      ? const Color(0xFF4CAF50)
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            // Main word-by-word recitation area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Column(
                  children: <Widget>[
                    // Word chips
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 10,
                        children: List<Widget>.generate(_tokens.length, (
                          int i,
                        ) {
                          final AyahWordToken token = _tokens[i];
                          final List<TajweedRuleOccurrence>? rules =
                              _tajweedRules[i];
                          return _WordRecitationChip(
                            token: token,
                            tajweedRules: rules,
                            hifzMode: _hifzMode,
                            onTap: () => _onWordTapped(i),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Live Mahraj guidance tip card
                    if (activeHint != null) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x1EF57C00),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x66F57C00)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Color(0xFFF57C00),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                activeHint,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    // Completion celebration card
                    if (isCompleted) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0x221B5E20),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF2E7D32),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Color(0xFF4CAF50),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.perfectReading,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.readingAccuracy(
                                accuracy,
                                _result?.correctCount ?? 0,
                                _result?.totalWords ?? 0,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_canAdvanceToNextAyah) ...<Widget>[
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  _advanceToNextAyah();
                                },
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Text(l.nextAyah),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    // Recognized text transcript
                    if (_speechService
                        .lastRecognizedText
                        .isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.quranColors.paper,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.hearing_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.aiListening(
                                  _speechService.lastRecognizedText,
                                ),
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.quranColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_speechService.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x11D32F2F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x44D32F2F)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: Color(0xFFD32F2F),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _speechService.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD32F2F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom control bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: context.quranColors.paper,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: context.quranColors.gold.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // Reset button
                  IconButton(
                    tooltip: l.startOver,
                    icon: const Icon(Icons.replay_rounded, size: 24),
                    onPressed: _resetAyah,
                  ),
                  // Big Mic Button with sound pulse
                  ListenableBuilder(
                    listenable: _speechService,
                    builder: (BuildContext context, _) {
                      final bool isListening = _speechService.isListening;
                      final bool isProcessing = _speechService.isProcessing;
                      return Semantics(
                        button: true,
                        label: isProcessing
                            ? 'Идет обработка'
                            : isListening
                            ? 'Остановить запись'
                            : 'Начать запись',
                        child: GestureDetector(
                          onTap: _isStarting ? null : _toggleListening,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isProcessing
                                  ? const Color(0xFFF57C00)
                                  : isListening
                                  ? const Color(0xFFD32F2F)
                                  : context.quranColors.gold,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: isProcessing
                                      ? const Color(0x88F57C00)
                                      : isListening
                                      ? const Color(0x88D32F2F)
                                      : const Color(0x66E3C47D),
                                  blurRadius: isListening ? 18 : 10,
                                  spreadRadius: isListening ? 4 : 1,
                                ),
                              ],
                            ),
                            child: isProcessing
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isListening
                                        ? Icons.stop_rounded
                                        : Icons.mic_none_rounded,
                                    color: isListening
                                        ? Colors.white
                                        : Colors.black,
                                    size: 32,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Listen to Sheikh button
                  IconButton(
                    tooltip: l.listenToAyah,
                    icon: const Icon(Icons.volume_up_rounded, size: 24),
                    onPressed: () {
                      HapticFeedback.lightImpact().ignore();
                      widget.audioService.playAyah(
                        _currentAyah.surah,
                        _currentAyah.number,
                        totalAyahsInSurah: widget.surah.ayahCount,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordRecitationChip extends StatelessWidget {
  const _WordRecitationChip({
    required this.token,
    this.tajweedRules,
    required this.hifzMode,
    required this.onTap,
  });

  final AyahWordToken token;
  final List<TajweedRuleOccurrence>? tajweedRules;
  final bool hifzMode;
  final VoidCallback onTap;

  static Color _maddQualityColor(MaddQuality quality) {
    switch (quality) {
      case MaddQuality.informational:
        return const Color(0xFFD4AF37).withValues(alpha: 0.85);
      case MaddQuality.perfect:
        return const Color(0xFF2E7D32);
      case MaddQuality.underExtended:
        return const Color(0xFFF57C00);
      case MaddQuality.overExtended:
        return const Color(0xFFD32F2F);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    final bool isBlurred =
        hifzMode &&
        token.status != RecitationWordStatus.correct &&
        token.status != RecitationWordStatus.hinted;

    switch (token.status) {
      case RecitationWordStatus.correct:
        bg = const Color(0xFF2E7D32);
        fg = Colors.white;
        break;
      case RecitationWordStatus.mismatch:
        bg = const Color(0xFFC62828);
        fg = Colors.white;
        break;
      case RecitationWordStatus.active:
        bg = const Color(0x33E3C47D);
        fg = context.quranColors.ink;
        border = Border.all(color: const Color(0xFFE3C47D), width: 2);
        break;
      case RecitationWordStatus.hinted:
        bg = const Color(0x44E3C47D);
        fg = context.quranColors.ink;
        break;
      case RecitationWordStatus.pending:
        bg = context.quranColors.paper;
        fg = context.quranColors.ink;
        break;
    }

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          token.originalText,
          style: TextStyle(
            fontFamily: context.quranType.arabicFamily,
            fontSize: 22,
            color: fg,
            height: 1.5,
          ),
        ),
        if (token.maddEval != null && !isBlurred)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _maddQualityColor(token.maddEval!.quality),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${token.maddEval!.actualSec.toStringAsFixed(1)} с',
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );

    if (isBlurred) {
      content = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: content,
      );
    }

    final bool hasTajweed = tajweedRules != null && tajweedRules!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border:
                  border ??
                  Border.all(
                    color: context.quranColors.gold.withValues(alpha: 0.25),
                  ),
            ),
            child: content,
          ),
          if (hasTajweed && !isBlurred)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tajweedRules!.first.rule.color,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: tajweedRules!.first.rule.color.withValues(
                        alpha: 0.6,
                      ),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
