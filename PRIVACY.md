# Privacy Notice

Status: draft. The operator identity, contact address, effective date, and any
store-specific disclosures marked OWNER TODO must be completed by the owner
before public release.

## Scope

This notice describes the behavior of the application represented by this
repository. It must be reviewed again if networking, analytics, crash reporting,
accounts, audio downloads, or other services are added.

## Data Handling

The application is primarily designed to work offline. It does not contain an
account system, advertising SDK, analytics SDK, or app-operated server sync.
The application code does not intentionally collect or transmit personal
data to the application operator, with one specific exception:

**Voice Recitation Checking (Hifz Trainer)**: If you use the optional voice recitation feature, your spoken audio is temporarily recorded to a local cache file and transmitted to a secure cloud GPU endpoint (powered by Modal) for speech recognition. The temporary audio file on the device and the temporary processing file on the server are deleted immediately upon completion of recognition. Audio data is never permanently retained, logged, or used to build user profiles.

The following data is stored locally so the reader can retain its state:

- theme and reading display preferences;
- selected translation and translation visibility;
- Arabic and translation text sizes;
- auto-scroll speed;
- last surah, ayah, page, and reader mode;
- bookmarked ayah identifiers.

The application also installs a read-only Quran content database from its
bundled assets. Search terms are processed against that local database and are
not intentionally transmitted by the application.

## Device Backups

Operating-system backup is separate from app-operated collection:

- On Android, the generated Quran database and other files in the internal
  application files area are excluded from cloud backup and device transfer.
  Shared preferences remain eligible for Android backup, subject to the user's
  device and Google account settings.
- On iOS and iPadOS, Apple-controlled device or iCloud backups may include local
  application data according to the user's settings and Apple's platform rules.
  The application does not operate or control those backup services.

## Sharing And Third Parties

The application does not sell personal data or integrate advertising, tracker, or commercial analytics SDKs.
When using optional online features, direct network requests are made to:
- EveryAyah (`everyayah.com`) for downloading public domain Quran recitations.
- Quran Foundation & Quran.com (`api.qurancdn.com`, `api.quran.com`) for fetching translations and word timings.
- Modal Labs (`modal.run`) for processing speech recognition requests when using the recitation trainer.

Platform providers (Google and Apple) process operating-system level diagnostics or backups if enabled in the user's device settings.

## Retention And Deletion

Local settings and bookmarks remain until changed, cleared through operating
system application storage controls, or removed by uninstalling the application.
A platform backup may restore eligible preferences after reinstallation. The
application operator cannot retrieve or delete data held only on a user's device
or in a platform-provider backup.

## Children And Regional Requirements

OWNER TODO: obtain an appropriate legal review for intended distribution regions,
age-related requirements, store data-safety forms, and any required consent or
disclosure language. This draft does not make an age-rating or legal-compliance
claim.

## Changes

Material changes to data handling must be reflected here before release. The
release checklist requires a fresh dependency, permission, and network review.

## Operator And Contact

- Operator/legal entity: OWNER TODO
- Privacy contact: OWNER TODO
- Effective date: OWNER TODO
- Public policy URL: OWNER TODO
