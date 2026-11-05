import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'data/quran_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    const Map<String, List<String>> fontLicenses = <String, List<String>>{
      'assets/fonts/OFL.txt': <String>['Amiri Quran Font'],
      'assets/fonts/KFGQPC_EULA.txt': <String>[
        'KFGQPC HAFS Uthmanic Script',
        'KFGQPC Hafs Smart',
      ],
      'assets/fonts/OFL-PTSerif.txt': <String>['PT Serif'],
    };
    for (final MapEntry<String, List<String>> entry in fontLicenses.entries) {
      try {
        final String license = await rootBundle.loadString(entry.key);
        yield LicenseEntryWithLineBreaks(entry.value, license);
      } catch (e) {
        debugPrint('Error loading font license ${entry.key}: $e');
      }
    }
  });
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.mubeen.mubeen_quran_pure.audio',
      androidNotificationChannelName: 'Mubeen Quran Audio',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint('JustAudioBackground init error: $e');
  }
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  final AppController controller = AppController();
  final QuranRepository repository = QuranRepository();
  Object? startupError;
  try {
    await Future.wait(<Future<void>>[
      controller.initialize(),
      repository.open(),
    ]);
  } on Object catch (error) {
    startupError = error;
  }

  runApp(
    MubeenQuranApp(
      controller: controller,
      repository: repository,
      startupError: startupError,
    ),
  );
}
