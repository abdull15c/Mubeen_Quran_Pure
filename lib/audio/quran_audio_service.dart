import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../data/quran_repository.dart';
import '../models/quran_models.dart';
import 'quran_audio_downloader.dart';
import 'quran_audio_models.dart';

enum AudioRepeatMode { none, repeatAyah, repeatSurah }

class QuranAudioService extends ChangeNotifier {
  QuranAudioService({required this.repository}) {
    _init();
  }

  final QuranRepository repository;
  final AudioPlayer _player = AudioPlayer();
  final QuranAudioDownloader downloader = QuranAudioDownloader();

  Reciter _currentReciter = kAvailableReciters.first;

  int? _currentSurahId;
  int? _currentAyahNumber;
  int _totalAyahsInCurrentSurah = 7;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _repeatAyah = false;
  bool _isPlayingOffline = false;
  double _speed = 1.0;
  Duration _position = Duration.zero;
  Duration _lastNotifiedPosition = Duration.zero;
  Duration _duration = Duration.zero;

  AudioSession? _audioSession;
  bool _wasPlayingBeforeInterruption = false;
  int _playGeneration = 0;
  Future<void>? _playLock;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<void>? _becomingNoisySub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

  final KaraokeTracking _karaoke = KaraokeTracking();
  KaraokeTracking get karaoke => _karaoke;

  Reciter get currentReciter => _currentReciter;
  int? get currentSurahId => _currentSurahId;
  int? get currentAyahNumber => _currentAyahNumber;
  int get totalAyahsInCurrentSurah => _totalAyahsInCurrentSurah;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get repeatAyah => _repeatAyah;
  bool get isPlayingOffline => _isPlayingOffline;
  double get speed => _speed;
  Duration get position => _position;
  Duration get duration => _duration;

  bool isAyahActive(int surahId, int ayahNumber) {
    return _currentSurahId == surahId && _currentAyahNumber == ayahNumber;
  }

  void _init() {
    _initAudioSession();

    _playerStateSub = _player.playerStateStream.listen((PlayerState state) {
      final bool playing = state.playing;
      final ProcessingState processing = state.processingState;

      _isBuffering =
          processing == ProcessingState.buffering ||
          processing == ProcessingState.loading;
      _isPlaying = playing && processing != ProcessingState.completed;

      if (processing == ProcessingState.completed) {
        _handleTrackCompleted();
      }
      notifyListeners();
    });

    // Throttle position notifications to reduce redundant widget rebuilds
    _positionSub = _player.positionStream.listen((Duration pos) {
      _position = pos;
      _karaoke.updatePosition(pos.inMilliseconds);
      if ((_position - _lastNotifiedPosition).inMilliseconds.abs() >= 500) {
        _lastNotifiedPosition = _position;
        notifyListeners();
      }
    });

    _durationSub = _player.durationStream.listen((Duration? dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
  }

  Future<void> _initAudioSession() async {
    try {
      final AudioSession session = await AudioSession.instance;
      _audioSession = session;
      await session.configure(const AudioSessionConfiguration.speech());

      _becomingNoisySub = session.becomingNoisyEventStream.listen((_) {
        pause();
      });

      _interruptionSub = session.interruptionEventStream.listen((
        AudioInterruptionEvent event,
      ) {
        if (event.begin) {
          _wasPlayingBeforeInterruption = _isPlaying;
          pause();
        } else {
          switch (event.type) {
            case AudioInterruptionType.pause:
            case AudioInterruptionType.duck:
              if (_wasPlayingBeforeInterruption) {
                resume();
              }
              _wasPlayingBeforeInterruption = false;
              break;
            case AudioInterruptionType.unknown:
              _wasPlayingBeforeInterruption = false;
              break;
          }
        }
      });
    } catch (e) {
      debugPrint('AudioSession initialization error: $e');
    }
  }

  Future<void> setReciter(Reciter reciter) async {
    if (_currentReciter == reciter) return;
    _currentReciter = reciter;
    _karaoke.clear();
    notifyListeners();

    if (_currentSurahId != null && _currentAyahNumber != null && _isPlaying) {
      await playAyah(
        _currentSurahId!,
        _currentAyahNumber!,
        totalAyahsInSurah: _totalAyahsInCurrentSurah,
      );
    }
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _player.setSpeed(_speed);
    notifyListeners();
  }

  void toggleRepeatAyah() {
    _repeatAyah = !_repeatAyah;
    notifyListeners();
  }

  Future<T> _runPlayLocked<T>(Future<T> Function() action) async {
    final Future<void>? previous = _playLock;
    final Completer<void> completer = Completer<void>();
    _playLock = completer.future;
    try {
      if (previous != null) {
        await previous;
      }
      return await action();
    } finally {
      completer.complete();
      if (identical(_playLock, completer.future)) {
        _playLock = null;
      }
    }
  }

  Future<void> playAyah(
    int surahId,
    int ayahNumber, {
    required int totalAyahsInSurah,
  }) async {
    final int gen = ++_playGeneration;
    return _runPlayLocked(() async {
      if (gen != _playGeneration) return;
      try {
        _currentSurahId = surahId;
        _currentAyahNumber = ayahNumber;
        _totalAyahsInCurrentSurah = totalAyahsInSurah;
        _isBuffering = true;
        _karaoke.clear();
        notifyListeners();

        final File? localFile = await downloader.getLocalAyahFile(
          _currentReciter.subfolder,
          surahId,
          ayahNumber,
        );
        if (gen != _playGeneration) return;

        final MediaItem mediaItem = MediaItem(
          id: '${_currentReciter.id}_${surahId}_$ayahNumber',
          album: 'Коран',
          title: 'Сура $surahId · Аят $ayahNumber',
          artist: _currentReciter.nameRussian,
        );

        final AudioSource source = localFile != null && localFile.existsSync()
            ? AudioSource.file(localFile.path, tag: mediaItem)
            : AudioSource.uri(
                Uri.parse(_currentReciter.getAyahAudioUrl(surahId, ayahNumber)),
                tag: mediaItem,
              );

        _isPlayingOffline = localFile != null && localFile.existsSync();
        await _player.setAudioSource(source);
        if (gen != _playGeneration) return;

        await _audioSession?.setActive(true);
        if (gen != _playGeneration) return;
        await _player.setSpeed(_speed);
        if (gen != _playGeneration) return;
        _player.play().ignore();
      } catch (e) {
        if (gen == _playGeneration) {
          _isBuffering = false;
          _isPlaying = false;
          notifyListeners();
        }
        debugPrint('Error playing Quran audio: $e');
      }
    });
  }

  Future<void> playNextAyah() async {
    final int? surahId = _currentSurahId;
    final int? ayahNum = _currentAyahNumber;
    if (surahId == null || ayahNum == null) return;
    if (ayahNum < _totalAyahsInCurrentSurah) {
      await playAyah(
        surahId,
        ayahNum + 1,
        totalAyahsInSurah: _totalAyahsInCurrentSurah,
      );
    } else if (surahId < 114) {
      final int gen = _playGeneration;
      try {
        final Surah nextSurah = await repository.getSurah(surahId + 1);
        if (gen != _playGeneration) return;
        await playAyah(nextSurah.id, 1, totalAyahsInSurah: nextSurah.ayahCount);
      } catch (_) {
        if (gen == _playGeneration) {
          await stop();
        }
      }
    } else {
      await stop();
    }
  }

  Future<void> playPreviousAyah() async {
    final int? surahId = _currentSurahId;
    final int? ayahNum = _currentAyahNumber;
    if (surahId == null || ayahNum == null) return;
    if (ayahNum > 1) {
      await playAyah(
        surahId,
        ayahNum - 1,
        totalAyahsInSurah: _totalAyahsInCurrentSurah,
      );
    } else if (surahId > 1) {
      final int gen = _playGeneration;
      try {
        final Surah prevSurah = await repository.getSurah(surahId - 1);
        if (gen != _playGeneration) return;
        await playAyah(
          prevSurah.id,
          prevSurah.ayahCount,
          totalAyahsInSurah: prevSurah.ayahCount,
        );
      } catch (_) {
        if (gen == _playGeneration) {
          await stop();
        }
      }
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    _player.play().ignore();
  }

  Future<void> stop() async {
    _playGeneration++;
    await _player.stop();
    _audioSession?.setActive(false).ignore();
    _currentSurahId = null;
    _currentAyahNumber = null;
    _isPlaying = false;
    _isBuffering = false;
    _karaoke.clear();
    notifyListeners();
  }

  void _handleTrackCompleted() {
    if (_repeatAyah && _currentSurahId != null && _currentAyahNumber != null) {
      playAyah(
        _currentSurahId!,
        _currentAyahNumber!,
        totalAyahsInSurah: _totalAyahsInCurrentSurah,
      );
      return;
    }

    playNextAyah();
  }

  @override
  void dispose() {
    _playGeneration++;
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _becomingNoisySub?.cancel();
    _interruptionSub?.cancel();
    _audioSession?.setActive(false).ignore();
    _player.dispose();
    downloader.dispose();
    _karaoke.dispose();
    super.dispose();
  }
}

/// Tracks real-time word highlighting progress based on audio timestamps.
class KaraokeTracking extends ChangeNotifier {
  List<WordTiming>? _timings;
  int? _activeWordIndex;

  int? get activeWordIndex => _activeWordIndex;

  /// Loads timings for the current ayah.
  void setTimings(List<WordTiming>? timings) {
    _timings = timings;
    _activeWordIndex = null;
    notifyListeners();
  }

  /// Called every time the audio player position changes.
  void updatePosition(int currentMs) {
    if (_timings == null || _timings!.isEmpty) {
      if (_activeWordIndex != null) {
        _activeWordIndex = null;
        notifyListeners();
      }
      return;
    }

    int? newIndex;
    for (int i = 0; i < _timings!.length; i++) {
      final WordTiming t = _timings![i];
      // Include a slight margin (e.g. 50ms) to ensure smooth transitions
      if (currentMs >= t.startMs && currentMs <= (t.endMs + 50)) {
        newIndex = i;
        break;
      }
    }

    if (_activeWordIndex != newIndex) {
      _activeWordIndex = newIndex;
      notifyListeners();
    }
  }

  void clear() {
    _timings = null;
    if (_activeWordIndex != null) {
      _activeWordIndex = null;
      notifyListeners();
    }
  }
}
