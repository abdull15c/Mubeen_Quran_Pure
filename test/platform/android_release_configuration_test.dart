import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String readProjectFile(String path) {
    final File file = File(path);
    expect(file.existsSync(), isTrue, reason: 'Missing project file: $path');
    return file.readAsStringSync();
  }

  group('Android release configuration', () {
    test('release signing uses key.properties without a debug fallback', () {
      final String gradle = readProjectFile('android/app/build.gradle.kts');

      expect(gradle, contains('rootProject.file("key.properties")'));
      expect(gradle, contains('hasReleaseSigningProperties'));
      expect(gradle, contains('signingConfigs.getByName("release")'));
      expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
    });

    test('backup rules omit support files and shared preferences', () {
      final String manifest = readProjectFile(
        'android/app/src/main/AndroidManifest.xml',
      );
      final String legacyRules = readProjectFile(
        'android/app/src/main/res/xml/backup_rules.xml',
      );
      final String modernRules = readProjectFile(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      );

      expect(
        manifest,
        contains('android:fullBackupContent="@xml/backup_rules"'),
      );
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      expect(legacyRules, contains('<exclude domain="file" path="." />'));
      expect(
        RegExp(
          r'<exclude\s+domain="file"\s+path="\."\s*/>',
        ).allMatches(modernRules).length,
        2,
      );
      expect(legacyRules, contains('domain="sharedpref"'));
      expect(modernRules, contains('domain="sharedpref"'));
    });

    test(
      'AudioService and MediaButtonReceiver are declared for background playback',
      () {
        final String manifest = readProjectFile(
          'android/app/src/main/AndroidManifest.xml',
        );
        final String mainActivity = readProjectFile(
          'android/app/src/main/kotlin/com/mubeen/mubeen_quran_pure/MainActivity.kt',
        );

        expect(
          manifest,
          contains('android:name="com.ryanheise.audioservice.AudioService"'),
        );
        expect(
          manifest,
          contains('android:foregroundServiceType="mediaPlayback"'),
        );
        expect(
          manifest,
          contains(
            'android:name="com.ryanheise.audioservice.MediaButtonReceiver"',
          ),
        );
        expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
        expect(mainActivity, contains('AudioServiceActivity'));
      },
    );
  });
}
