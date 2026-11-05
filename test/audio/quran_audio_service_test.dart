import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:mubeen_quran_pure/audio/quran_audio_service.dart';
import 'package:mubeen_quran_pure/data/quran_repository.dart';
import 'package:mubeen_quran_pure/models/quran_models.dart';
import 'package:mubeen_quran_pure/search/semantic_search.dart';

class FakeQuranRepository extends QuranRepository {
  FakeQuranRepository() : super(semanticSearch: _FakeSemanticSearch());

  final Map<int, Surah> _surahs = {
    1: const Surah(
      id: 1,
      nameArabic: 'الفاتحة',
      nameTranslit: 'Al-Fatihah',
      nameRussian: 'Открывающая',
      revelationPlace: 'meccan',
      ayahCount: 7,
      revelationOrder: 5,
      bismillahPre: false,
    ),
    2: const Surah(
      id: 2,
      nameArabic: 'البقرة',
      nameTranslit: 'Al-Baqarah',
      nameRussian: 'Корова',
      revelationPlace: 'medinan',
      ayahCount: 286,
      revelationOrder: 87,
      bismillahPre: true,
    ),
  };

  @override
  Future<Surah> getSurah(int id) async {
    if (_surahs.containsKey(id)) {
      return _surahs[id]!;
    }
    throw StateError('Surah $id not found in fake.');
  }

  @override
  Future<void> open() async {}
  @override
  Future<void> close() async {}
}

class _FakeSemanticSearch implements SemanticSearch {
  @override
  Future<List<SemanticHit>> search(String query, {int limit = 120}) async => [];
  @override
  Future<void> close() async {}
}

class FakeJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return FakeAudioPlayerPlatform(request.id);
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    return DisposeAllPlayersResponse();
  }
}

class FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  FakeAudioPlayerPlatform(super.id);

  final StreamController<PlaybackEventMessage> _eventController =
      StreamController<PlaybackEventMessage>.broadcast();

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    _eventController.add(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        duration: const Duration(seconds: 5),
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      ),
    );
    return LoadResponse(duration: const Duration(seconds: 5));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    return PauseResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    return SetVolumeResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    return SetSpeedResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async {
    return SetShuffleModeResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    return SeekResponse();
  }

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async {
    return SetAndroidAudioAttributesResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _eventController.close();
    return DisposeResponse();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  JustAudioPlatform.instance = FakeJustAudioPlatform();

  group('QuranAudioService Tests', () {
    late QuranAudioService service;
    late FakeQuranRepository fakeRepository;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_session'),
            (MethodCall methodCall) async {
              return null;
            },
          );

      fakeRepository = FakeQuranRepository();
      service = QuranAudioService(repository: fakeRepository);
    });

    tearDown(() {
      service.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_session'),
            null,
          );
    });

    test('initial state is correct', () {
      expect(service.isPlaying, isFalse);
      expect(service.currentSurahId, isNull);
      expect(service.currentAyahNumber, isNull);
      expect(service.speed, 1.0);
      expect(service.repeatAyah, isFalse);
    });

    test('toggleRepeatAyah toggles state', () {
      expect(service.repeatAyah, isFalse);
      service.toggleRepeatAyah();
      expect(service.repeatAyah, isTrue);
      service.toggleRepeatAyah();
      expect(service.repeatAyah, isFalse);
    });

    test('playAyah sets state before platform error', () async {
      await service.playAyah(1, 1, totalAyahsInSurah: 7);

      expect(service.currentSurahId, 1);
      expect(service.currentAyahNumber, 1);
      expect(service.totalAyahsInCurrentSurah, 7);
    });

    test('playNextAyah progresses to next ayah in same surah', () async {
      await service.playAyah(1, 2, totalAyahsInSurah: 7);
      expect(service.currentAyahNumber, 2);

      await service.playNextAyah();
      expect(service.currentSurahId, 1);
      expect(service.currentAyahNumber, 3);
    });

    test('playNextAyah advances to next surah automatically', () async {
      await service.playAyah(1, 7, totalAyahsInSurah: 7);
      expect(service.currentAyahNumber, 7);

      await service.playNextAyah();

      expect(service.currentSurahId, 2);
      expect(service.currentAyahNumber, 1);
      expect(service.totalAyahsInCurrentSurah, 286);
    });

    test('playPreviousAyah returns to previous surah automatically', () async {
      await service.playAyah(2, 1, totalAyahsInSurah: 286);
      expect(service.currentAyahNumber, 1);

      await service.playPreviousAyah();

      expect(service.currentSurahId, 1);
      expect(service.currentAyahNumber, 7);
      expect(service.totalAyahsInCurrentSurah, 7);
    });

    test('pause and stop reset active ayah location', () async {
      await service.playAyah(1, 1, totalAyahsInSurah: 7);
      expect(service.currentSurahId, 1);

      await service.pause();
      expect(service.currentSurahId, 1);
      expect(service.currentAyahNumber, 1);

      await service.stop();
      expect(service.currentSurahId, isNull);
      expect(service.currentAyahNumber, isNull);
      expect(service.isPlaying, isFalse);
    });

    test(
      'calling stop during async playAyah cancels playback and does not leave active ayah',
      () async {
        final Future<void> playFuture = service.playAyah(
          1,
          1,
          totalAyahsInSurah: 7,
        );
        await service.stop();
        await playFuture;

        expect(service.currentSurahId, isNull);
        expect(service.currentAyahNumber, isNull);
        expect(service.isPlaying, isFalse);
      },
    );

    test(
      'rapid concurrent playAyah requests serialize cleanly with latest request winning',
      () async {
        final Future<void> play1 = service.playAyah(1, 1, totalAyahsInSurah: 7);
        final Future<void> play2 = service.playAyah(1, 2, totalAyahsInSurah: 7);
        final Future<void> play3 = service.playAyah(1, 3, totalAyahsInSurah: 7);

        await Future.wait([play1, play2, play3]);

        expect(service.currentSurahId, 1);
        expect(service.currentAyahNumber, 3);
      },
    );
  });
}
