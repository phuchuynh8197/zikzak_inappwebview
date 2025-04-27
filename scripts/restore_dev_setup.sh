#!/bin/bash
# ZikZak InAppWebView 2.0.0
# -------------------------
# restore_dev_mode.sh
#
# This script converts all package dependencies to path dependencies
# for local development, making it easier to develop and test changes
# across multiple packages simultaneously.
#

echo "🔥 ZikZak InAppWebView - Restoring Development Mode 🔥"
echo "Converting all dependencies to path dependencies..."

# Root directory of the project
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Root directory: $ROOT_DIR"

# Function to update pubspec.yaml for development mode
update_for_dev_mode() {
  local package_dir=$1
  local pubspec_file="$package_dir/pubspec.yaml"

  if [ ! -f "$pubspec_file" ]; then
    echo "⚠️ Pubspec file not found at $pubspec_file"
    return
  fi

  echo "Processing $pubspec_file"

  # Backup pubspec file
  cp "$pubspec_file" "${pubspec_file}.bak"

  sed -i.tmp -E 's|zikzak_inappwebview_windows: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_inappwebview_windows:\n    path: ../zikzak_inappwebview_windows|g' "$pubspec_file"

  sed -i.tmp -E 's|zikzak_inappwebview_internal_annotations: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_inappwebview_internal_annotations:\n    path: ../zikzak_inappwebview_internal_annotations|g' "$pubspec_file"

  # Replace zikzak_inappwebview_platform_interface dependency
  sed -i.tmp -E 's|zikzak_inappwebview_platform_interface: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_inappwebview_platform_interface:\n    path: ../zikzak_inappwebview_platform_interface|g' "$pubspec_file"

  # Replace android dependency
  sed -i.tmp -E 's|zikzak_inappwebview_android: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_inappwebview_android:\n    path: ../zikzak_inappwebview_android|g' "$pubspec_file"

  # Replace iOS dependency
  sed -i.tmp -E 's|zikzak_inappwebview_ios: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_inappwebview_ios:\n    path: ../zikzak_inappwebview_ios|g' "$pubspec_file"

  # Replace macOS dependency
  sed -i.tmp -E 's|zikzak_inappwebview_macos: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_inappwebview_macos:\n    path: ../zikzak_inappwebview_macos|g' "$pubspec_file"

  # Replace web dependency
  sed -i.tmp -E 's|zikzak_inappwebview_web: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_inappwebview_web:\n    path: ../zikzak_inappwebview_web|g' "$pubspec_file"

  # Replace Windows dependency
  sed -i.tmp -E 's|zikzak_inappwebview_windows: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_inappwebview_windows:\n    path: ../zikzak_inappwebview_windows|g' "$pubspec_file"

  # Clean up temporary files
  rm -f "${pubspec_file}.tmp"

  echo "✅ Updated $pubspec_file to use path dependencies"
}

# Process each package
for package in zikzak_inappwebview zikzak_inappwebview_android zikzak_inappwebview_ios zikzak_inappwebview_macos zikzak_inappwebview_web zikzak_inappwebview_windows zikzak_inappwebview_platform_interface; do
  if [ -d "$ROOT_DIR/$package" ]; then
    update_for_dev_mode "$ROOT_DIR/$package"
  else
    echo "⚠️ Directory not found: $ROOT_DIR/$package"
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

echo ""
echo "🚀 Development mode setup complete! All packages now use path dependencies."
echo "You can now make changes across packages and test them together."
echo ""
