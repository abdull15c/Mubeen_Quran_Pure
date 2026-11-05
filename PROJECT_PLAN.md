# Mubeen Quran Pure

Mubeen Quran Pure is an offline mobile application dedicated only to the Quran.
It contains no hadith, adhkar, news, social feed, advertising, or required
account. Opening the app continues from the last reading position.

## Supported Release Scope

- Android phones and tablets are an intended release target.
- iOS and iPadOS devices are an intended release target.
- Windows scaffolding is not a supported or validated product target.
- Web, macOS, and Linux are outside the current project scope.

## Product Principles

- The Quran is the first and dominant element on every reading screen.
- Arabic text and navigation work fully offline.
- No feature may distract from reading, understanding, or memorizing the Quran.
- Content correctness is more important than decoration or animation.
- User settings and bookmarks remain on the device.

## Implemented MVP

- Flow reader with Uthmani Arabic text.
- Quran page reader covering pages 1 through 604. This is a text-based page
  grouping, not a claim of pixel-perfect Madani Mushaf reproduction.
- Navigation by 114 surahs, 30 juz, 60 hizb, pages, and bookmarks.
- Hybrid offline search by Arabic text, Russian translations, local vector
  similarity over 6,236 ayahs, surah names, and `2:255` references.
- Russian translations by Elmir Kuliev and Abu Adel.
- Tafsir as-Saadi and word-by-word details from the bundled database.
- Last-position restoration and per-ayah bookmarks.
- Parchment, OLED, emerald, and light themes.
- Independent Arabic and translation font sizes.
- Hands-free auto-scroll from 1 to 12 lines per minute.

## Next Release Gates

The following features require verified external assets and are not represented
as complete in the MVP:

- Pixel-perfect Madani Mushaf pages require licensed official page assets or
  verified line-layout data for all 604 pages.
- Audio playback, per-surah downloads, and cache management are implemented
  against everyayah.com. Distribution rights and attribution for every listed
  reciter must be confirmed and recorded in `CONTENT_SOURCES.md` before the
  feature is shipped publicly.
- Word-level audio highlighting is implemented with timings from
  api.quran.com; the data is unverified and the feature must be presented as
  approximate until it is validated against the audio.
- The voice recitation trainer depends on a self-hosted Whisper service and a
  build-time token; a token broker with rate limits is required before public
  release (see `server/README.md`).

## Owner Release TODOs

- OWNER TODO: establish and record provenance, exact editions, permissions or
  licenses, and required attribution for every bundled content component.
- OWNER TODO: complete the operator identity, privacy contact, effective date,
  public policy URL, and final store privacy disclosures.
- OWNER TODO: provision and securely retain Android and Apple signing material;
  an unsigned Android build is never a distributable release.
- OWNER TODO: validate the exact store artifacts on representative physical
  Android, iOS, and iPadOS devices before claiming support.

## Quality Gates

- Exactly 114 surahs and 6,236 ayahs.
- Exactly 6,236 records for each included Russian translation.
- Full tafsir coverage for 6,236 ayahs.
- No empty Arabic tokens in word-by-word data.
- SQLite `quick_check`, foreign-key check, and FTS5 integrity check pass.
- Search and reader behavior are tested on real baseline Android, iOS, and
  iPadOS devices before performance claims are published.
