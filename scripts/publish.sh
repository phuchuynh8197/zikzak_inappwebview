#!/bin/bash
set -e

# Color codes for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

readonly SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
readonly PROJECT_DIR="$(dirname $SCRIPT_PATH)"

# The order of packages for publishing
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

# Function to check if a package version is already published on pub.dev
check_package_on_pubdev() {
    local package_name=$1
    local version=$2

    echo -e "${BLUE}Checking if $package_name version $version is available on pub.dev...${NC}"

    # Use curl to query the pub.dev API
    local response=$(curl -s "https://pub.dev/api/packages/$package_name")
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://pub.dev/api/packages/$package_name")

    # Check if the package exists
    if [ "$http_code" != "200" ]; then
        echo -e "${YELLOW}Package $package_name not found on pub.dev. Will be published for the first time.${NC}"
        return 1
    fi

    # Check if the version exists in the package versions
    if echo "$response" | grep -q "\"version\":\"$version\""; then
        echo -e "${GREEN}Version $version of $package_name is already published on pub.dev!${NC}"
        return 0
    else
        echo -e "${YELLOW}Version $version of $package_name is not yet published. Ready to publish.${NC}"
        return 1
    fi
}

# Function to check if all dependencies of a package are available on pub.dev
check_dependencies() {
    local package_dir="$1"
    local max_retries=5
    local retry_interval=60

    # Extract package version from pubspec.yaml
    local version=$(grep "^version:" "$PROJECT_DIR/$package_dir/pubspec.yaml" | sed 's/version: //' | tr -d '[:space:]')

    # Find all package dependencies that match our packages
    local dependencies=$(grep -E "zikzak_inappwebview_" "$PROJECT_DIR/$package_dir/pubspec.yaml" | grep -v "path:" | sed 's/^[ \t]*//;s/[ \t]*$//' | grep -o "zikzak_inappwebview_[a-z_]*")

    if [ -z "$dependencies" ]; then
        echo -e "${BLUE}No internal dependencies found for $package_dir.${NC}"
        return 0
    fi

    echo -e "${BLUE}Checking dependencies for $package_dir...${NC}"

    for dep in $dependencies; do
        echo -e "${YELLOW}Checking dependency: $dep${NC}"

        # Skip if dependency is the package itself
        if [ "$dep" = "$package_dir" ]; then
            continue
        fi

        # Try up to max_retries times with delay
        local retry_count=0
        while [ $retry_count -lt $max_retries ]; do
            if check_package_on_pubdev "$dep" "$version"; then
                break
            else
                retry_count=$((retry_count + 1))
                if [ $retry_count -lt $max_retries ]; then
                    echo -e "${YELLOW}Dependency $dep not available yet. Waiting ${retry_interval}s before retry ($retry_count/$max_retries)...${NC}"
                    sleep $retry_interval
                else
                    echo -e "${RED}Dependency $dep version $version is required but not available on pub.dev after $max_retries retries.${NC}"
                    echo -e "${RED}Make sure it has been published before proceeding.${NC}"
                    return 1
                fi
            fi
        done
    done

    echo -e "${GREEN}All dependencies for $package_dir are available on pub.dev!${NC}"
    return 0
}

# Function to publish a package
publish_package() {
    local package_dir="$1"

    echo -e "${BLUE}======================================${NC}"
    echo -e "${YELLOW}Publishing package: ${GREEN}$package_dir${NC}"
    echo -e "${BLUE}======================================${NC}"

    # Extract package version
    local version=$(grep "^version:" "$PROJECT_DIR/$package_dir/pubspec.yaml" | sed 's/version: //' | tr -d '[:space:]')

    # Check if package is already published
    if check_package_on_pubdev "$package_dir" "$version"; then
        echo -e "${GREEN}Skipping $package_dir version $version (already published)${NC}"
        return 0
    fi

    # Check if all dependencies are available on pub.dev
    if ! check_dependencies "$package_dir"; then
        echo -e "${RED}Cannot publish $package_dir yet due to missing dependencies.${NC}"
        return 1
    fi

    # Navigate to the package directory
    cd "$PROJECT_DIR/$package_dir"

    # Format the Dart code
    echo -e "${BLUE}Formatting Dart code...${NC}"
    if [ -d "lib" ]; then
        dart format lib/
    fi

    # Analyze the package
    echo -e "${BLUE}Analyzing package...${NC}"
    flutter analyze

    # Publish with confirmation
    echo -e "${BLUE}Running dry-run...${NC}"
    flutter pub publish --dry-run

    echo -e "${YELLOW}Ready to publish ${GREEN}$package_dir${YELLOW}? (y/n)${NC}"
    read -r answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        echo -e "${BLUE}Publishing...${NC}"
        flutter pub publish -f
        echo -e "${GREEN}Package $package_dir published successfully!${NC}"
    else
        echo -e "${RED}Skipping $package_dir...${NC}"
        return 1
    fi

    return 0
}

# Main script execution
echo -e "${BLUE}Starting publication process in the correct order${NC}"
echo -e "${YELLOW}Packages will be published in this order:${NC}"
for package in "${PACKAGES[@]}"; do
    echo -e "- $package"
done
echo

# Confirm publication of all packages
echo -e "${YELLOW}Do you want to proceed with publishing all packages? (y/n)${NC}"
read -r proceed
if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
    echo -e "${RED}Publication process aborted.${NC}"
    exit 0
fi

# Publish each package in the defined order
for package in "${PACKAGES[@]}"; do
    if ! publish_package "$package"; then
        echo -e "${RED}Publication process stopped at $package.${NC}"
        exit 1
    fi
done

echo -e "${GREEN}All packages published successfully!${NC}"
echo -e ""
echo -e "${BLUE}Options for next steps:${NC}"
echo -e "1. ${YELLOW}To revert to development setup (keep branch):${NC}"
echo -e "   ./scripts/restore_dev_setup.sh"
echo -e ""
echo -e "2. ${YELLOW}To completely revert all publish changes (switch back to main):${NC}"
echo -e "   ./scripts/revert_publish_changes.sh"
echo -e ""
echo -e "3. ${YELLOW}To merge all changes into main and push:${NC}"
echo -e "   ./scripts/push_to_main.sh"
