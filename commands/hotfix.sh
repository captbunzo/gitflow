#!/usr/bin/env bash

# ==============================================================================
# GitFlow Automation - Hotfix Management
# ==============================================================================
#
# File: commands/hotfix.sh
# Description: Manage critical production hotfixes. Creates hotfix branches
#              from main and ships them directly to production after testing.
#
# Subcommands:
#   - ship: Merge hotfix to main/develop and deploy to production
#
# Workflow:
#   Hotfixes branch from main (not develop) and follow the same Build Once
#   strategy as releases. Version is set at branch creation, then shipped
#   without modification once testing is complete.
#
# ==============================================================================

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
        original_branch="$current_branch"  # Remember where we started

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
        git fetch origin main develop "$expected_branch" --quiet

        # Ensure hotfix branch is up to date before shipping
        print_info "Checking if hotfix branch is up to date..."
        local_hash=$(git rev-parse HEAD)
        remote_hash=$(git rev-parse "origin/$expected_branch" 2>/dev/null || echo "")

        if [ -z "$remote_hash" ]; then
            print_error "Remote branch origin/$expected_branch does not exist"
            exit 1
        fi

        if [ "$local_hash" != "$remote_hash" ]; then
            # Check if local is behind remote
            if git merge-base --is-ancestor "$local_hash" "$remote_hash"; then
                print_error "Local branch is behind remote"
                print_info "Your local $expected_branch is out of date."
                echo
                read -rp "Pull latest changes? [y/N]: " pull_confirm
                if [[ "$pull_confirm" =~ ^[Yy]$ ]]; then
                    print_info "Pulling latest changes..."
                    git pull origin "$expected_branch" --ff-only
                    print_success "Branch updated to latest"
                else
                    print_error "Cannot ship with stale branch"
                    print_info "Pull manually: git pull origin $expected_branch"
                    exit 1
                fi
            # Check if remote is behind local (unpushed commits)
            elif git merge-base --is-ancestor "$remote_hash" "$local_hash"; then
                print_error "You have unpushed commits on $expected_branch"
                print_info "Push them first: git push origin $expected_branch"
                exit 1
            else
                print_error "Local and remote branches have diverged"
                exit 1
            fi
        else
            print_success "Hotfix branch is up to date"
        fi

        # CRITICAL: Capture the SHA of the hotfix branch BEFORE merging.
        # The --no-ff merge will create a new merge commit, but we want to tag
        # the actual code that was tested, not the merge commit.
        hotfix_sha=$(git rev-parse "$expected_branch")
        print_info "Hotfix SHA to be tagged: $hotfix_sha"

        print_info "Merging hotfix branch to main..."
        git checkout main
        
        # Check if main is up to date
        main_local=$(git rev-parse HEAD)
        main_remote=$(git rev-parse "origin/main")
        if [ "$main_local" != "$main_remote" ]; then
            if git merge-base --is-ancestor "$main_local" "$main_remote"; then
                print_warning "Local main is behind remote"
                echo
                read -rp "Pull latest changes to main? [y/N]: " pull_main
                if [[ "$pull_main" =~ ^[Yy]$ ]]; then
                    git pull origin main --ff-only
                    print_success "Main updated"
                else
                    print_error "Cannot ship with stale main branch"
                    exit 1
                fi
            elif git merge-base --is-ancestor "$main_remote" "$main_local"; then
                print_error "Main has unpushed commits"
                print_info "Push them first: git push origin main"
                exit 1
            else
                print_error "Main has diverged from remote"
                exit 1
            fi
        fi
        
        git merge --no-ff "$expected_branch" -m "Merge hotfix $version to main"
        git push origin main

        print_info "Merging hotfix branch back to develop..."
        git checkout develop
        
        # Check if develop is up to date
        develop_local=$(git rev-parse HEAD)
        develop_remote=$(git rev-parse "origin/develop")
        if [ "$develop_local" != "$develop_remote" ]; then
            if git merge-base --is-ancestor "$develop_local" "$develop_remote"; then
                print_warning "Local develop is behind remote"
                echo
                read -rp "Pull latest changes to develop? [y/N]: " pull_develop
                if [[ "$pull_develop" =~ ^[Yy]$ ]]; then
                    git pull origin develop --ff-only
                    print_success "Develop updated"
                else
                    print_error "Cannot ship with stale develop branch"
                    exit 1
                fi
            elif git merge-base --is-ancestor "$develop_remote" "$develop_local"; then
                print_error "Develop has unpushed commits"
                print_info "Push them first: git push origin develop"
                exit 1
            else
                print_error "Develop has diverged from remote"
                exit 1
            fi
        fi
        
        git merge --no-ff "$expected_branch" -m "Merge hotfix $version back to develop"
        git push origin develop

        # Check if tag already exists
        hotfix_tag="v$version"
        if git rev-parse "$hotfix_tag" >/dev/null 2>&1; then
            print_error "Tag $hotfix_tag already exists!"
            exit 1
        fi

        # Tag the specific SHA that was tested, not the merge commit
        print_info "Creating production tag: $hotfix_tag (pointing to $hotfix_sha)"
        git tag "$hotfix_tag" "$hotfix_sha"
        git push origin "$hotfix_tag"

        print_success "Hotfix shipped to production!"
        print_info "✓ Merged to main and develop"
        print_info "✓ Tagged as $hotfix_tag"
        print_info "✓ Production deployment will start automatically"
        print_warning "Delete hotfix branch when ready: gitflow branch delete $expected_branch"
        
        # Switch back to original branch if different from main
        if [ "$original_branch" != "main" ]; then
            print_info "Switching back to $original_branch..."
            git checkout "$original_branch"
        fi
        ;;

    *)
        print_error "Invalid subcommand: $subcommand"
        show_usage
        exit 1
        ;;
esac
