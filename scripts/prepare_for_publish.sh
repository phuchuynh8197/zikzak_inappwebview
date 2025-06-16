#!/bin/bash
set -e

# Color codes for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if version argument is provided
if [ "$#" -ne 1 ]; then
    echo -e "${RED}Error: Version number is required.${NC}"
    echo -e "Usage: $0 <version_number>"
    echo -e "Example: $0 1.2.5"
    exit 1
fi

VERSION=$1
BRANCH_NAME="publish-$VERSION"
ROOT_DIR="$(pwd)"

# Validate semantic version format (simple check)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Version should follow semantic versioning (e.g., 1.2.5)${NC}"
    exit 1
fi

echo -e "${BLUE}=== Preparing to publish version $VERSION ===${NC}"

# Create a new branch for publishing
git checkout -b $BRANCH_NAME
echo -e "${GREEN}Created branch: $BRANCH_NAME${NC}"

# List of all packages to update
PACKAGES=(
    "zikzak_inappwebview_internal_annotations"
    "zikzak_inappwebview_platform_interface"
    "zikzak_inappwebview_android"
    "zikzak_inappwebview_ios"
    "zikzak_inappwebview_macos"
    "zikzak_inappwebview_web"
    "zikzak_inappwebview_windows"
    "zikzak_inappwebview"
)

# Update versions in all package pubspec.yaml files
for pkg in "${PACKAGES[@]}"; do
    echo -e "${BLUE}Updating version in $pkg to $VERSION${NC}"
    # Check if the package directory exists
    if [ ! -d "$ROOT_DIR/$pkg" ]; then
        echo -e "${RED}Warning: Package directory '$pkg' not found. Skipping.${NC}"
        continue
    fi

    # Update version in pubspec.yaml
    if [ -f "$ROOT_DIR/$pkg/pubspec.yaml" ]; then
        # Use sed for reliable version replacement
        sed -i '' "s/^version:.*/version: $VERSION/" "$ROOT_DIR/$pkg/pubspec.yaml"

        # Verify the update
        new_version=$(grep "^version:" "$ROOT_DIR/$pkg/pubspec.yaml" | sed 's/version: //' | tr -d '[:space:]')
        if [ "$new_version" != "$VERSION" ]; then
            echo -e "${RED}Failed to update version for $pkg to $VERSION. Current version: $new_version${NC}"
        else
            echo -e "${GREEN}Successfully updated $pkg to version $VERSION${NC}"
        fi
    else
        echo -e "${RED}Warning: pubspec.yaml not found in $pkg. Skipping.${NC}"
    fi

    # Update version in iOS podspec if it exists
    if [ "$pkg" == "zikzak_inappwebview_ios" ] && [ -f "$ROOT_DIR/$pkg/ios/zikzak_inappwebview_ios.podspec" ]; then
        echo -e "${BLUE}Updating iOS podspec version in $pkg to $VERSION${NC}"
        # Use sed to update the version line in podspec
        sed -i '' "s/s\.version.*=.*/s.version          = '$VERSION'/" "$ROOT_DIR/$pkg/ios/zikzak_inappwebview_ios.podspec"

        # Verify the podspec update
        podspec_version=$(grep "s.version" "$ROOT_DIR/$pkg/ios/zikzak_inappwebview_ios.podspec" | sed "s/.*= *'//" | sed "s/'.*//")
        if [ "$podspec_version" != "$VERSION" ]; then
            echo -e "${RED}Failed to update podspec version for $pkg to $VERSION. Current version: $podspec_version${NC}"
        else
            echo -e "${GREEN}Successfully updated iOS podspec in $pkg to version $VERSION${NC}"
        fi
    fi
done

# Function to convert path dependencies to versioned dependencies
# Function to convert path dependencies to versioned dependencies AND update existing versions
convert_path_to_versioned() {
    local file="$1"
    local version="$2"

    echo -e "${YELLOW}Converting path dependencies and updating versioned dependencies to $version in $file${NC}"

    # List of zikzak packages to convert/update
    local packages=(
        "zikzak_inappwebview_internal_annotations"
        "zikzak_inappwebview_platform_interface"
        "zikzak_inappwebview_android"
        "zikzak_inappwebview_ios"
        "zikzak_inappwebview_macos"
        "zikzak_inappwebview_web"
        "zikzak_inappwebview_windows"
    )

    # Create a temporary file
    local temp_file="${file}.tmp"

    # Use awk to process the file and handle all dependency formats
    awk -v version="$version" '
    BEGIN {
        # Build array of packages to update
        packages_count = split("zikzak_inappwebview_internal_annotations zikzak_inappwebview_platform_interface zikzak_inappwebview_android zikzak_inappwebview_ios zikzak_inappwebview_macos zikzak_inappwebview_web zikzak_inappwebview_windows", packages, " ")
        for (i = 1; i <= packages_count; i++) {
            target_packages[packages[i]] = 1
        }
        in_dependency = ""
    }

    {
        # Check if this line defines a zikzak dependency (single line format)
        matched = 0
        for (pkg in target_packages) {
            # Match: "  package_name: ^2.4.0" or "  package_name:" or "  package_name: any_version"
            if ($0 ~ "^[[:space:]]*" pkg ":[[:space:]]*") {
                print "  " pkg ": ^" version
                matched = 1
                break
            }
        }
        if (matched) next

        # Check if this line starts a multi-line zikzak dependency
        for (pkg in target_packages) {
            if ($0 ~ "^[[:space:]]*" pkg ":[[:space:]]*$") {
                print "  " pkg ": ^" version
                in_dependency = pkg
                matched = 1
                break
            }
        }
        if (matched) next

        # If we are in a zikzak dependency block, skip path/version lines
        if (in_dependency != "") {
            if ($0 ~ /^[[:space:]]*path:/ || $0 ~ /^[[:space:]]*version:/) {
                next
            }
            # Reset if we encounter a non-indented line or another dependency
            if ($0 ~ /^[^[:space:]]/ || $0 ~ /^[[:space:]]*[^[:space:]]+:[[:space:]]*/) {
                in_dependency = ""
            }
        }

        # Print all other lines as-is
        print $0
    }' "$file" > "$temp_file"

    mv "$temp_file" "$file"

    echo -e "${GREEN}Updated zikzak dependencies to version ^$version in $file${NC}"
}


# Update dependencies in each package to use versioned dependencies instead of path
echo -e "${BLUE}Updating dependencies to use versioned references${NC}"

# Update dependencies in ALL packages
for pkg in "${PACKAGES[@]}"; do
    if [ -f "$ROOT_DIR/$pkg/pubspec.yaml" ]; then
        convert_path_to_versioned "$ROOT_DIR/$pkg/pubspec.yaml" "$VERSION"
    else
        echo -e "${RED}Warning: pubspec.yaml not found in $pkg. Skipping.${NC}"
    fi
done

# Ask for the commit message that will be used for both Git commit and CHANGELOG files
echo -e "${YELLOW}Enter a commit/changelog message for version $VERSION (default: 'Prepare for publishing version $VERSION'):${NC}"
read -r COMMIT_MESSAGE
if [ -z "$COMMIT_MESSAGE" ]; then
    COMMIT_MESSAGE="Prepare for publishing version $VERSION"
fi

# Update CHANGELOG.md files with new version
CURRENT_DATE=$(date +"%Y-%m-%d")
for pkg in "${PACKAGES[@]}"; do
    if [ -f "$ROOT_DIR/$pkg/CHANGELOG.md" ]; then
        echo -e "${BLUE}Updating CHANGELOG.md in $pkg${NC}"
        # Add new version entry at the top of the CHANGELOG with the commit message
        sed -i '' "1s/^/## $VERSION - $CURRENT_DATE\n\n* $COMMIT_MESSAGE\n* Updated dependencies to use hosted references\n\n/" "$ROOT_DIR/$pkg/CHANGELOG.md"
    else
        echo -e "${RED}Warning: CHANGELOG.md not found in $pkg. Creating new CHANGELOG.md${NC}"
        echo -e "## $VERSION - $CURRENT_DATE\n\n* $COMMIT_MESSAGE\n* Updated dependencies to use hosted references\n" > "$ROOT_DIR/$pkg/CHANGELOG.md"
    fi
done

# Function to check if a package version is already published on pub.dev
check_package_on_pubdev() {
    local package_name=$1
    local version=$2

    echo -e "${YELLOW}Checking if $package_name version $version is already on pub.dev...${NC}"

    # Use curl to query the pub.dev API
    local response=$(curl -s "https://pub.dev/api/packages/$package_name")
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://pub.dev/api/packages/$package_name")

    # Check if the package exists
    if [ "$http_code" != "200" ]; then
        echo -e "${BLUE}Package $package_name not found on pub.dev. Will be published for the first time.${NC}"
        return 1
    fi

    # Check if the version exists in the package versions
    if echo "$response" | grep -q "\"version\":\"$version\""; then
        echo -e "${RED}Version $version of $package_name is already published on pub.dev!${NC}"
        return 0
    else
        echo -e "${GREEN}Version $version of $package_name is not yet published. Ready to publish.${NC}"
        return 1
    fi
}

# Check all packages on pub.dev and display a summary
echo -e "${BLUE}\n=== Checking packages on pub.dev ===${NC}"
declare -A package_status

for pkg in "${PACKAGES[@]}"; do
    # Extract package name from directory
    pkg_name=$(basename "$pkg")

    if check_package_on_pubdev "$pkg_name" "$VERSION"; then
        package_status["$pkg_name"]="Already published"
    else
        package_status["$pkg_name"]="Not published (ready to publish)"
    fi
done

# Display publication status summary
echo -e "${BLUE}\n=== Publication Status Summary ===${NC}"
for pkg_name in "${!package_status[@]}"; do
    status="${package_status[$pkg_name]}"
    if [[ "$status" == "Already published" ]]; then
        echo -e "${pkg_name}: ${RED}$status${NC}"
    else
        echo -e "${pkg_name}: ${GREEN}$status${NC}"
    fi
done

# Verify that no path dependencies remain
echo -e "${BLUE}\n=== Verifying no path dependencies remain ===${NC}"
found_path_deps=false

for pkg in "${PACKAGES[@]}"; do
    if [ -f "$ROOT_DIR/$pkg/pubspec.yaml" ]; then
        if grep -q "path:" "$ROOT_DIR/$pkg/pubspec.yaml"; then
            echo -e "${RED}Warning: Path dependencies still found in $pkg/pubspec.yaml${NC}"
            echo -e "${YELLOW}Remaining path dependencies:${NC}"
            grep -A1 -B1 "path:" "$ROOT_DIR/$pkg/pubspec.yaml"
            found_path_deps=true
        else
            echo -e "${GREEN}✓ No path dependencies in $pkg${NC}"
        fi
    fi
done

if [ "$found_path_deps" = true ]; then
    echo -e "\n${RED}⚠️  Some packages still have path dependencies. Please review and fix manually.${NC}"
else
    echo -e "\n${GREEN}✅ All path dependencies successfully converted to versioned dependencies!${NC}"
fi

echo -e "${GREEN}All packages updated to version $VERSION with versioned dependencies${NC}"

# Ask user if they want to review changes first
echo -e "${YELLOW}Would you like to review the changes before committing? (y/n)${NC}"
read -r review_choice
if [[ "$review_choice" == "y" || "$review_choice" == "Y" ]]; then
    git diff
fi

# Ask if user wants to modify CHANGELOG files
echo -e "${YELLOW}Would you like to modify CHANGELOG.md files to add more detailed release notes? (y/n)${NC}"
read -r changelog_choice
if [[ "$changelog_choice" == "y" || "$changelog_choice" == "Y" ]]; then
    echo -e "${BLUE}Please edit the CHANGELOG.md files now. Press Enter when done.${NC}"
    read -r
fi

# Automatically commit changes
echo -e "${BLUE}Committing changes...${NC}"
git add .
git commit -m "Prepare for publishing version $VERSION"
echo -e "${GREEN}Changes committed successfully!${NC}"



echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Merge to master using: ./scripts/push_to_master.sh (this will create and push the git tag automatically)"
echo -e "2. Publish packages in order using the publish.sh script"
echo -e ""
echo -e "${BLUE}To revert to development setup (path dependencies), use:${NC}"
echo -e "./scripts/restore_dev_setup.sh"
echo -e ""
echo -e "${RED}To completely revert all publish changes (including git branch):${NC}"
echo -e "./scripts/revert_publish_changes.sh"
