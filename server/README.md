# Modal services

The Whisper API requires the `MODAL_API_KEY` value from a Modal secret. Create a long,
random token and deploy the service with:

```powershell
modal secret create quran-api-secret MODAL_API_KEY=<random-token>
modal deploy server/modal_quran_whisper.py
```

Build the app with the same token only for private testing:

```powershell
flutter build apk --release --dart-define=WHISPER_API_KEY=<random-token>
```

A token embedded in a mobile binary can be extracted. Before public release,
put the Modal endpoint behind a token broker with device/app attestation,
short-lived tokens, rate limits, and per-device quotas. Never commit the token.
