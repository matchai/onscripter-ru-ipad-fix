#!/bin/bash
set -euo pipefail

INPUT="${1:-}"
OUTPUT="${2:-onscripter-ru-ios-patched.ipa}"

if [ -z "$INPUT" ]; then
  echo "Usage: $0 <input.ipa> [output.ipa]"
  exit 1
fi

for cmd in lipo vtool xcrun zip unzip /usr/libexec/PlistBuddy; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing: $cmd (install Xcode CLI tools)"; exit 1; }
done

WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

unzip -q "$INPUT" -d "$WORK"
APP="$WORK/Payload/onscripter-ru-ios.app"

if [ ! -d "$APP" ]; then
  echo "Error: not a valid onscripter-ru IPA"
  exit 1
fi

# 1. Thin to arm64 and bump Mach-O SDK version
#    iOS reads LC_VERSION_MIN_IPHONEOS to decide compatibility mode.
#    Original: version 8.0, sdk 11.4 -> triggers letterboxing on modern iPads.
BIN="$APP/onscripter-ru-ios"
lipo "$BIN" -thin arm64 -output "$BIN.arm64"
vtool -set-version-min ios 16.0 18.0 -replace -output "$BIN.patched" "$BIN.arm64"
mv "$BIN.patched" "$BIN"
chmod +x "$BIN"
rm "$BIN.arm64"

# 2. Add LaunchScreen storyboard (tells iOS app supports all screen sizes)
xcrun --sdk iphoneos ibtool \
  --compile "$APP/LaunchScreen.storyboardc" \
  "$(dirname "$0")/LaunchScreen.storyboard" \
  --minimum-deployment-target 16.0

# 3. Patch Info.plist
PLIST="$APP/Info.plist"
/usr/libexec/PlistBuddy \
  -c "Delete :UILaunchImages" \
  -c "Add :UILaunchStoryboardName string LaunchScreen" \
  -c "Add :UILaunchScreen dict" \
  -c "Set :MinimumOSVersion 16.0" \
  -c "Set :DTPlatformVersion 18.0" \
  -c "Set :DTSDKName iphoneos18.0" \
  -c "Set :CFBundleDisplayName Umineko" \
  "$PLIST"

# 4. Remove legacy launch images
rm -f "$APP"/LaunchImage-*.png

# 5. Strip old code signature (Sideloadly/AltStore re-signs)
rm -rf "$APP/_CodeSignature"
rm -f "$APP/embedded.mobileprovision"

# 6. Package
(cd "$WORK" && zip -qr - Payload/) > "$OUTPUT"

echo "Patched IPA: $OUTPUT"
