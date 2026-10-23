# Anything Notification

Turn any reminder into a notification: one-time or recurring, with Done and
Snooze on the notification itself. Android only, Flutter, no account, all data
stays on the device. The product spec is in [docs/PRD.md](docs/PRD.md).

## Build

```
flutter pub get
flutter build apk --release                         # all CPU types
flutter build apk --release --target-platform android-arm64   # phones only, smaller
```

### If the build fails with `CERTIFICATE_VERIFY_FAILED` for `libsqlite3`

The `sqlite3` package downloads a prebuilt SQLite from GitHub during the build,
using Dart's own HTTPS client. Behind a proxy that re-signs HTTPS, Dart rejects
the certificate while `curl` works. Pre-fill the cache with curl, then build:

```
tool/fetch_sqlite_libs.sh
```

It verifies every file against the hash published in the package. Run it again
after `flutter clean` or when the `sqlite3` version changes.

## Test

```
flutter test
flutter analyze
```

Always smoke-test a **release** APK on a device before shipping: some failures
(code and resource shrinking) only appear there. See the risks table in the PRD.
