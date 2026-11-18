---
name: rename-flutter-project
description: Rename this Flutter project's Dart package name (pubspec `name:` field and all `package:<name>/` imports) and/or its native application identifier (Android applicationId/namespace + Kotlin package folder, iOS/macOS PRODUCT_BUNDLE_IDENTIFIER, Linux APPLICATION_ID, Windows/Linux CMake binary name). Use whenever the user asks to "change the package name", "change the project name", "rename the app package", "ganti nama package/project", or similar for this Flutter project (myapp).
---

# rename-flutter-project

Renames two distinct things this project has, either together or separately:

1. **Dart project name** — the `name:` field in `pubspec.yaml`, and every `package:<name>/` import
   across `lib/` and `test/`. This is what other Dart code imports this project as; it is unrelated to
   how the app is identified on a device.
2. **Package identifier** (a.k.a. application ID / bundle ID) — the reverse-domain string
   (`com.example.myapp`) that uniquely identifies the app to Android, iOS, macOS, and Linux. Renaming
   this touches:
   - `android/app/build.gradle` (`namespace` and `applicationId`)
   - the Kotlin source folder `android/app/src/main/kotlin/...` (moved to match the new package path,
     with the `package` declaration in `MainActivity.kt` updated)
   - `ios/Runner.xcodeproj/project.pbxproj` and `macos/Runner.xcodeproj/project.pbxproj`
     (`PRODUCT_BUNDLE_IDENTIFIER`, including the `.RunnerTests` variant)
   - `macos/Runner/Configs/AppInfo.xcconfig`
   - `linux/CMakeLists.txt` (`APPLICATION_ID`)

   `windows/CMakeLists.txt` and `linux/CMakeLists.txt`'s `BINARY_NAME`, and `macos/Runner/Configs/AppInfo.xcconfig`'s
   `PRODUCT_NAME` (the desktop build's binary name) follow the **Dart project name**, not the package
   identifier, and are updated alongside it.

This does **not** rename the app's user-visible display name (`android:label`, `CFBundleDisplayName`,
etc.) or the top-level project folder — only the technical identifiers above. Ask first if the user also
wants the display name changed.

## Running it

```bash
NEW_PROJECT_NAME=my_new_app NEW_PACKAGE_NAME=com.newtronic.my_new_app \
  bash .claude/skills/rename-flutter-project/scripts/rename.sh
```

Run from the project root (where `pubspec.yaml` lives). Either variable can be omitted to leave that part
untouched. `NEW_PROJECT_NAME` must be `lowercase_with_underscores` (Dart package name rules);
`NEW_PACKAGE_NAME` must be a reverse-domain identifier like `com.example.app`.

The script auto-detects the current values (from `pubspec.yaml` and
`android/app/build.gradle`'s `applicationId`) and prints the old → new mapping before making any change.

## Collect both values first

Before anything else, make sure you have an answer for **both** parts, even if the user only mentioned
one:

- **Dart project name** missing → ask for it, offering "leave unchanged" as an option.
- **Package identifier** missing → always ask for it; don't silently leave it unchanged. Detect the
  current value (`applicationId` in `android/app/build.gradle`) and suggest
  `com.newtronic.<project_name>` as the default, where `<project_name>` is the new Dart name if one was
  given, otherwise the current one. Offer "leave unchanged" too.

Use a single `AskUserQuestion` call for whatever is missing. Only treat a part as unchanged when the user
explicitly says so.

## Before running — confirm with the user

**This project is not a git repository** (confirmed — no `.git` directory), so this rename **cannot be
undone with `git checkout`** if something goes wrong. Always:

1. Tell the user this explicitly and confirm they want to proceed without version control, or suggest
   `git init && git add -A && git commit -m "before rename"` first.
2. Show the old → new mapping (Dart name, package identifier) and get confirmation before running the
   script, since it touches many files across Android/iOS/macOS/Linux/Windows in one pass.

The script itself refuses to run without `I_UNDERSTAND_NO_GIT=1` set while there's no git repo, as a
backstop — but that env var should only be set after the user has actually agreed, not set reflexively to
get past the check.

## After running

- `flutter clean && flutter pub get` (Android's Gradle and the Dart tool cache the old package path).
- If Xcode was open on `ios/Runner.xcworkspace` or `macos/Runner.xcworkspace`, close and reopen it.
- If the app was already installed on a device/emulator under the old package identifier, uninstall it
  first — Android/iOS treat the renamed app as a different app and won't upgrade in place.
