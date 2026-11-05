import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../../audio/quran_audio_service.dart';
import '../../models/quran_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/islamic_ornament_painters.dart';
import 'reader_utils.dart';
import 'reader_widgets.dart';

class SurahHeader extends StatelessWidget {
  const SurahHeader({
    super.key,
    required this.surah,
    required this.audioService,
    required this.onJumpToAyah,
  });

  final Surah surah;
  final QuranAudioService audioService;
  final ValueChanged<int> onJumpToAyah;

  void _showAyahPicker(BuildContext context) {
    showAyahPickerSheet(
      context: context,
      surah: surah,
      onSelected: onJumpToAyah,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool isMeccan =
        surah.revelationPlace.toLowerCase().contains('makk') ||
        surah.revelationPlace.toLowerCase().contains('мекк');
    final String placeLabel = isMeccan ? l.meccan : l.medinan;
    final String placeIcon = isMeccan ? '🕋' : '🕌';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: SurahOrnamentFrame(
        primaryGold: context.quranColors.gold,
        deepEmerald: context.quranColors.deepGreen,
        child: Column(
          children: <Widget>[
            Text(
              surah.nameArabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: context.quranColors.gold,
                fontFamily: context.quranType.arabicFamily,
                fontSize: 34,
                height: 1.3,
                shadows: const <Shadow>[
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 4,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x33E3C47D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$placeIcon $placeLabel',
                    style: const TextStyle(
                      color: Color(0xFFEAE3D2),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showAyahPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x22E3C47D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0x55E3C47D),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          l.surahInfoLabel(
                            surah.id,
                            surah.nameRussian,
                            surah.ayahCount,
                          ),
                          style: const TextStyle(
                            color: Color(0xFFEAE3D2),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Color(0xFFE3C47D),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: audioService,
                  builder: (BuildContext context, _) {
                    final bool isCurrentSurahPlaying =
                        audioService.isPlaying &&
                        audioService.currentSurahId == surah.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.lightImpact().ignore();
                        if (isCurrentSurahPlaying) {
                          audioService.pause();
                        } else {
                          audioService.playAyah(
                            surah.id,
                            audioService.currentSurahId == surah.id &&
                                    audioService.currentAyahNumber != null
                                ? audioService.currentAyahNumber!
                                : 1,
                            totalAyahsInSurah: surah.ayahCount,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentSurahPlaying
                              ? const Color(0x44E3C47D)
                              : const Color(0x22E3C47D),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0x55E3C47D),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              isCurrentSurahPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: const Color(0xFFE3C47D),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCurrentSurahPlaying ? l.pause : l.listenSurah,
                              style: const TextStyle(
                                color: Color(0xFFEAE3D2),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (surah.bismillahPre) ...<Widget>[
              const SizedBox(height: 12),
              const Divider(color: Color(0x40E3C47D), height: 1),
              const SizedBox(height: 12),
              Text(
                bismillah,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE3C47D),
                  fontFamily: context.quranType.arabicFamily,
                  fontSize: 22,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
