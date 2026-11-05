import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';
import '../models/quran_models.dart';
import '../theme/app_theme.dart';
import 'quran_audio_models.dart';
import 'quran_audio_service.dart';

class QuranAudioMiniPlayer extends StatelessWidget {
  const QuranAudioMiniPlayer({
    super.key,
    required this.audioService,
    required this.currentSurah,
  });

  final QuranAudioService audioService;
  final Surah? currentSurah;

  void _showReciterPicker(BuildContext context) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.quranColors.gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.mic_rounded),
                      const SizedBox(width: 10),
                      Text(
                        l.selectReciter,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: kAvailableReciters.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Reciter reciter = kAvailableReciters[index];
                      final bool isSelected =
                          audioService.currentReciter.id == reciter.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? context.quranColors.gold
                              : context.quranColors.paper,
                          foregroundColor: isSelected
                              ? Colors.black
                              : context.quranColors.ink,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          reciter.nameRussian,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${reciter.nameArabic} · ${reciter.quality}',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: context.quranColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: context.quranColors.gold,
                              )
                            : null,
                        onTap: () {
                          HapticFeedback.selectionClick().ignore();
                          audioService.setReciter(reciter);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpeedPicker(BuildContext context) {
    const List<double> speeds = <double>[0.75, 1.0, 1.25, 1.5];
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.quranColors.gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.playbackSpeed,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: speeds.map((double speed) {
                    final bool isSelected = audioService.speed == speed;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: ChoiceChip(
                        label: Text('${speed}x'),
                        selected: isSelected,
                        selectedColor: context.quranColors.gold,
                        onSelected: (_) {
                          audioService.setSpeed(speed);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: audioService,
      builder: (BuildContext context, _) {
        if (audioService.currentSurahId == null) {
          return const SizedBox.shrink();
        }

        final int surahId = audioService.currentSurahId!;
        final int ayahNum = audioService.currentAyahNumber ?? 1;
        final String surahName = currentSurah?.id == surahId
            ? currentSurah!.nameRussian
            : 'Сура $surahId';

        return ListenableBuilder(
          listenable: audioService.downloader,
          builder: (BuildContext context, _) {
            final bool isDownloading = audioService.downloader.isDownloading(
              audioService.currentReciter.subfolder,
              surahId,
            );
            final double progress = audioService.downloader.getProgress(
              audioService.currentReciter.subfolder,
              surahId,
            );

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              decoration: BoxDecoration(
                color: context.quranColors.deepGreen,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.quranColors.gold.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          // Reciter chip
                          InkWell(
                            onTap: () => _showReciterPicker(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x33E3C47D),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0x55E3C47D),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.person_rounded,
                                    size: 14,
                                    color: Color(0xFFE3C47D),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    audioService.currentReciter.nameRussian
                                        .split(' ')
                                        .first,
                                    style: const TextStyle(
                                      color: Color(0xFFEAE3D2),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: 16,
                                    color: Color(0xFFE3C47D),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    '$surahName · ${l.ayahNumber(ayahNum)}',
                                    style: const TextStyle(
                                      color: Color(0xFFE3C47D),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (audioService.isPlayingOffline) ...<Widget>[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.download_done_rounded,
                                    size: 16,
                                    color: Color(0xFF81C784),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Download surah button
                          if (isDownloading)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  value: progress > 0 ? progress : null,
                                  strokeWidth: 2,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFE3C47D),
                                      ),
                                ),
                              ),
                            )
                          else
                            IconButton(
                              tooltip: l.downloadSurahOffline,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.download_for_offline_outlined,
                                color: Color(0xFFE3C47D),
                                size: 20,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact().ignore();
                                audioService.downloader.downloadSurah(
                                  audioService.currentReciter,
                                  surahId,
                                  audioService.totalAyahsInCurrentSurah,
                                );
                              },
                            ),
                          // Speed button
                          IconButton(
                            tooltip: l.speed,
                            visualDensity: VisualDensity.compact,
                            icon: Text(
                              '${audioService.speed}x',
                              style: const TextStyle(
                                color: Color(0xFFEAE3D2),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => _showSpeedPicker(context),
                          ),
                          // Repeat button
                          IconButton(
                            tooltip: audioService.repeatAyah
                                ? l.repeatOn
                                : l.repeatOff,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              audioService.repeatAyah
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              color: audioService.repeatAyah
                                  ? const Color(0xFFE3C47D)
                                  : Colors.white54,
                              size: 20,
                            ),
                            onPressed: audioService.toggleRepeatAyah,
                          ),
                          // Close player
                          IconButton(
                            tooltip: l.closePlayer,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: audioService.stop,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Progress and main controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            tooltip: l.prevAyah,
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              color: Color(0xFFEAE3D2),
                              size: 24,
                            ),
                            onPressed: ayahNum > 1
                                ? audioService.playPreviousAyah
                                : null,
                          ),
                          const SizedBox(width: 8),
                          // Play/Pause button
                          Semantics(
                            button: true,
                            label: audioService.isPlaying
                                ? l.pause
                                : l.listenAyah,
                            child: InkWell(
                              onTap: () {
                                if (audioService.isPlaying) {
                                  audioService.pause();
                                } else {
                                  audioService.resume();
                                }
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.quranColors.gold,
                                  boxShadow: const <BoxShadow>[
                                    BoxShadow(
                                      color: Color(0x66E3C47D),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: audioService.isBuffering
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.black,
                                                ),
                                          ),
                                        )
                                      : Icon(
                                          audioService.isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: 26,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: l.nextAyah,
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: Color(0xFFEAE3D2),
                              size: 24,
                            ),
                            onPressed:
                                ayahNum < audioService.totalAyahsInCurrentSurah
                                ? audioService.playNextAyah
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
