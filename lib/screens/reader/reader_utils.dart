import 'package:flutter/foundation.dart';

String toArabicDigits(int value) {
  const List<String> digits = <String>[
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];
  return value
      .toString()
      .split('')
      .map((String digit) => digits[int.parse(digit)])
      .join();
}

const String bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

bool get supportsMobilePlatformControls =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

bool get supportsSystemUiControl =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<void> ignorePlatformError(Future<void> Function() operation) async {
  try {
    await operation();
  } on Object {
    // Platform features are optional and must not break the reader.
  }
}

Future<void> safeHapticFeedback(Future<void> Function() feedback) async {
  if (!supportsMobilePlatformControls) return;
  await ignorePlatformError(feedback);
}
