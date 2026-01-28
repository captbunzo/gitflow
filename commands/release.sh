#!/usr/bin/env bash

# Manage release workflow: create RC tags and ship to production

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Show usage
show_usage() {
    cat <<EOF
Usage: release.sh SUBCOMMAND [VERSION] [OPTIONS]

Manage release workflow from staging to production.

SUBCOMMANDS:
  rc                  Create a release candidate (RC) tag
  ship                Ship release to production

ARGUMENTS:
  VERSION             Semantic version (e.g., 1.2.0)

OPTIONS:
  --rc NUMBER         RC number (for 'rc' subcommand, defaults to 1)
  -h, --help         Show this help message

EXAMPLES:
  # Create first RC
  release.sh rc 1.2.0

  # Create second RC
  release.sh rc 1.2.0 --rc 2

  # Ship release to production
  release.sh ship 1.2.0

  # Interactive mode
  release.sh
EOF
}

# Parse arguments
subcommand=""
version=""
rc_number="1"

# First positional argument is the subcommand
if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
    subcommand="$1"
    shift

    # Second positional argument is the version
    if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
        version="$1"
        shift
    fi
fi

# Check for options
while [[ $# -gt 0 ]]; do
    case $1 in
        --rc)
            rc_number="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

print_header "Release Workflow"

ensure_repo_root

# If no subcommand, show menu
if [ -z "$subcommand" ]; then
    echo -e "${CYAN}What would you like to do?${NC}"
    echo "A) Create release candidate (RC) tag"
    echo "B) Ship release to production"
    echo "Q) Quit"
    echo
    read -p "Select an option: " choice
    echo

    case $choice in
        A|a) subcommand="rc" ;;
        B|b) subcommand="ship" ;;
        Q|q) print_info "Goodbye!"; exit 0 ;;
        *) print_error "Invalid option"; exit 1 ;;
    esac
fi

# Execute subcommand
case $subcommand in
    rc)
        # Get current branch
        current_branch=$(git branch --show-current)

        # Validate we're on a release branch (check pattern first)
        if [[ ! "$current_branch" =~ ^release/v ]]; then
            print_error "Not on a release branch."
            print_info "Current: $current_branch"
            print_info "You must be on a release branch to create an RC tag"
            exit 1
        fi

        # Extract version from branch name if not provided
        if [ -z "$version" ]; then
            # Extract version from branch name (release/v1.2.0 -> 1.2.0)
            version=$(echo "$current_branch" | sed 's|^release/v||')
            print_info "Detected version from branch: $version"
        fi

        validate_version "$version"

        expected_branch="release/v$version"

        if [ "$current_branch" != "$expected_branch" ]; then
            print_error "Branch/version mismatch."
            print_info "Current: $current_branch"
            print_info "Expected: $expected_branch"
            exit 1
        fi

        # Get RC number if not provided
        if [ "$rc_number" = "1" ]; then
            read -p "Enter RC number [1]: " input_rc
            rc_number="${input_rc:-1}"
        fi

        rc_tag="v${version}-rc.${rc_number}"

        print_info "Creating and pushing RC tag: $rc_tag"
        git tag "$rc_tag"
        git push origin "$rc_tag"

        print_success "RC tag created and pushed!"
        print_info "This will trigger deployment to UAT."
        print_info "Tag: $rc_tag"
        ;;

    ship)
        # Get current branch
        current_branch=$(git branch --show-current)

        # Validate we're on a release branch (check pattern first)
        if [[ ! "$current_branch" =~ ^release/v ]]; then
            print_error "Not on a release branch."
            print_info "Current: $current_branch"
            print_info "You must be on a release branch to ship"
            exit 1
        fi

        # Extract version from branch name if not provided
        if [ -z "$version" ]; then
            version=$(echo "$current_branch" | sed 's|^release/v||')
            print_info "Detected version from branch: $version"
        fi

        validate_version "$version"

        expected_branch="release/v$version"

        if [ "$current_branch" != "$expected_branch" ]; then
            print_error "Branch/version mismatch."
            print_info "Current: $current_branch"
            print_info "Expected: $expected_branch"
            exit 1
        fi

        print_info "Merging release branch to main..."
        git checkout main
        git merge --no-ff "$expected_branch"
        git push origin main

        print_info "Merging release branch back to develop..."
        git checkout develop
        git merge --no-ff "$expected_branch"
        git push origin develop

        # Check if tag already exists
        release_tag="v$version"
        if git rev-parse "$release_tag" >/dev/null 2>&1; then
            print_error "Tag $release_tag already exists!"
            exit 1
        fi

        print_info "Creating production tag: $release_tag"
        git checkout main
        git tag "$release_tag"
        git push origin "$release_tag"

        print_success "Release shipped to production!"
        print_info "✓ Merged to main and develop"
        print_info "✓ Tagged as $release_tag"
        print_info "✓ Production deployment will start automatically"
        print_warning "Delete release branch when ready: gitflow branch delete $expected_branch"
        ;;

    *)
        print_error "Invalid subcommand: $subcommand"
        show_usage
        exit 1
        ;;
esac
