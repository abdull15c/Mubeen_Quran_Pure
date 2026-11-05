import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/audio/quran_audio_downloader.dart';
import 'package:mubeen_quran_pure/audio/quran_audio_models.dart';

void main() {
  group('QuranAudioDownloader Tests', () {
    test('Downloader tracks download progress and cancellation properly', () {
      final QuranAudioDownloader downloader = QuranAudioDownloader();
      final Reciter reciter = kAvailableReciters.first;

      expect(downloader.isDownloading(reciter.subfolder, 1), false);
      expect(downloader.getProgress(reciter.subfolder, 1), 0.0);

      // Cancel should be safe and idempotent
      downloader.cancelDownload(reciter.subfolder, 1);
      expect(downloader.isDownloading(reciter.subfolder, 1), false);
    });

    test('Downloader dispose cleans up and flags isDisposed', () async {
      final QuranAudioDownloader downloader = QuranAudioDownloader();
      final Reciter reciter = kAvailableReciters.first;

      expect(downloader.isDisposed, isFalse);
      downloader.dispose();
      expect(downloader.isDisposed, isTrue);

      // Subsequent actions should be safe and not throw
      downloader.cancelDownload(reciter.subfolder, 1);
      await downloader.downloadSurah(reciter, 1, 7);
      await downloader.deleteSurahDownload(reciter.subfolder, 1);
    });
  });
}
