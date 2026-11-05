# Mubeen Quran Pure Technical Specification

## Scope

Flutter application for Android, iOS, and iPadOS. Windows is unsupported despite
the presence of generated scaffolding; web, macOS, and Linux are out of scope.
All bundled content is Quran-related and available offline. User state is stored
separately from immutable content.

## Content Database

Asset: `assets/db/quran.db.gz`

The application expands the gzip asset on first use to the application support
directory and opens SQLite read-only.

Core tables:

- `surahs`: 114 surahs and metadata.
- `ayahs`: 6,236 ayahs with Uthmani and normalized Arabic, juz, hizb, page, and
  sajda metadata.
- `translations`: 6,236 `kuliev` and 6,236 `abu_adel` records.
- `quran_wbw`: word-by-word Arabic, Russian gloss, root, lemma, and part of
  speech where available.
- `tafsir_saadi`: one tafsir record per ayah.
- `quran_search_fts`: FTS4 index for Arabic text, Russian translations, surah
  names, and curated thematic descriptions.
- `content_metadata`: content scope and schema information.

`tool/build_quran_db.py` reproducibly extracts only Quran content from a source
database, normalizes Arabic for search, rebuilds FTS4, validates record counts,
and creates the compressed application asset.

## Application Layers

- `QuranRepository`: installs and queries immutable Quran content.
- `AppController`: stores theme, reading preferences, last position, and
  bookmarks with `SharedPreferences`.
- `QuranHomeScreen`: shell with reading, navigation, search, and settings.
- Flow reader: ayah cards, translations, tafsir, word details, bookmarks, and
  auto-scroll.
- Page reader: RTL navigation across Quran page groups 1 through 604.

## Search

- `2:255` references resolve directly.
- FTS input is tokenized and escaped before a prefix query is generated.
- Arabic is indexed both in Uthmani form and normalized without Quranic marks
  and common alef variants.
- Translation filtering uses only supported keys: `kuliev`, `abu_adel`.
- `tool/build_semantic_search.py` creates a quantized 100-dimensional Russian
  BPEmb subword embedding model and one vector for each ayah from both
  translations plus curated situation descriptions.
- A separate compact topic-prototype index maps high-confidence Russian intent
  matches to curated ayah lists before hybrid ranking.
- Runtime query embeddings and cosine search are implemented in Dart. The
  6,236-vector scan runs in an isolate and does not require a native ML runtime.
- FTS and vector candidates are combined using reciprocal-rank fusion. Missing
  or corrupt semantic assets degrade to FTS without breaking Quran reading.
- Multi-word FTS uses OR candidate generation followed by deterministic
  query-term coverage reranking; this avoids requiring every conversational
  word to appear in one indexed row.
- Semantic assets total about 2.1 MB. They improve Russian situation search;
  Arabic semantic similarity is not claimed and Arabic remains covered by FTS.

## Persistence

Stored locally without an account:

- last surah, ayah, and page;
- current reader mode;
- selected translation and visibility;
- theme and text sizes;
- auto-scroll speed;
- bookmarked ayah IDs.

The content database remains read-only so application updates cannot overwrite
user state.

## Android Backup

The installed `quran_pure_v*.db` file is reproducible from the bundled asset and
should not consume backup or device-transfer storage. Android backup XML does
not support filename globs, so both rule formats exclude the internal `file`
domain. They do not exclude the `sharedpref` domain; settings, bookmarks, and
the last reading position remain eligible for operating-system backup.

## Android Release Signing

`android/key.properties` is optional for local release compilation. When it is
present, all four signing values are required and the configured release
keystore is used. When it is absent, the release variant remains unsigned. It
must never fall back to the debug key, and an unsigned artifact must not be
published.

## Content Governance

Technical validation of counts or database integrity does not establish
provenance or redistribution rights. OWNER TODO: complete and review every
source, edition, permission or license, and attribution field in
`CONTENT_SOURCES.md` before public distribution.

## Online Services

Reading, search, tafsir, and word-by-word details are fully offline. The
following features are online and are layered on top of the offline reader:

- Reciter audio is streamed per ayah from `https://everyayah.com/data/` using
  the reciter subfolders listed in `lib/audio/quran_audio_models.dart`
  (11 reciters). A surah can be downloaded into the application support
  directory by `QuranAudioDownloader`; nothing is bundled. Lock-screen playback
  uses `just_audio_background` and `audio_session`.
- Word-level timings for karaoke highlighting are fetched from
  `https://api.quran.com/api/v4` per surah and reciter and cached in
  `translations_cache.db` by `TranslationManager`.
- Additional translations (`en_sahih`, `tj_mirof`, `uz_sodiq`, `az_musayev`)
  are fetched from `https://api.qurancdn.com/api/qdc` and cached in the same
  database.
- The recitation trainer records 16 kHz mono PCM WAV and sends it to a Whisper
  large-v3-turbo service on Modal (`server/modal_quran_whisper.py`). The
  endpoint URL and bearer token are build-time `--dart-define` values
  (`WHISPER_API_URL`, `WHISPER_API_KEY`); without a token the trainer is
  disabled.

Every item above is subject to the rights review in `CONTENT_SOURCES.md`.
The reciter audio, word-timing, and translation rights are OWNER TODO items and
must be confirmed before public release.

## Deferred Systems

Exact Madani page layout is a separate verified system. The current 604-page
mode groups verified text by database page number and must not be described as
a pixel-perfect reproduction of the printed Mushaf before licensed page assets
or verified line-layout data are available.
