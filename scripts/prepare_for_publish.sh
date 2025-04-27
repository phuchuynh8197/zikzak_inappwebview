#!/bin/bash
set -e

# Color codes for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 🦾 Function to display a beast mode banner
display_banner() {
    echo -e "${BOLD}${PURPLE}"
    echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo "┃                     🔥 ZIKZAK PUBLISHING DOMINATION 🔥                      ┃"
    echo "┃                     ORDINARY WORKFLOW? DEMOLISHED!                          ┃"
    echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo -e "${NC}"
}

# Display the epic banner
display_banner

# 🧠 Pre-flight check function to validate repository state
pre_flight_check() {
    echo -e "${CYAN}🚀 EXECUTING PRE-FLIGHT CHECKS${NC}"
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${RED}⚠️  ERROR: You have uncommitted changes in your working directory!${NC}"
        echo -e "${YELLOW}Please commit or stash your changes before running this script.${NC}"
        exit 1
    fi
    
    # Check if we're on a feature branch instead of main/master
    CURRENT_BRANCH=$(git branch --show-current)
    if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" && "$CURRENT_BRANCH" != "develop" ]]; then
        echo -e "${YELLOW}⚠️ WARNING: You're on branch '$CURRENT_BRANCH' instead of main/master.${NC}"
        echo -e "${YELLOW}Are you sure you want to prepare for publishing from this branch? (y/n)${NC}"
        read -r branch_choice
        if [[ "$branch_choice" != "y" && "$branch_choice" != "Y" ]]; then
            echo -e "${RED}Publishing preparation aborted.${NC}"
            exit 1
        fi
    fi
    
    # Check if the version already exists as a Git tag
    if git rev-parse "v$VERSION" >/dev/null 2>&1; then
        echo -e "${RED}⚠️  ERROR: Version tag 'v$VERSION' already exists in Git!${NC}"
        echo -e "${YELLOW}Please choose a different version number.${NC}"
        exit 1
    fi
    
    # Check for Flutter environment
    if ! command -v flutter >/dev/null 2>&1; then
        echo -e "${RED}⚠️  ERROR: Flutter not found in PATH!${NC}"
        echo -e "${YELLOW}Make sure Flutter is installed and available in your PATH.${NC}"
        exit 1
    fi
    
    # Success!
    echo -e "${GREEN}✅ PRE-FLIGHT CHECKS PASSED! Ready for publishing preparation!${NC}"
}

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

# Validate semantic version format (more comprehensive check)
if ! [[ $VERSION =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$ ]]; then
    echo -e "${RED}Error: Version '$VERSION' doesn't follow semantic versioning!${NC}"
    echo -e "${YELLOW}Expected format: MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]${NC}"
    echo -e "${YELLOW}Example: 1.2.5 or 1.2.5-beta.1${NC}"
    exit 1
fi

# Run pre-flight checks
pre_flight_check

echo -e "${BLUE}=== Preparing to publish version $VERSION ===${NC}"

# Create a new branch for publishing
git checkout -b $BRANCH_NAME
echo -e "${GREEN}Created branch: $BRANCH_NAME${NC}"

# List of all packages to update
PACKAGES=(
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
        # Use awk for reliable version replacement
        awk -v version="$VERSION" '{
            if ($0 ~ /^version:/) {
                print "version: " version;
            } else {
                print $0;
            }
        }' "$ROOT_DIR/$pkg/pubspec.yaml" > "$ROOT_DIR/$pkg/pubspec.yaml.new"

        mv "$ROOT_DIR/$pkg/pubspec.yaml.new" "$ROOT_DIR/$pkg/pubspec.yaml"

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
done

# Update dependencies in each package to use versioned dependencies instead of path
echo -e "${BLUE}Updating dependencies to use versioned references${NC}"

# Pre-validate to check for any potentially problematic path dependencies
echo -e "${BLUE}=== Pre-publish validation ===${NC}"
declare -A problematic_paths

# Function to check for problematic path dependencies
validate_pubspec() {
    local pubspec_file=$1
    local pkg_name=$2
    local problems_found=0
    
    if grep -q "path: \.\./zikzak_inappwebview" "$pubspec_file"; then
        local path_deps=$(grep -n "path: \.\./zikzak_inappwebview" "$pubspec_file" | sed 's/:.*//g')
        echo -e "${YELLOW}⚠️ Path dependencies found in $pkg_name at lines: $path_deps${NC}"
        problematic_paths["$pkg_name"]="$path_deps"
        problems_found=1
    fi
    
    return $problems_found
}

for pkg in "${PACKAGES[@]}"; do
    if [ -f "$ROOT_DIR/$pkg/pubspec.yaml" ]; then
        validate_pubspec "$ROOT_DIR/$pkg/pubspec.yaml" "$pkg"
    fi
done

if [ "${#problematic_paths[@]}" -gt 0 ]; then
    echo -e "${YELLOW}Path dependencies were found in ${#problematic_paths[@]} package(s). These will be addressed.${NC}"
fi

# Update platform_interface dependency in all platform packages
for pkg in "zikzak_inappwebview_android" "zikzak_inappwebview_ios" "zikzak_inappwebview_macos" "zikzak_inappwebview_web" "zikzak_inappwebview_windows"; do
    if [ -f "$ROOT_DIR/$pkg/pubspec.yaml" ]; then
        echo -e "${YELLOW}Updating platform_interface dependency in $pkg${NC}"
        
        # Create a backup before modification
        cp "$ROOT_DIR/$pkg/pubspec.yaml" "$ROOT_DIR/$pkg/pubspec.yaml.pre_publish_backup"
        
        awk -v version="$VERSION" -v pkg_name="$pkg" '
        BEGIN { 
            in_dev_dependencies = 0;
            changes = 0;
            dev_deps_changes = 0;
        }
        {
            # Track when we enter/exit dev_dependencies section
            if ($0 ~ /^dev_dependencies:/) {
                in_dev_dependencies = 1;
                print $0;
            } 
            # Handle platform_interface dependency in regular dependencies
            else if (!in_dev_dependencies && $0 ~ /zikzak_inappwebview_platform_interface:/) {
                if ($0 ~ /^  zikzak_inappwebview_platform_interface:$/) {
                    print "  zikzak_inappwebview_platform_interface: ^" version;
                    changes++;
                    getline; # skip the path line if it exists
                    if ($0 !~ /path:/) {
                        print $0; # if not a path line, print it
                    } else {
                        changes++; # Count skipping the path
                    }
                } else {
                    print "  zikzak_inappwebview_platform_interface: ^" version;
                    changes++;
                }
            } 
            # Comment out path dependencies in dev_dependencies section
            else if (in_dev_dependencies && $0 ~ /path: ..\/zikzak_inappwebview/) {
                print "    #" $0 " # Commented for publishing";
                dev_deps_changes++;
            }
            # Skip path lines in regular dependencies
            else if (!in_dev_dependencies && $0 ~ /path: ..\/zikzak_inappwebview_platform_interface/) {
                # Skip path lines
                changes++;
            }
            # Reset the flag when exiting dev_dependencies section
            else if (in_dev_dependencies && $0 ~ /^[a-zA-Z]/) {
                in_dev_dependencies = 0;
                print $0;
            }
            else {
                print $0;
            }
        }
        END {
            if (changes > 0) {
                printf "Processed %s: %d regular dependency changes\n", pkg_name, changes > "/dev/stderr";
            }
            if (dev_deps_changes > 0) {
                printf "Processed %s: %d dev dependency changes\n", pkg_name, dev_deps_changes > "/dev/stderr";
            }
        }' "$ROOT_DIR/$pkg/pubspec.yaml" > "$ROOT_DIR/$pkg/pubspec.yaml.new" 2>"$ROOT_DIR/$pkg/publish_changes.log"

        if [ -s "$ROOT_DIR/$pkg/pubspec.yaml.new" ]; then
            mv "$ROOT_DIR/$pkg/pubspec.yaml.new" "$ROOT_DIR/$pkg/pubspec.yaml"
            changes=$(cat "$ROOT_DIR/$pkg/publish_changes.log")
            if [ -n "$changes" ]; then
                echo -e "${GREEN}$changes${NC}"
            fi
        else
            echo -e "${RED}Error: Failed to update $pkg pubspec. Check the AWK script output.${NC}"
        fi
    else
        echo -e "${RED}Warning: pubspec.yaml not found in $pkg. Skipping.${NC}"
    fi
done

# Update all dependencies in the main package
if [ -f "$ROOT_DIR/zikzak_inappwebview/pubspec.yaml" ]; then
    echo -e "${YELLOW}Updating all dependencies in main package${NC}"

    # Handle all packages at once with a single AWK pass to avoid multiple file rewrites
    awk -v version="$VERSION" '
    BEGIN { 
        in_dev_dependencies = 0;
        packages["zikzak_inappwebview_internal_annotations"] = 1;
        packages["zikzak_inappwebview_platform_interface"] = 1;
        packages["zikzak_inappwebview_android"] = 1;
        packages["zikzak_inappwebview_ios"] = 1;
        packages["zikzak_inappwebview_macos"] = 1;
        packages["zikzak_inappwebview_web"] = 1;
        packages["zikzak_inappwebview_windows"] = 1;
    }
    
    # Track when we enter/exit dev_dependencies section
    /^dev_dependencies:/ {
        in_dev_dependencies = 1;
        print;
        next;
    }
    
    # For dev_dependencies zikzak packages
    in_dev_dependencies && /^  zikzak_inappwebview/ {
        pkg_name = $1;
        sub(/:$/, "", pkg_name);
        
        if (packages[pkg_name]) {
            # Keep the package reference but version it properly
            print "  " pkg_name ": ^" version;
            # Skip the path line if it exists
            getline;
            if ($0 !~ /path:/) {
                print; # If not a path line, print it
            } else {
                print "    #" $0 " # Commented for publishing";
            }
            next;
        }
    }

    # For regular dependencies zikzak packages
    !in_dev_dependencies && /^  zikzak_inappwebview/ {
        pkg_name = $1;
        sub(/:$/, "", pkg_name);
        
        if (packages[pkg_name]) {
            # Replace with versioned dependency
            print "  " pkg_name ": ^" version;
            # Skip the path line if it exists
            getline;
            if ($0 !~ /path:/) {
                print; # If not a path line, print it
            }
            next;
        }
    }
    
    # Skip path lines in regular dependencies
    !in_dev_dependencies && /path: ..\\/zikzak_inappwebview/ {
        next;
    }
    
    # Reset the flag when leaving dev_dependencies section
    in_dev_dependencies && /^[a-zA-Z]/ && !/^  / {
        in_dev_dependencies = 0;
        print;
        next;
    }
    
    # Print all other lines unchanged
    { print }
    ' "$ROOT_DIR/zikzak_inappwebview/pubspec.yaml" > "$ROOT_DIR/zikzak_inappwebview/pubspec.yaml.new"

    if [ -s "$ROOT_DIR/zikzak_inappwebview/pubspec.yaml.new" ]; then
        mv "$ROOT_DIR/zikzak_inappwebview/pubspec.yaml.new" "$ROOT_DIR/zikzak_inappwebview/pubspec.yaml"
        echo -e "${GREEN}Successfully updated main package dependencies to version $VERSION${NC}"
    else
        echo -e "${RED}Error: Failed to update main package dependencies. Check the AWK script.${NC}"
    fi
else
    echo -e "${RED}Warning: pubspec.yaml not found for main package. Skipping.${NC}"
fi

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

echo -e "${GREEN}All packages updated to version $VERSION with versioned dependencies${NC}"

# Generate an epic summary report of all changes
echo -e "${BLUE}\n=== 🔥 PUBLISHING DOMINATION REPORT 🔥 ===${NC}"
echo -e "${YELLOW}Version:${NC} $VERSION"
echo -e "${YELLOW}Changed packages:${NC} ${#PACKAGES[@]}"

# Check for remaining path dependencies that might cause publishing problems
echo -e "\n${BLUE}=== Path Dependency Analysis ===${NC}"
remaining_path_deps=0

for pkg in "${PACKAGES[@]}"; do
    if [ -f "$ROOT_DIR/$pkg/pubspec.yaml" ]; then
        # More robust pattern matching for path dependencies - handles different spacing/formatting
        path_deps=$(grep -n "path:.*\.\.\/zikzak_inappwebview" "$ROOT_DIR/$pkg/pubspec.yaml" | grep -v "#" | wc -l)
        # Extra check for any path dependencies we might have missed
        extra_path_deps=$(grep -n "path:" "$ROOT_DIR/$pkg/pubspec.yaml" | grep -v "#" | grep -v "\.\.\/zikzak_inappwebview" | wc -l)
        
        total_paths=$((path_deps + extra_path_deps))
        
        if [ "$path_deps" -gt 0 ]; then
            echo -e "${RED}⚠️  WARNING: $pkg still has $path_deps uncommented zikzak path dependencies!${NC}"
            remaining_path_deps=$((remaining_path_deps + path_deps))
            
            # Show the actual problematic lines for easier debugging
            echo -e "${YELLOW}   Problem lines:${NC}"
            grep -n "path:.*\.\.\/zikzak_inappwebview" "$ROOT_DIR/$pkg/pubspec.yaml" | grep -v "#" | sed 's/^/    /'
        elif [ "$extra_path_deps" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  NOTE: $pkg has $extra_path_deps other path dependencies (non-zikzak)${NC}"
        else
            commented_deps=$(grep -n "#.*path:.*\.\.\/zikzak_inappwebview.*# Commented for publishing" "$ROOT_DIR/$pkg/pubspec.yaml" | wc -l)
            if [ "$commented_deps" -gt 0 ]; then
                echo -e "${GREEN}✅ $pkg: $commented_deps path dependencies properly commented${NC}"
            else
                echo -e "${GREEN}✅ $pkg: No zikzak path dependencies detected${NC}"
            fi
        fi
    fi
done

if [ "$remaining_path_deps" -gt 0 ]; then
    echo -e "\n${RED}⚠️  DANGER: $remaining_path_deps total uncommented path dependencies remain!${NC}"
    echo -e "${RED}    These could prevent successful publishing! Review before proceeding.${NC}"
else
    echo -e "\n${GREEN}✅ ALL CLEAR: No uncommented path dependencies detected in any package!${NC}"
    echo -e "${GREEN}   Publishing should succeed without dependency issues.${NC}"
fi

echo -e "\n${BLUE}=== Publication Order ===${NC}"
echo -e "(Recommended publishing order to respect dependency hierarchy)"
echo -e "1. ${YELLOW}zikzak_inappwebview_internal_annotations${NC}"
echo -e "2. ${YELLOW}zikzak_inappwebview_platform_interface${NC}"
echo -e "3. ${YELLOW}Platform implementations (android, ios, macos, web, windows)${NC}"
echo -e "4. ${YELLOW}Main package (zikzak_inappwebview)${NC}"

# Ask if user wants to run flutter pub get to verify dependencies
echo -e "\n${YELLOW}Would you like to run 'flutter pub get' on all packages to verify dependencies? (y/n)${NC}"
read -r pubget_choice
if [[ "$pubget_choice" == "y" || "$pubget_choice" == "Y" ]]; then
    echo -e "${BLUE}Running 'flutter pub get' on all packages...${NC}"
    for pkg in "${PACKAGES[@]}"; do
        if [ -d "$ROOT_DIR/$pkg" ]; then
            echo -e "${YELLOW}Getting dependencies for $pkg...${NC}"
            (cd "$ROOT_DIR/$pkg" && flutter pub get)
            pub_status=$?
            if [ $pub_status -ne 0 ]; then
                echo -e "${RED}⚠️  ERROR: 'flutter pub get' failed for $pkg! Review dependencies.${NC}"
            else
                echo -e "${GREEN}✅ Dependencies resolved successfully for $pkg${NC}"
            fi
        fi
    done
fi

# Ask user if they want to review changes first
echo -e "\n${YELLOW}Would you like to review the changes before committing? (y/n)${NC}"
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
echo -e "1. Publish packages in order using the publish.sh script"
echo -e "2. After publishing, switch back to main branch: git checkout main"
echo -e ""
echo -e "${BLUE}To revert to development setup (path dependencies), use:${NC}"
echo -e "./scripts/restore_dev_setup.sh"
echo -e ""
echo -e "${RED}To completely revert all publish changes (including git branch):${NC}"
echo -e "./scripts/revert_publish_changes.sh"
