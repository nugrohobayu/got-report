#!/usr/bin/env bash
# Renames this Flutter project's Dart package name (pubspec `name:` + all
# `package:<name>/` imports) and/or its native application identifier
# (Android applicationId/namespace + Kotlin package dir, iOS/macOS
# PRODUCT_BUNDLE_IDENTIFIER, Linux APPLICATION_ID) and binary name
# (windows/linux CMakeLists BINARY_NAME / project()).
#
# Usage (run from the project root, the directory containing pubspec.yaml):
#   NEW_PROJECT_NAME=my_new_app NEW_PACKAGE_NAME=com.newtronic.my_new_app \
#     bash .claude/skills/rename-flutter-project/scripts/rename.sh
#
# Either variable may be omitted to leave that part unchanged.
set -euo pipefail

if [ ! -f pubspec.yaml ]; then
  echo "Run this from the Flutter project root (no pubspec.yaml found here)." >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ "${I_UNDERSTAND_NO_GIT:-0}" != "1" ]; then
    echo "This project isn't a git repository, so this rename can't be undone" >&2
    echo "with 'git checkout'. Back up the project directory first, then" >&2
    echo "re-run with I_UNDERSTAND_NO_GIT=1 set." >&2
    exit 1
  fi
fi

NEW_PROJECT_NAME="${NEW_PROJECT_NAME:-}"
NEW_PACKAGE_NAME="${NEW_PACKAGE_NAME:-}"

if [ -z "$NEW_PROJECT_NAME" ] && [ -z "$NEW_PACKAGE_NAME" ]; then
  echo "Set NEW_PROJECT_NAME and/or NEW_PACKAGE_NAME before running this script." >&2
  exit 1
fi

if [ -n "$NEW_PROJECT_NAME" ] && ! [[ "$NEW_PROJECT_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "NEW_PROJECT_NAME must be lowercase_with_underscores, starting with a letter (Dart package name rules)." >&2
  exit 1
fi

if [ -n "$NEW_PACKAGE_NAME" ] && ! [[ "$NEW_PACKAGE_NAME" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$ ]]; then
  echo "NEW_PACKAGE_NAME must be a reverse-domain identifier, e.g. com.example.app." >&2
  exit 1
fi

OLD_PROJECT_NAME=$(sed -n 's/^name:[[:space:]]*\(.*\)$/\1/p' pubspec.yaml | head -1 | tr -d '\r')
OLD_PACKAGE_NAME=$(sed -n 's/.*applicationId[= ]*"\([^"]*\)".*/\1/p' android/app/build.gradle | head -1)

echo "Dart project name: ${OLD_PROJECT_NAME:-<none found>} -> ${NEW_PROJECT_NAME:-<unchanged>}"
echo "Package identifier: ${OLD_PACKAGE_NAME:-<none found>} -> ${NEW_PACKAGE_NAME:-<unchanged>}"

escape_dots() { printf '%s' "$1" | sed 's/\./\\./g'; }

# ---- Dart project name -------------------------------------------------
if [ -n "$NEW_PROJECT_NAME" ]; then
  if [ -z "$OLD_PROJECT_NAME" ]; then
    echo "Could not find 'name:' in pubspec.yaml, skipping Dart rename." >&2
  else
    sed -i "s/^name:[[:space:]]*.*/name: $NEW_PROJECT_NAME/" pubspec.yaml

    OLD_ESC=$(escape_dots "$OLD_PROJECT_NAME")
    grep -rl "package:${OLD_PROJECT_NAME}/" lib test 2>/dev/null | while read -r f; do
      sed -i "s/package:${OLD_ESC}\//package:${NEW_PROJECT_NAME}\//g" "$f"
    done

    if [ -f windows/CMakeLists.txt ]; then
      sed -i \
        -e "s/project(${OLD_ESC} /project(${NEW_PROJECT_NAME} /" \
        -e "s/set(BINARY_NAME \"${OLD_ESC}\")/set(BINARY_NAME \"${NEW_PROJECT_NAME}\")/" \
        windows/CMakeLists.txt
    fi
    if [ -f linux/CMakeLists.txt ]; then
      sed -i "s/set(BINARY_NAME \"${OLD_ESC}\")/set(BINARY_NAME \"${NEW_PROJECT_NAME}\")/" \
        linux/CMakeLists.txt
    fi
    if [ -f macos/Runner/Configs/AppInfo.xcconfig ]; then
      sed -i "s/PRODUCT_NAME = ${OLD_ESC}/PRODUCT_NAME = ${NEW_PROJECT_NAME}/" \
        macos/Runner/Configs/AppInfo.xcconfig
    fi
  fi
fi

# ---- Application/package identifier -----------------------------------
if [ -n "$NEW_PACKAGE_NAME" ]; then
  if [ -z "$OLD_PACKAGE_NAME" ]; then
    echo "Could not find applicationId in android/app/build.gradle, skipping." >&2
  else
    OLD_PKG_ESC=$(escape_dots "$OLD_PACKAGE_NAME")

    sed -i \
      -e "s/namespace[= ]*\"${OLD_PKG_ESC}\"/namespace = \"${NEW_PACKAGE_NAME}\"/" \
      -e "s/applicationId[= ]*\"${OLD_PKG_ESC}\"/applicationId = \"${NEW_PACKAGE_NAME}\"/" \
      android/app/build.gradle

    OLD_PKG_PATH=$(echo "$OLD_PACKAGE_NAME" | tr '.' '/')
    NEW_PKG_PATH=$(echo "$NEW_PACKAGE_NAME" | tr '.' '/')
    OLD_KOTLIN_DIR="android/app/src/main/kotlin/$OLD_PKG_PATH"
    NEW_KOTLIN_DIR="android/app/src/main/kotlin/$NEW_PKG_PATH"

    if [ -d "$OLD_KOTLIN_DIR" ]; then
      mkdir -p "$NEW_KOTLIN_DIR"
      mv "$OLD_KOTLIN_DIR"/* "$NEW_KOTLIN_DIR"/
      find "$NEW_KOTLIN_DIR" -name "*.kt" -exec sed -i "s/^package .*/package ${NEW_PACKAGE_NAME}/" {} +
      find android/app/src/main/kotlin -type d -empty -delete
    fi

    for pbxproj in ios/Runner.xcodeproj/project.pbxproj macos/Runner.xcodeproj/project.pbxproj; do
      if [ -f "$pbxproj" ]; then
        sed -i "s/PRODUCT_BUNDLE_IDENTIFIER = ${OLD_PKG_ESC}/PRODUCT_BUNDLE_IDENTIFIER = ${NEW_PACKAGE_NAME}/g" "$pbxproj"
      fi
    done

    if [ -f macos/Runner/Configs/AppInfo.xcconfig ]; then
      sed -i "s/PRODUCT_BUNDLE_IDENTIFIER = ${OLD_PKG_ESC}/PRODUCT_BUNDLE_IDENTIFIER = ${NEW_PACKAGE_NAME}/" \
        macos/Runner/Configs/AppInfo.xcconfig
    fi

    if [ -f linux/CMakeLists.txt ]; then
      sed -i "s/set(APPLICATION_ID \"${OLD_PKG_ESC}\")/set(APPLICATION_ID \"${NEW_PACKAGE_NAME}\")/" \
        linux/CMakeLists.txt
    fi
  fi
fi

echo "Done. Run 'flutter clean && flutter pub get' next, and re-open the iOS/macOS project in Xcode if you had it open."
