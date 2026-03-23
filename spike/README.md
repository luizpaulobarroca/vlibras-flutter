# VLibras Spike

Disposable proof-of-concept for Phase 1 SDK investigation. NOT production code.

## Run manually

```bash
cd spike
flutter pub get
flutter run -d chrome
```

## Run integration tests

Start ChromeDriver first (must match installed Chrome version):

```bash
chromedriver --port=4444
```

Then in a separate terminal:

```bash
cd spike
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/vlibras_load_test.dart \
  -d chrome
```

## Status

This directory will be deleted after Phase 1 completes. Findings are preserved in `.planning/research/phase-01-findings.md`.
