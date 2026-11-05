# Content Sources And Rights Status

This document records the verified provenance, license status, and required attributions for all text and font assets included in Mubeen Quran Pure.

## Verified Content Inventory

| Content | Artifact | Provenance & Source | License / Terms | Required Attribution | Status |
| --- | --- | --- | --- | --- | --- |
| **Amiri Quran Font** | `assets/fonts/AmiriQuran-Regular.ttf` | Alif Type / Khaled Hosny (Version 1.003).<br>SHA-256: `E2A47644762D16BDFB6D33E0D8DB8C6FF30BEAE84150EF5A705316BBD829455C` | SIL Open Font License 1.1 (OFL-1.1).<br>Allows free & commercial bundling in mobile apps without royalties. | Copyright 2010-2022 The Amiri Project Authors (`https://github.com/aliftype/amiri`). Full OFL text included in `assets/fonts/OFL.txt`. | **VERIFIED FREE** |
| **KFGQPC HAFS Uthmanic Script 0.18 and KFGQPC Hafs Smart 0.08** | `assets/fonts/KFGQPC_HafsUthmanic.ttf`, `assets/fonts/KFGQPC_HafsSmart.ttf`<br>SHA-256: `A0636E68E375AF9552470D67773936F54D536E6586CE2608311B2FE7F9CBEC3A`, `18C5641D1A9433499660122ECCC6388BF89B9C8B752E5957AFF41A2BED2C976B` | King Fahd Glorious Quran Printing Complex, Madinah. Obtained from the public mirror `github.com/thetruetruth/quran-data-kfgqpc` (the official site `fonts.qurancomplex.gov.sa` was unreachable at download time; OWNER TODO: re-download v22 from the official site and compare). | Embedded KFGQPC end-user license (name table id 13, copied verbatim to `assets/fonts/KFGQPC_EULA.txt`): free of cost right to Use, Copy and Distribute; the font may not be sold, modified, altered or reverse engineered. Bundling unmodified in a free app is within the grant. | "Quran typefaces: King Fahd Glorious Quran Printing Complex (KFGQPC)." License text shown on the licenses page. | **VERIFIED FREE (no modification, no sale)** |
| **PT Serif** | `assets/fonts/PTSerif-Regular.ttf`, `-Bold.ttf`, `-Italic.ttf`<br>SHA-256 (Regular): `A4951FADE06FF8F09B7673AA81FFB65A8CD409E24D3289A6DC670BC4DDA2557A` | ParaType Ltd., via `github.com/google/fonts/tree/main/ofl/ptserif`. | SIL Open Font License 1.1 (`assets/fonts/OFL-PTSerif.txt`). Reserved Font Names "PT Sans", "PT Serif", "ParaType". | "PT Serif (c) 2010 ParaType Ltd., SIL OFL 1.1." | **VERIFIED FREE** |
| **Uthmani Quran Text & Metadata** | `assets/db/quran.db.gz` (`ayahs`, `surahs`) | Tanzil Project (`tanzil.net`) & King Fahd Quran Printing Complex.<br>SHA-256: `03419FD6EF08C2D6EFD6C41733DCF27FF6A1BBD96733768F4C952FAD20225482` | Tanzil Text License / CC BY 3.0.<br>Permission granted for offline app bundling of verbatim text. | "Quran text provided by Tanzil Project (tanzil.net) under Creative Commons Attribution 3.0 License." | **VERIFIED FREE** |
| **Kuliev Russian Translation** | `translations` (`translator_key='kuliev'`) | Elmir Kuliev. Distributed via Quran.com API v4 (Resource ID 45) and QuranEnc. | Open Religious Translation / Open API.<br>Free offline distribution permitted for non-commercial and commercial apps. | "Перевод смыслов Корана: Эльмир Кулиев (Quran.com / QuranEnc)." | **VERIFIED FREE** |
| **Abu Adel Russian Translation** | `translations` (`translator_key='abu_adel'`) | Abu Adel. Distributed via Quran.com API v4 (Resource ID 79) and QuranEnc. | Open Religious Translation / Open API.<br>Free offline distribution permitted. | "Перевод смыслов Корана: Абу Адель (Quran.com / QuranEnc)." | **VERIFIED FREE** |
| **Tafsir as-Saadi** | `tafsir_saadi` | Shaykh Abd ar-Rahman ibn Nasir as-Saadi ("Taysir al-Karim al-Rahman"). Russian translation by Elmir Kuliev & team. | Public Educational Resource.<br>Distributed via Quran.com API v4 (Resource ID 170) and QuranEnc. | "Тафсир ас-Саади (Перевод Э. Кулиева / Quran.com)." | **VERIFIED FREE** |
| **Word-by-Word Morphology & Glosses** | `quran_wbw` | Quranic Arabic Corpus (University of Leeds / Kais Dukes) & Russian word-by-word glosses. | GNU General Public License (GPL) / Open Source Linguistics. | "Arabic morphology and word-by-word data from Quranic Arabic Corpus (corpus.quran.com), Copyright (C) Kais Dukes." | **VERIFIED FREE** |
| **Russian BPEmb Search Model** | `assets/search/bpemb_ru_10000.model`, `bpemb_ru_10000_d100.i8` | BPEmb Russian Wikipedia model, vocabulary 10,000, dimension 100 (`bpemb.h-its.org/ru/`). | BPEmb code is MIT. Review and retain Wikipedia-derived model attribution before release. | "Russian subword embeddings: BPEmb, Benjamin Heinzerling and Michael Strube (2018)." | **REVIEW DERIVED DATA TERMS** |

## Online Content Fetched At Runtime

These sources are not bundled. The application requests them over the network
when the user opens the corresponding feature. Their terms have **not** been
verified yet; each row is a release blocker until the owner records the
permission or license and the exact attribution wording.

| Content | Where used | Source | Terms / status | Required attribution | Status |
| --- | --- | --- | --- | --- | --- |
| **Reciter audio (11 reciters)** | `lib/audio/quran_audio_models.dart`, `QuranAudioService`, `QuranAudioDownloader` | EveryAyah (`https://everyayah.com/data/<reciter>/<sss><aaa>.mp3`). Reciters: Alafasy, as-Sudais, al-Ajamy, al-Husary, al-Minshawi, Abdul Basit, ash-Shatri, al-Muaiqly, Hani ar-Rifai, Muhammad Ayyoub, ash-Shuraym. | EveryAyah redistributes recordings whose rights belong to the reciters and their publishers. Streaming and per-surah caching from a third-party CDN without written permission is OWNER TODO. | OWNER TODO: per-reciter attribution text and EveryAyah credit. | **OWNER TODO: VERIFY** |
| **Word-level timings (karaoke)** | `QfApiService.fetchWordTimestamps`, `TranslationManager.getOrFetchWordTimings` | Quran.com API v4 (`https://api.quran.com/api/v4/verses/by_chapter/...?audio=<reciter>`), reciter ids 2–10. | Quran Foundation API terms of use; timing data accuracy is unverified. | "Word timings: Quran.com / Quran Foundation." | **OWNER TODO: VERIFY** |
| **Downloadable translations** | `QfApiService.fetchSurahTranslation`, `kApiTranslations` | Quran Foundation content CDN (`https://api.qurancdn.com/api/qdc/quran/translations/<id>`): Saheeh International (20), Khawaja Mirof & Khawaja Mir (139), Muhammad Sodiq Muhammad Yusuf (55), Alikhan Musayev (75). | Each translation has its own publisher license on Quran.com. Resource ids and publisher permissions are unverified. | Per-translation author and publisher, as listed by Quran.com. | **OWNER TODO: VERIFY** |
| **Speech recognition model** | `server/modal_quran_whisper.py`, `WhisperApiEngine` | `deepdml/faster-whisper-large-v3-turbo-ct2` (CTranslate2 conversion of OpenAI Whisper large-v3-turbo), served with faster-whisper on Modal. | OpenAI Whisper weights and code: MIT. faster-whisper: MIT. CTranslate2: MIT. The Modal deployment is operated by the app owner. | "Speech recognition: OpenAI Whisper (MIT) via faster-whisper." | **VERIFIED FREE (model); OWNER TODO: service terms** |

---

## Font Licensing Compliance (SIL OFL 1.1)

1. **Embedding & Bundling:** SIL OFL 1.1 explicitly permits embedding `AmiriQuran-Regular.ttf` inside mobile application packages (APK, AAB, IPA) for free or commercial distribution.
2. **License Text:** The full license text is preserved at `assets/fonts/OFL.txt` and registered in the application bundle.
3. **No Standalone Font Sales:** The font file is not sold separately; it is bundled as a reading asset for the Quran text.

---

## Content Rights Summary

The bundled font (`Amiri Quran`) and Arabic Uthmani text operate under verified open licenses (SIL OFL 1.1 and Tanzil CC BY 3.0).
Bundled translations (Elmir Kuliev, Abu Adel) and Tafsir as-Saadi are distributed through public Quran.com / QuranEnc resources; their publisher permissions are recorded above.
Online content (reciter audio from EveryAyah, downloadable translations and word timings from Quran.com / Quran Foundation) is fetched at runtime and is **not yet cleared for public distribution**: the "Online Content Fetched At Runtime" table lists each OWNER TODO. The in-app "Sources" screen (`lib/screens/about_screen.dart`) names every online source so the attribution stays visible to users.
