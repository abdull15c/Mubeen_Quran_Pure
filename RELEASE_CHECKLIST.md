# Release Checklist

Use this checklist for every public build. Record evidence, reviewer, and date
outside the repository where credentials or private agreements are involved.

## Ownership

- [ ] OWNER TODO: assign the person or legal entity responsible for release
  approval and retain their dated approval with the release record.
- [ ] OWNER TODO: resolve every owner field and release blocker in
  `PRIVACY.md` and `CONTENT_SOURCES.md`; unchecked ownership work is not
  delegated to the build process.

## Content And Policy

- [ ] Resolve every release-blocking OWNER TODO in `CONTENT_SOURCES.md`.
- [ ] Verify the bundled database against the approved source editions and
  retain hashes and validation results.
- [ ] Add every required license notice and attribution without paraphrasing
  rights-holder wording.
- [ ] Complete the operator, contact, effective date, and public URL fields in
  `PRIVACY.md`.
- [ ] Compare `PRIVACY.md` with the final dependency list, platform permissions,
  network behavior, Android Data safety answers, and Apple privacy answers.
- [ ] Obtain legal/policy review for intended stores, regions, and age ratings.

## Quality

- [ ] Run `flutter pub get` from a clean checkout.
- [ ] Run `dart format --output=none --set-exit-if-changed lib test`.
- [ ] Run `flutter analyze` with no unresolved diagnostics.
- [ ] Run `flutter test` with all tests passing.
- [ ] Validate SQLite integrity, content counts, search coverage, and required
  metadata using the approved content-build process.
- [ ] Rebuild semantic assets and verify all three SHA-256 values in
  `semantic_manifest.json` against the exact release bundle.
- [ ] Run `tool/evaluate_semantic_search.py` and review Recall@1/3/5/10, MRR,
  category breakdowns, and false-positive rate on held-out Russian queries.
- [ ] Measure cold/warm search latency and peak memory on baseline physical
  Android and iOS devices; confirm Arabic semantic search is not claimed.
- [ ] Confirm semantic assets add about 2.1 MB and record final APK/AAB/IPA
  sizes rather than quoting source-asset size as installed size.
- [ ] Test first launch, upgrade, low-storage failure, interrupted database
  installation, search, bookmarks, preference restoration, and app-data reset.
- [ ] Test representative physical Android phones/tablets and iPhones/iPads,
  including large text and screen-reader behavior.
- [ ] Confirm the 604-page mode is described as text grouping and not exact
  printed-page reproduction.

## Android Signing

- [ ] Create `android/key.properties` only in the secure build environment. It
  must define `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`.
- [ ] Use an absolute `storeFile` path. On Windows, use forward slashes or escape
  backslashes according to Java properties syntax.
- [ ] Confirm `android/key.properties`, `*.jks`, and `*.keystore` remain ignored
  and are absent from source control and release archives.
- [ ] Back up the release/upload key and passwords in approved secure storage.
- [ ] Run `android\gradlew.bat :app:signingReport` on Windows, or
  `./android/gradlew :app:signingReport` on macOS/Linux, and verify the release
  variant uses the intended release certificate and never a debug certificate.
- [ ] Temporarily verify the no-key build path in a clean environment: with no
  `android/key.properties`, the release variant must report no signing config,
  never the debug config. Do not distribute the resulting unsigned artifact.
- [ ] Build the intended store artifact with `flutter build appbundle --release`.
- [ ] Verify the final artifact's certificate fingerprint independently with
  Android SDK or JDK signing tools before upload.
- [ ] Treat an artifact built without `android/key.properties` as unsigned and
  non-distributable, even if compilation succeeds.

## Android Backup

- [ ] Inspect the merged release manifest and confirm it references
  `@xml/backup_rules` and `@xml/data_extraction_rules`.
- [ ] Confirm both backup rule formats exclude the internal `file` domain. This
  is deliberately broader than `quran_pure_v*.db` because Android backup rule
  paths are literal and do not support filename globs.
- [ ] Confirm neither rule excludes the `sharedpref` domain.
- [ ] Exercise an eligible cloud restore or device-to-device transfer: settings,
  last position, and bookmarks should restore, while the Quran database should
  be recreated from the bundled asset.

## Apple Release

- [ ] Select the intended bundle identifier, team, signing certificate, and
  provisioning profile for the archive.
- [ ] Confirm the deployment target remains iOS/iPadOS 15.0 or update the
  supported-platform documentation.
- [ ] Review entitlements, required-reason API manifests, privacy declarations,
  archive validation, and store metadata against the final build.
- [ ] Test backup/restore behavior and make the privacy notice match observed
  iOS/iPadOS behavior.

## Final Artifact

- [ ] Update and verify version name, build number, release notes, screenshots,
  support links, and store listings without adding unsupported claims.
- [ ] Install the exact release artifact on clean devices and complete a smoke
  test in airplane mode.
- [ ] Confirm no debug banners, development endpoints, test data, secrets,
  signing files, crash logs, or local machine paths are packaged.
- [ ] Archive checksums, signing fingerprints, content evidence, test results,
  and store submission records for the released build.
