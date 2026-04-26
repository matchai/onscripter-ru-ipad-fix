# ONScripter-RU iPad Fix

Patches the [ONScripter-RU](https://github.com/umineko-project/onscripter-ru) iOS IPA to fix letterboxing on modern iPads.

The original IPA was built with Xcode 9.4 / iOS SDK 11.4. On iPads with screen sizes not covered by the bundled launch images, iOS puts the app in compatibility mode, rendering at a legacy resolution with black bars on all four sides.

## Download

Grab the patched IPA from the [latest release](https://github.com/matchai/onscripter-ru-ipad-fix/releases/latest) and sideload with [Sideloadly](https://sideloadly.io), [AltStore](https://altstore.io), or similar.

After installing, connect your iPad and transfer game files via Finder (Files tab).

## What the patch does

1. **Thins binary to arm64** -- drops unused armv7/armv7s slices
2. **Bumps Mach-O SDK version** from 11.4 to 18.0 -- iOS reads `LC_VERSION_MIN_IPHONEOS` to decide compatibility mode; this is the key fix
3. **Adds a LaunchScreen storyboard** -- tells iOS the app supports all screen sizes
4. **Removes legacy launch images** and updates Info.plist accordingly
5. **Strips code signature** -- your sideloading tool re-signs it

## Patch it yourself

Requires macOS with Xcode command line tools.

```sh
./patch-ipa.sh input.ipa output.ipa
```
