# Mubeen Quran Pure

A focused, offline Flutter Quran reader for supported Android, iOS, and iPadOS
devices.

## Included

- Uthmani Quran text, 114 surahs and 6,236 ayahs
- Flow and 604-page-group reading modes
- Kuliev and Abu Adel Russian translations
- Tafsir as-Saadi and word-by-word details
- Hybrid offline search: exact Arabic/Russian FTS plus local vector similarity
- Juz, hizb, page, surah, and bookmark navigation
- Three Quran typefaces (KFGQPC HAFS Uthmanic Script, KFGQPC Hafs Smart,
  Amiri Quran) selectable in settings; translations set in PT Serif
- Four eye-care themes and hands-free auto-scroll
- Russian Material UI localization and Arabic-aware highlighted search results
- Lifecycle-aware screen wake lock while the reader is visible
- Local-only settings with no account, advertising, or unrelated content
- Online extras: 11 reciters with per-surah download, karaoke word
  highlighting, downloadable translations, and a Whisper-based recitation
  trainer (see Current Limits)

## Supported Platforms

- Android 7.0 (API 24) or newer, based on the current Flutter Android build
  settings.
- iOS and iPadOS 15.0 or newer.
- Windows has generated project scaffolding only. It is unsupported, unvalidated,
  and must not be presented or distributed as a release target. Web, macOS, and
  Linux targets are not included.

Release validation is still required on representative physical phones and
tablets. Platform support does not imply that every device size, accessibility
setting, or vendor-specific Android build has been tested.

## Current Limits

- Quran text, built-in translations, tafsir, and search are bundled for
  offline use; there is no account or online sync.
- Reciter audio (streamed or downloaded from everyayah.com), word-level audio
  highlighting (timings from api.quran.com), extra translations (Quran
  Foundation API), and the voice recitation trainer (Whisper on Modal) require
  a network connection. No audio is bundled, and the distribution rights for
  these online sources are still OWNER TODO items in
  [CONTENT_SOURCES.md](CONTENT_SOURCES.md).
- The bundled translations, tafsir, and word-by-word details are Russian;
  English, Tajik, Uzbek, and Azerbaijani translations are downloaded on demand.
- The 604-page reader groups text by database page number. It is not a
  pixel-perfect reproduction of a printed Madani Mushaf.
- Android release builds are signed only when `android/key.properties` is
  supplied. Without it, the release variant is intentionally unsigned and must
  not be distributed.
- Content provenance and redistribution rights still have unresolved release
  TODOs documented in [CONTENT_SOURCES.md](CONTENT_SOURCES.md).

## Release Status

The repository is not ready for public distribution merely because a release
artifact can be built. The owner must resolve the provenance, permission,
attribution, privacy-contact, store-policy, signing, and device-validation TODOs
in the release documents before publication. No license or redistribution right
for bundled content should be inferred from its presence in the repository.

## Run

Install Flutter 3.47 or newer, then run:

```powershell
flutter pub get
flutter run
```

## Content Build

The checked-in asset is already ready for the application. To rebuild it from a
source database:

```powershell
python tool\build_quran_db.py source.db.gz assets\db\quran.db.gz
```

The build script keeps Quran-only tables, rebuilds search, and validates the
expected Quran record counts and SQLite integrity.

To rebuild the compact semantic assets after changing Quran content or the
semantic situations catalog:

```powershell
python -m pip install -r tool\requirements-semantic.txt
python tool\build_semantic_search.py
python tool\evaluate_semantic_search.py
```

The shipped vector layer uses a quantized Russian BPEmb subword embedding model
and one 100-dimensional vector for each of the 6,236 ayahs. It adds about 2.1
MB of assets and does not require a network connection or native ML runtime.
Search combines reciprocal-rank-fused lexical and vector candidates; exact
references such as `2:255` remain authoritative.

Search quality is tracked with `tool/semantic_benchmark.py`, currently 105
held-out positive Russian queries across 21 categories and 20 unrelated
negative queries. This benchmark is deliberately not imported by the asset
builder.

## Important Accuracy Note

The current Mushaf mode groups verified Quran text by the traditional page
number stored in the database. It does not claim pixel-perfect reproduction of
the printed Madani Mushaf. Exact reproduction requires licensed official page
assets or separately verified line-layout data.

## Release Documentation

- [Privacy notice](PRIVACY.md)
- [Content sources and rights status](CONTENT_SOURCES.md)
- [Release checklist](RELEASE_CHECKLIST.md)
