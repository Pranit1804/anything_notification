#!/usr/bin/env bash
# Pre-fills the cache of the `sqlite3` package's build hook, using curl.
#
# Why: when you build, the package downloads a prebuilt SQLite from GitHub with
# Dart's own HTTPS client. Behind a company proxy that re-signs HTTPS, Dart
# rejects the certificate (CERTIFICATE_VERIFY_FAILED) while curl, which uses the
# system trust store, works. The hook reuses any cached file whose SHA-256
# matches the hash published inside the package, so this script downloads the
# files with curl, checks every hash itself, and puts them where the hook looks.
#
# Run it after `flutter clean` or when the `sqlite3` version changes; it only
# downloads what is missing:
#
#   tool/fetch_sqlite_libs.sh
#
# Files fetched: the Android ABIs a release build needs (arm, arm64, x64) and
# the macOS library `flutter test` uses on this machine.
set -euo pipefail

cd "$(dirname "$0")/.."

version=$(awk '/^  sqlite3:$/{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock)
[ -n "$version" ] || { echo "sqlite3 is not in pubspec.lock (run flutter pub get)"; exit 1; }

pkg="$HOME/.pub-cache/hosted/pub.dev/sqlite3-$version"
hashes="$pkg/lib/src/hook/asset_hashes.dart"
[ -f "$hashes" ] || { echo "Not found: $hashes (run flutter pub get)"; exit 1; }

cache=".dart_tool/hooks_runner/shared/sqlite3/build"
base="${SQLITE3_URL_BASE:-https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$version}"

fetch() {
  local name=$1 target=$2
  local hash
  hash=$(grep -F "'$name'" "$hashes" | sed -E "s/.*'([0-9a-f]{64})'.*/\1/")
  [ -n "$hash" ] || { echo "No published hash for $name"; return 1; }

  local dir="$cache/download-${hash:0:8}"
  local file="$dir/$target"
  if [ -f "$file" ] && [ "$(shasum -a 256 "$file" | cut -d' ' -f1)" = "$hash" ]; then
    echo "ok       $name"
    return 0
  fi

  mkdir -p "$dir"
  curl -fsSL "$base/$name" -o "$file.tmp"
  local actual
  actual=$(shasum -a 256 "$file.tmp" | cut -d' ' -f1)
  if [ "$actual" != "$hash" ]; then
    rm -f "$file.tmp"
    echo "HASH MISMATCH for $name (expected $hash, got $actual)"
    return 1
  fi
  mv "$file.tmp" "$file"
  echo "fetched  $name"
}

fetch libsqlite3.arm.android.so   libsqlite3.so
fetch libsqlite3.arm64.android.so libsqlite3.so
fetch libsqlite3.x64.android.so   libsqlite3.so
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) fetch libsqlite3.arm64.macos.dylib libsqlite3.dylib ;;
  Darwin-x86_64) fetch libsqlite3.x64.macos.dylib libsqlite3.dylib ;;
esac
echo "Done. SQLite $version libraries are cached; builds will not need the network for them."
