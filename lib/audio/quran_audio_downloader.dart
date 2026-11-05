import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'quran_audio_models.dart';

class QuranAudioDownloader extends ChangeNotifier {
  QuranAudioDownloader();

  final Map<String, double> _downloadProgress = <String, double>{};
  final Set<String> _activeDownloads = <String>{};

  final Map<String, HttpClient> _activeClients = <String, HttpClient>{};
  bool _disposed = false;

  bool get isDisposed => _disposed;

  bool isDownloading(String reciterSubfolder, int surahId) {
    return _activeDownloads.contains(_cacheKey(reciterSubfolder, surahId));
  }

  double getProgress(String reciterSubfolder, int surahId) {
    return _downloadProgress[_cacheKey(reciterSubfolder, surahId)] ?? 0.0;
  }

  String _cacheKey(String reciterSubfolder, int surahId) =>
      '${reciterSubfolder}_$surahId';

  Future<Directory> getAudioCacheDir(
    String reciterSubfolder,
    int surahId,
  ) async {
    final Directory appDir = await getApplicationSupportDirectory();
    final Directory dir = Directory(
      p.join(appDir.path, 'audio_cache', reciterSubfolder, surahId.toString()),
    );
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<File?> getLocalAyahFile(
    String reciterSubfolder,
    int surahId,
    int ayahNumber,
  ) async {
    try {
      final Directory dir = await getAudioCacheDir(reciterSubfolder, surahId);
      final String s = surahId.toString().padLeft(3, '0');
      final String a = ayahNumber.toString().padLeft(3, '0');
      final File file = File(p.join(dir.path, '$s$a.mp3'));
      if (await file.exists() && (await file.length()) > 1000) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> isSurahDownloaded(
    String reciterSubfolder,
    int surahId,
    int totalAyahs,
  ) async {
    try {
      final Directory dir = await getAudioCacheDir(reciterSubfolder, surahId);
      if (!await dir.exists()) return false;

      for (var a = 1; a <= totalAyahs; a++) {
        final String sStr = surahId.toString().padLeft(3, '0');
        final String aStr = a.toString().padLeft(3, '0');
        final File file = File(p.join(dir.path, '$sStr$aStr.mp3'));
        if (!await file.exists()) return false;
        if (await file.length() < 1000) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void cancelDownload(String reciterSubfolder, int surahId) {
    final String key = _cacheKey(reciterSubfolder, surahId);
    _activeDownloads.remove(key);
    _downloadProgress.remove(key);
    _activeClients[key]?.close(force: true);
    _activeClients.remove(key);
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool _isValidMp3(Uint8List bytes) {
    if (bytes.length < 128) return false;
    // ID3 tag
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) return true;
    // MPEG frame sync
    for (int i = 0; i < bytes.length - 1 && i < 1024; i++) {
      if (bytes[i] == 0xFF && (bytes[i + 1] & 0xE0) == 0xE0) {
        return true;
      }
    }
    return false;
  }

  Future<void> downloadSurah(
    Reciter reciter,
    int surahId,
    int totalAyahs,
  ) async {
    if (_disposed) return;
    final String key = _cacheKey(reciter.subfolder, surahId);
    if (_activeDownloads.contains(key)) return;

    _activeDownloads.add(key);
    _downloadProgress[key] = 0.0;
    notifyListeners();

    final HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    _activeClients[key] = client;

    try {
      final Directory dir = await getAudioCacheDir(reciter.subfolder, surahId);

      for (var a = 1; a <= totalAyahs; a++) {
        if (_disposed || !_activeDownloads.contains(key)) break; // Cancelled

        final String sStr = surahId.toString().padLeft(3, '0');
        final String aStr = a.toString().padLeft(3, '0');
        final File targetFile = File(p.join(dir.path, '$sStr$aStr.mp3'));

        if (!targetFile.existsSync() || targetFile.lengthSync() < 1000) {
          final String url = reciter.getAyahAudioUrl(surahId, a);
          bool success = false;

          // Retry up to 3 times per Ayah
          for (var attempt = 0; attempt < 3; attempt++) {
            if (_disposed || !_activeDownloads.contains(key)) break;
            try {
              final HttpClientRequest request = await client.getUrl(
                Uri.parse(url),
              );
              final HttpClientResponse response = await request.close();

              final String contentType =
                  response.headers.contentType?.mimeType ?? '';
              final bool isAudio =
                  contentType.contains('audio') ||
                  contentType.contains('mpeg') ||
                  contentType.contains('octet-stream') ||
                  contentType.isEmpty;
              final bool isHtml = contentType.contains('text/html');

              if (response.statusCode == 200 && isAudio && !isHtml) {
                final File tempFile = File('${targetFile.path}.tmp');
                final IOSink sink = tempFile.openWrite();
                try {
                  await response.pipe(sink);
                } catch (_) {
                  await sink.close();
                  rethrow;
                }

                if (tempFile.existsSync() && tempFile.lengthSync() > 1000) {
                  final Uint8List sample = Uint8List.fromList(
                    await tempFile.openRead(0, 1024).first,
                  );
                  if (_isValidMp3(sample)) {
                    if (targetFile.existsSync()) targetFile.deleteSync();
                    tempFile.renameSync(targetFile.path);
                    success = true;
                    break; // Success
                  } else {
                    tempFile.deleteSync();
                  }
                }
              } else {
                await response.drain<void>();
                if (isHtml) break; // Don't retry if captive portal
              }
            } catch (e) {
              if (attempt == 2) {
                debugPrint(
                  'Failed to download Ayah $surahId:$a after 3 attempts: $e',
                );
              }
              await Future<void>.delayed(
                Duration(milliseconds: 400 * (attempt + 1)),
              );
            }
          }

          if (!success) {
            if (_disposed || !_activeDownloads.contains(key)) break;
            // Ayah failed, abort download to not report false 100%
            _downloadProgress.remove(key);
            break;
          }
        }

        if (!_disposed && _activeDownloads.contains(key)) {
          _downloadProgress[key] = (a / totalAyahs).clamp(0.0, 1.0);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error downloading surah audio: $e');
    } finally {
      client.close(force: true);
      _activeClients.remove(key);
      _activeDownloads.remove(key);
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> deleteSurahDownload(String reciterSubfolder, int surahId) async {
    try {
      final Directory dir = await getAudioCacheDir(reciterSubfolder, surahId);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
    _downloadProgress.remove(_cacheKey(reciterSubfolder, surahId));
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final HttpClient client in _activeClients.values) {
      client.close(force: true);
    }
    _activeClients.clear();
    _activeDownloads.clear();
    _downloadProgress.clear();
    super.dispose();
  }
}
