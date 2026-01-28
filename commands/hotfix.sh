#!/usr/bin/env bash

# Manage hotfix workflow: ship to production

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Show usage
show_usage() {
    cat <<EOF
Usage: hotfix.sh SUBCOMMAND [VERSION]

Manage hotfix workflow from staging to production.

SUBCOMMANDS:
  ship                Ship hotfix to production

ARGUMENTS:
  VERSION             Semantic version (e.g., 1.2.1)

OPTIONS:
  -h, --help         Show this help message

EXAMPLES:
  # Ship hotfix to production
  hotfix.sh ship 1.2.1

  # Interactive mode
  hotfix.sh
EOF
}

# Parse arguments
subcommand=""
version=""

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

# Check for help flag
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--h|-help|--help|-\?|--\?)
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

print_header "Hotfix Workflow"

ensure_repo_root

# If no subcommand, show menu
if [ -z "$subcommand" ]; then
    echo -e "${CYAN}What would you like to do?${NC}"
    echo "A) Ship hotfix to production"
    echo "Q) Quit"
    echo
    read -rp "Select an option: " choice
    echo

    case $choice in
        A|a) subcommand="ship" ;;
        Q|q) print_info "Goodbye!"; exit 0 ;;
        *) print_error "Invalid option"; exit 1 ;;
    esac
fi

# Execute subcommand
case $subcommand in
    ship)
        # Get current branch
        current_branch=$(git branch --show-current)

        # Validate we're on a hotfix branch (check pattern first)
        if [[ ! "$current_branch" =~ ^hotfix/v ]]; then
            print_warning "Not on a hotfix branch."
            print_info "Current: $current_branch"
            echo
            
            # Prompt to switch to a hotfix branch
            if prompt_switch_to_branch "hotfix" "hotfix branch"; then
                current_branch=$(git branch --show-current)
            else
                exit 1
            fi
        fi

        # Extract version from branch name if not provided
        if [ -z "$version" ]; then
            version=$(echo "$current_branch" | sed 's|^hotfix/v||')
            print_info "Detected version from branch: $version"
        fi

        if ! validate_version "$version"; then
            print_error "Invalid version format: $version. Use semantic versioning (e.g., 1.2.1)"
            exit 1
        fi

        expected_branch="hotfix/v$version"

        if [ "$current_branch" != "$expected_branch" ]; then
            print_error "Branch/version mismatch."
            print_info "Current: $current_branch"
            print_info "Expected: $expected_branch"
            exit 1
        fi

        # Fetch latest from remotes before merging
        print_info "Fetching latest from origin..."
        git fetch origin main develop --quiet

        print_info "Merging hotfix branch to main..."
        git checkout main
        git merge --no-ff "$expected_branch"
        git push origin main

        print_info "Merging hotfix branch back to develop..."
        git checkout develop
        git merge --no-ff "$expected_branch"
        git push origin develop

        # Check if tag already exists
        hotfix_tag="v$version"
        if git rev-parse "$hotfix_tag" >/dev/null 2>&1; then
            print_error "Tag $hotfix_tag already exists!"
            exit 1
        fi

        print_info "Creating production tag: $hotfix_tag"
        git checkout main
        git tag "$hotfix_tag"
        git push origin "$hotfix_tag"

        print_success "Hotfix shipped to production!"
        print_info "✓ Merged to main and develop"
        print_info "✓ Tagged as $hotfix_tag"
        print_info "✓ Production deployment will start automatically"
        print_warning "Delete hotfix branch when ready: gitflow branch delete $expected_branch"
        ;;

    *)
        print_error "Invalid subcommand: $subcommand"
        show_usage
        exit 1
        ;;
esac
