#!/bin/bash
# Build a runnable .app bundle from the Swift Package.
# Usage: scripts/build_app.sh [--universal] [--dmg] [--sign "Developer ID Application: ..."]
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This native SwiftUI/AppKit app requires macOS and Xcode to build." >&2
  echo "From Windows, use scripts/Build-MacOS.ps1 to request a GitHub macOS runner build." >&2
  exit 1
fi

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
UNIVERSAL=0
DMG=0
SIGN_IDENTITY=""
CONFIGURATION="${CONFIGURATION:-release}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --universal) UNIVERSAL=1; shift ;;
    --dmg) DMG=1; shift ;;
    --sign)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "--sign requires a signing identity" >&2
        exit 2
      fi
      SIGN_IDENTITY="$2"; shift 2 ;;
    --debug) CONFIGURATION="debug"; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

for tool in swift xcrun codesign ditto; do
  command -v "$tool" >/dev/null || { echo "Required tool missing: $tool" >&2; exit 1; }
done
xcrun --sdk macosx --show-sdk-path >/dev/null

BUILD_ARGS=(-c "$CONFIGURATION")
if [[ "$UNIVERSAL" == "1" ]]; then
  BUILD_ARGS+=(--arch arm64 --arch x86_64)
fi

echo "==> swift build ${BUILD_ARGS[*]}"
swift build "${BUILD_ARGS[@]}"

BIN_PATH="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
APP="$ROOT/build/iTaxViewerMac.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_PATH/iTaxViewerMac" "$APP/Contents/MacOS/iTaxViewerMac"
chmod +x "$APP/Contents/MacOS/iTaxViewerMac"
if [[ "$UNIVERSAL" == "1" ]]; then
  lipo -verify_arch arm64 x86_64 "$APP/Contents/MacOS/iTaxViewerMac"
fi

# SwiftPM resource bundle(s)
for bundle in "$BIN_PATH"/*.bundle; do
  [[ -e "$bundle" ]] || continue
  cp -R "$bundle" "$APP/Contents/Resources/"
done
# Some toolchains emit .resources directories instead of .bundle
for res in "$BIN_PATH"/*.resources; do
  [[ -e "$res" ]] || continue
  cp -R "$res" "$APP/Contents/Resources/"
done
if [[ ! -d "$APP/Contents/Resources/iTaxViewerMac_iTaxViewerCore.bundle" &&
      ! -d "$APP/Contents/Resources/iTaxViewerMac_iTaxViewerCore.resources" ]]; then
  echo "SwiftPM core resource bundle is missing; refusing to produce an unusable app." >&2
  exit 1
fi

cp "$ROOT/scripts/Info.plist" "$APP/Contents/Info.plist"
if [[ -f "$ROOT/scripts/AppIcon.icns" ]]; then
  cp "$ROOT/scripts/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi
printf 'APPL????' > "$APP/Contents/PkgInfo"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "==> codesign with: $SIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
else
  echo "==> ad-hoc codesign (development only; not notarized)"
  codesign --force --deep --sign - "$APP"
fi
codesign --verify --deep --strict "$APP"

if [[ "$DMG" == "1" ]]; then
  echo "==> creating DMG"
  mkdir -p "$ROOT/build/dmg"
  rm -rf "$ROOT/build/dmg/iTaxViewerMac.app"
  ditto "$APP" "$ROOT/build/dmg/iTaxViewerMac.app"
  ln -sfn /Applications "$ROOT/build/dmg/Applications"
  rm -f "$ROOT/build/iTaxViewerMac-unsigned.dmg"
  hdiutil create -volname "iTax Viewer for macOS" -srcfolder "$ROOT/build/dmg" \
    -ov -format UDZO "$ROOT/build/iTaxViewerMac-unsigned.dmg"
fi

echo "==> done: $APP"
if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "Next (notarization):"
  echo "  xcrun notarytool submit <dmg-or-zip> --apple-id <id> --team-id <team> --password <app-specific-pw> --wait"
  echo "  xcrun stapler staple \"$APP\""
fi
