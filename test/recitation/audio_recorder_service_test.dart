import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/recitation/audio_recorder_service.dart';
import 'package:record/record.dart';

class FakeAudioRecorder implements AudioRecorder {
  bool recording = false;
  bool disposed = false;
  int startCalls = 0;
  int stopCalls = 0;
  final StreamController<Amplitude> _ampController =
      StreamController<Amplitude>.broadcast();

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    startCalls++;
    recording = true;
  }

  @override
  Future<String?> stop() async {
    stopCalls++;
    recording = false;
    return null;
  }

  @override
  Future<void> cancel() async {
    recording = false;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<bool> isPaused() async => false;

  @override
  Future<bool> isRecording() async => recording;

  @override
  Future<Amplitude> getAmplitude() async => Amplitude(current: -160, max: 0);

  @override
  Future<bool> isEncoderSupported(AudioEncoder encoder) async => true;

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async =>
      const Stream<Uint8List>.empty();

  @override
  List<int> convertBytesToInt16(
    Uint8List bytes, [
    dynamic endian = Endian.little,
  ]) => <int>[];

  @override
  Stream<Amplitude> onAmplitudeChanged(Duration interval) =>
      _ampController.stream;

  @override
  Stream<RecordState> onStateChanged() => const Stream<RecordState>.empty();

  @override
  Future<void> dispose() async {
    disposed = true;
    await _ampController.close();
  }

  @override
  Future<List<InputDevice>> listInputDevices() async => <InputDevice>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioRecorderService Concurrency & Race Tests', () {
    late FakeAudioRecorder fakeRecorder;
    late AudioRecorderService service;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall call) async => Directory.systemTemp.path,
          );
      fakeRecorder = FakeAudioRecorder();
      service = AudioRecorderService(recorder: fakeRecorder);
    });

    tearDown(() {
      if (!service.isDisposed) {
        service.dispose();
      }
    });

    test(
      'Concurrent startRecording calls do not start duplicate recordings',
      () async {
        final List<Future<bool>> futures = [
          service.startRecording(enableVad: false),
          service.startRecording(enableVad: false),
        ];
        final List<bool> results = await Future.wait(futures);

        expect(results[0], isTrue);
        expect(results[1], isTrue);
        expect(fakeRecorder.startCalls, 1);
        expect(service.isRecording, isTrue);
      },
    );

    test('Rapid start and stop recording executes safely in order', () async {
      final Future<bool> startFuture = service.startRecording(enableVad: false);
      final Future<dynamic> stopFuture = service.stopRecording();

      final bool started = await startFuture;
      await stopFuture;

      expect(started, isTrue);
      expect(service.isRecording, isFalse);
      expect(fakeRecorder.startCalls, 1);
      expect(fakeRecorder.stopCalls, 1);
    });

    test('cancelRecording resets state and cleans up', () async {
      await service.startRecording(enableVad: false);
      expect(service.isRecording, isTrue);

      await service.cancelRecording();
      expect(service.isRecording, isFalse);
    });

    test('dispose sets isDisposed and disposes recorder', () {
      expect(service.isDisposed, isFalse);
      service.dispose();
      expect(service.isDisposed, isTrue);
      expect(fakeRecorder.disposed, isTrue);
    });
  });
}
