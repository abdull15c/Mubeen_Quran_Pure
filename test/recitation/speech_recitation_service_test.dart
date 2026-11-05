import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/recitation/audio_recorder_service.dart';
import 'package:mubeen_quran_pure/recitation/quran_speech_engine.dart';
import 'package:mubeen_quran_pure/recitation/speech_recitation_service.dart';
import 'package:mubeen_quran_pure/recitation/whisper_api_engine.dart';

class FakeWhisperEngine extends WhisperApiEngine {
  FakeWhisperEngine({this.recognizeDelay = Duration.zero, this.resultToReturn})
    : super(apiKey: 'fake-key');

  final Duration recognizeDelay;
  SpeechResult? resultToReturn;
  int recognizeCalls = 0;
  bool cancelled = false;

  @override
  Future<SpeechResult> recognize(
    Uint8List audioWav, {
    String? expectedText,
  }) async {
    recognizeCalls++;
    if (recognizeDelay > Duration.zero) {
      await Future<void>.delayed(recognizeDelay);
    }
    if (cancelled) {
      return const SpeechResult(fullText: '', confidence: 0);
    }
    return resultToReturn ??
        const SpeechResult(fullText: 'بسم الله', confidence: 0.95);
  }

  @override
  void cancelAll() {
    cancelled = true;
  }
}

class FakeAudioRecorderService extends AudioRecorderService {
  bool recording = false;
  Uint8List? nextRotateBytes;

  @override
  bool get isRecording => recording;

  @override
  Future<bool> startRecording({bool enableVad = true}) async {
    recording = true;
    return true;
  }

  @override
  Future<Uint8List?> rotateRecording() async {
    return nextRotateBytes ?? Uint8List.fromList([1, 2, 3, 4]);
  }

  @override
  Future<Uint8List?> stopRecording() async {
    recording = false;
    return Uint8List.fromList([1, 2, 3, 4]);
  }

  @override
  Future<void> cancelRecording() async {
    recording = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpeechRecitationService Tests', () {
    late SpeechRecitationService service;

    setUp(() {
      service = SpeechRecitationService(
        whisperEngine: WhisperApiEngine(apiKey: ''),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is correct', () {
      expect(service.isListening, isFalse);
      expect(service.isProcessing, isFalse);
      expect(service.isContinuous, isFalse);
      expect(service.soundLevel, 0.0);
      expect(service.lastRecognizedText, isEmpty);
      expect(service.lastSpeechResult, isNull);
      expect(service.errorMessage, isNull);
      expect(service.engineMode, 'idle');
      expect(service.isWhisperAvailable, isFalse);
    });

    test('isWhisperAvailable reports true when API key is provided', () {
      final SpeechRecitationService onlineService = SpeechRecitationService(
        whisperEngine: WhisperApiEngine(apiKey: 'modal-key'),
      );
      expect(onlineService.isWhisperAvailable, isTrue);
      onlineService.dispose();
    });

    test('stopListening resets state safely', () async {
      await service.stopListening();
      expect(service.isListening, isFalse);
      expect(service.isProcessing, isFalse);
      expect(service.isContinuous, isFalse);
      expect(service.soundLevel, 0.0);
    });

    test('cancelListening resets state safely', () async {
      await service.cancelListening();
      expect(service.isListening, isFalse);
      expect(service.isProcessing, isFalse);
      expect(service.isContinuous, isFalse);
      expect(service.soundLevel, 0.0);
      expect(service.engineMode, 'idle');
    });

    test(
      'Continuous recitation transitions between multiple ayahs without stopping microphone',
      () async {
        final FakeWhisperEngine fakeWhisper = FakeWhisperEngine();
        final FakeAudioRecorderService fakeRecorder =
            FakeAudioRecorderService();
        final SpeechRecitationService continuousService =
            SpeechRecitationService(
              whisperEngine: fakeWhisper,
              recorder: fakeRecorder,
            );

        final List<String> receivedOutputs = [];
        await continuousService.startContinuousRecitation(
          expectedText: 'الحمد لله',
          onChunkRecognized: (SpeechResult r) {
            receivedOutputs.add(r.fullText);
          },
        );

        expect(continuousService.isListening, isTrue);
        expect(continuousService.isContinuous, isTrue);
        expect(fakeRecorder.onSpeechPauseDetected, isNotNull);

        // Simulate VAD pause on Ayah 1
        fakeRecorder.onSpeechPauseDetected?.call();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(receivedOutputs.length, 1);
        expect(receivedOutputs.last, 'بسم الله');

        // User advances to Ayah 2: setExpectedAyahText should NOT kill VAD
        continuousService.setExpectedAyahText('الرحمن الرحيم');
        expect(continuousService.isListening, isTrue);
        expect(continuousService.isContinuous, isTrue);
        expect(fakeRecorder.onSpeechPauseDetected, isNotNull);

        // Simulate VAD pause on Ayah 2
        fakeWhisper.resultToReturn = const SpeechResult(
          fullText: 'الرحمن الرحيم',
          confidence: 0.98,
        );
        fakeRecorder.onSpeechPauseDetected?.call();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(receivedOutputs.length, 2);
        expect(receivedOutputs.last, 'الرحمن الرحيم');

        continuousService.dispose();
      },
    );

    test(
      'Late response from previous ayah is discarded when ayah has advanced',
      () async {
        final FakeWhisperEngine slowWhisper = FakeWhisperEngine(
          recognizeDelay: const Duration(milliseconds: 100),
        );
        final FakeAudioRecorderService fakeRecorder =
            FakeAudioRecorderService();
        final SpeechRecitationService continuousService =
            SpeechRecitationService(
              whisperEngine: slowWhisper,
              recorder: fakeRecorder,
            );

        final List<String> receivedOutputs = [];
        await continuousService.startContinuousRecitation(
          expectedText: 'Аят 1',
          onChunkRecognized: (SpeechResult r) {
            receivedOutputs.add(r.fullText);
          },
        );

        // Trigger pause on Ayah 1
        fakeRecorder.onSpeechPauseDetected?.call();

        // Immediately switch to Ayah 2 before slow whisper finishes
        continuousService.setExpectedAyahText('Аят 2');

        // Wait for slow whisper to finish
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // The result from Ayah 1 must have been discarded!
        expect(receivedOutputs, isEmpty);
        expect(continuousService.lastRecognizedText, isEmpty);

        continuousService.dispose();
      },
    );

    test(
      'cancelListening drops in-flight requests and clears queues',
      () async {
        final FakeWhisperEngine slowWhisper = FakeWhisperEngine(
          recognizeDelay: const Duration(milliseconds: 100),
        );
        final FakeAudioRecorderService fakeRecorder =
            FakeAudioRecorderService();
        final SpeechRecitationService continuousService =
            SpeechRecitationService(
              whisperEngine: slowWhisper,
              recorder: fakeRecorder,
            );

        final List<String> receivedOutputs = [];
        await continuousService.startContinuousRecitation(
          expectedText: 'Аят 1',
          onChunkRecognized: (SpeechResult r) {
            receivedOutputs.add(r.fullText);
          },
        );

        fakeRecorder.onSpeechPauseDetected?.call();
        await continuousService.cancelListening();

        expect(continuousService.isListening, isFalse);
        expect(continuousService.isProcessing, isFalse);
        expect(slowWhisper.cancelled, isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(receivedOutputs, isEmpty);

        continuousService.dispose();
      },
    );

    test(
      'Single-pass stopListening resets isProcessing = false even if callback triggers stop',
      () async {
        final FakeWhisperEngine fakeWhisper = FakeWhisperEngine(
          resultToReturn: const SpeechResult(
            fullText: 'الحمد لله',
            confidence: 0.99,
          ),
        );
        final FakeAudioRecorderService fakeRecorder =
            FakeAudioRecorderService();
        final SpeechRecitationService singleService = SpeechRecitationService(
          whisperEngine: fakeWhisper,
          recorder: fakeRecorder,
        );

        await singleService.startListening(onRecognized: (SpeechResult r) {});

        // In the callback, simulate user handler calling stopListening again (R02 bug)
        await singleService.stopListening(
          onResult: (SpeechResult r) {
            // Idempotent secondary call
            singleService.stopListening();
          },
        );

        expect(singleService.isListening, isFalse);
        expect(singleService.isProcessing, isFalse);
        expect(singleService.lastRecognizedText, equals('الحمد لله'));

        singleService.dispose();
      },
    );

    test(
      'Continuous recitation preserves and concatenates text-only chunks without words array',
      () async {
        final FakeWhisperEngine fakeWhisper = FakeWhisperEngine(
          resultToReturn: const SpeechResult(fullText: 'الحمد', words: []),
        );
        final FakeAudioRecorderService fakeRecorder =
            FakeAudioRecorderService();
        final SpeechRecitationService continuousService =
            SpeechRecitationService(
              whisperEngine: fakeWhisper,
              recorder: fakeRecorder,
            );

        final List<String> received = [];
        await continuousService.startContinuousRecitation(
          expectedText: 'الحمد لله',
          onChunkRecognized: (SpeechResult r) {
            received.add(r.fullText);
          },
        );

        // Chunk 1 returns text-only: 'الحمد'
        fakeRecorder.onSpeechPauseDetected?.call();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(received.last, equals('الحمد'));

        // Chunk 2 returns text-only: 'لله'
        fakeWhisper.resultToReturn = const SpeechResult(
          fullText: 'لله',
          words: [],
        );
        fakeRecorder.onSpeechPauseDetected?.call();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Both words must be retained and concatenated!
        expect(received.last, equals('الحمد لله'));

        continuousService.dispose();
      },
    );
  });
}
