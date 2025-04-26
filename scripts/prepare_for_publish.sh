#!/bin/bash
# ZikZak InAppWebView 2.0.0 
# -------------------------
# prepare_for_publish.sh
# 
# This script converts all path dependencies back to version dependencies
# for publishing to pub.dev, ensuring proper versioning and compatibility.
#

echo "🔥 ZikZak InAppWebView - Preparing for Publication 🔥"
echo "Converting all path dependencies to version dependencies..."

# Root directory of the project
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Root directory: $ROOT_DIR"

# Version constants - update these before publishing
PLATFORM_INTERFACE_VERSION="2.0.0"
ANDROID_VERSION="2.0.0"
IOS_VERSION="2.0.0"
MACOS_VERSION="2.0.0"
WEB_VERSION="2.0.0"
WINDOWS_VERSION="2.0.0"
MAIN_VERSION="2.0.0"

# Function to update pubspec.yaml for publication
update_for_publication() {
  local package_dir=$1
  local pubspec_file="$package_dir/pubspec.yaml"
  local package_name=$(basename "$package_dir")
  
  if [ ! -f "$pubspec_file" ]; then
    echo "⚠️ Pubspec file not found at $pubspec_file"
    return
  fi
  
  echo "Processing $pubspec_file"
  
  # Backup pubspec file
  cp "$pubspec_file" "${pubspec_file}.dev"
  
  # Replace platform interface path dependency with version
  sed -i.tmp -E 's|zikzak_inappwebview_platform_interface:.*\n.*path:.*|zikzak_inappwebview_platform_interface: ^'$PLATFORM_INTERFACE_VERSION'|g' "$pubspec_file"
  
  # Replace android path dependency with version
  sed -i.tmp -E 's|zikzak_inappwebview_android:.*\n.*path:.*|zikzak_inappwebview_android: ^'$ANDROID_VERSION'|g' "$pubspec_file"
  
  # Replace iOS path dependency with version
  sed -i.tmp -E 's|zikzak_inappwebview_ios:.*\n.*path:.*|zikzak_inappwebview_ios: ^'$IOS_VERSION'|g' "$pubspec_file"
  
  # Replace macOS path dependency with version
  sed -i.tmp -E 's|zikzak_inappwebview_macos:.*\n.*path:.*|zikzak_inappwebview_macos: ^'$MACOS_VERSION'|g' "$pubspec_file"
  
  # Replace web path dependency with version
  sed -i.tmp -E 's|zikzak_inappwebview_web:.*\n.*path:.*|zikzak_inappwebview_web: ^'$WEB_VERSION'|g' "$pubspec_file"
  
  # Replace Windows path dependency with version
  sed -i.tmp -E 's|zikzak_inappwebview_windows:.*\n.*path:.*|zikzak_inappwebview_windows: ^'$WINDOWS_VERSION'|g' "$pubspec_file"
  
  # Update the version in the pubspec
  if [ "$package_name" = "zikzak_inappwebview" ]; then
    sed -i.tmp -E 's|version: [0-9]+\.[0-9]+\.[0-9]+.*|version: '$MAIN_VERSION'|g' "$pubspec_file"
  elif [ "$package_name" = "zikzak_inappwebview_platform_interface" ]; then
    sed -i.tmp -E 's|version: [0-9]+\.[0-9]+\.[0-9]+.*|version: '$PLATFORM_INTERFACE_VERSION'|g' "$pubspec_file"
  elif [ "$package_name" = "zikzak_inappwebview_android" ]; then
    sed -i.tmp -E 's|version: [0-9]+\.[0-9]+\.[0-9]+.*|version: '$ANDROID_VERSION'|g' "$pubspec_file"
  elif [ "$package_name" = "zikzak_inappwebview_ios" ]; then
    sed -i.tmp -E 's|version: [0-9]+\.[0-9]+\.[0-9]+.*|version: '$IOS_VERSION'|g' "$pubspec_file"
  elif [ "$package_name" = "zikzak_inappwebview_macos" ]; then
    sed -i.tmp -E 's|version: [0-9]+\.[0-9]+\.[0-9]+.*|version: '$MACOS_VERSION'|g' "$pubspec_file"
  elif [ "$package_name" = "zikzak_inappwebview_web" ]; then
    sed -i.tmp -E 's|version: [0-9]+\.[0-9]+\.[0-9]+.*|version: '$WEB_VERSION'|g' "$pubspec_file"
  elif [ "$package_name" = "zikzak_inappwebview_windows" ]; then
    sed -i.tmp -E 's|version: [0-9]+\.[0-9]+\.[0-9]+.*|version: '$WINDOWS_VERSION'|g' "$pubspec_file"
  fi
  
  # Clean up temporary files
  rm -f "${pubspec_file}.tmp"
  
  echo "✅ Updated $pubspec_file for publication with version dependencies"
}

# Process each package
echo "Updating package versions and dependencies..."
for package in zikzak_inappwebview_platform_interface zikzak_inappwebview_android zikzak_inappwebview_ios zikzak_inappwebview_macos zikzak_inappwebview_web zikzak_inappwebview_windows zikzak_inappwebview; do
  if [ -d "$ROOT_DIR/$package" ]; then
    update_for_publication "$ROOT_DIR/$package"
  else
    echo "⚠️ Directory not found: $ROOT_DIR/$package"
  fi
done

# Verify changelog files exist and are updated
echo "Verifying CHANGELOG.md files..."
for package in zikzak_inappwebview_platform_interface zikzak_inappwebview_android zikzak_inappwebview_ios zikzak_inappwebview_macos zikzak_inappwebview_web zikzak_inappwebview_windows zikzak_inappwebview; do
  changelog_file="$ROOT_DIR/$package/CHANGELOG.md"
  if [ -f "$changelog_file" ]; then
    if ! grep -q "## 2.0.0" "$changelog_file"; then
      echo "⚠️ WARNING: CHANGELOG.md in $package does not contain an entry for version 2.0.0"
      echo "   Please update the changelog before publishing!"
    else
      echo "✅ CHANGELOG.md in $package is ready for version 2.0.0"
    fi
  else
    echo "⚠️ CHANGELOG.md not found in $package"
  fi
done

# Run flutter pub get on all packages
echo "Running 'flutter pub get' on all packages..."
for package in zikzak_inappwebview zikzak_inappwebview_platform_interface zikzak_inappwebview_android zikzak_inappwebview_ios zikzak_inappwebview_macos zikzak_inappwebview_web zikzak_inappwebview_windows; do
  if [ -d "$ROOT_DIR/$package" ]; then
    echo "Getting dependencies for $package..."
    (cd "$ROOT_DIR/$package" && flutter pub get)
  fi
done

# Run flutter analyze to check for any issues
echo "Running 'flutter analyze' to check for issues..."
for package in zikzak_inappwebview zikzak_inappwebview_platform_interface zikzak_inappwebview_android zikzak_inappwebview_ios zikzak_inappwebview_macos zikzak_inappwebview_web zikzak_inappwebview_windows; do
  if [ -d "$ROOT_DIR/$package" ]; then
    echo "Analyzing $package..."
    (cd "$ROOT_DIR/$package" && flutter analyze)
  fi
done

echo ""
echo "🚀 Publication preparation complete!"
echo "Packages are ready to be published in the following order:"
echo "1. zikzak_inappwebview_platform_interface"
echo "2. zikzak_inappwebview_android, zikzak_inappwebview_ios, zikzak_inappwebview_macos, zikzak_inappwebview_web, zikzak_inappwebview_windows"
echo "3. zikzak_inappwebview (main package)"
echo ""
echo "To publish each package, run:"
echo "  cd [package_directory]"
echo "  flutter pub publish"
echo ""
echo "To restore development mode after publishing, run:"
echo "  ./scripts/restore_dev_mode.sh"
echo ""