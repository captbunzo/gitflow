#!/usr/bin/env bash

# ==============================================================================
# GitFlow Automation - Pull Request Management
# ==============================================================================
#
# File: commands/pr.sh
# Description: Create and merge pull requests for feature and fix branches.
#              Integrates with GitHub CLI (gh) for PR operations.
#
# Subcommands:
#   - create: Create a PR to merge current branch into develop
#   - merge:  Merge and delete a PR, cleaning up local and remote branches
#
# Workflow:
#   Feature and fix branches create PRs to develop. After approval and merge,
#   branches are automatically cleaned up locally and remotely.
#
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Show usage
show_usage() {
    cat <<EOF
Usage: pr.sh SUBCOMMAND [BRANCH]

Manage pull requests for GitFlow workflow.

SUBCOMMANDS:
  create              Create a PR to develop
  merge               Merge a PR and cleanup

ARGUMENTS:
  BRANCH              Branch name (optional, uses current branch if not provided)

OPTIONS:
  -h, --help         Show this help message

EXAMPLES:
  # Create PR from current branch
  pr.sh create

  # Create PR from specific branch
  pr.sh create feature/my-feature

  # Merge PR from current branch
  pr.sh merge

  # Merge PR from specific branch
  pr.sh merge feature/my-feature

  # Interactive mode
  pr.sh
EOF
}

# Parse arguments
subcommand=""
branch_name=""

# First positional argument is the subcommand
if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
    subcommand="$1"
    shift

    # Second positional argument is the branch name
    if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
        branch_name="$1"
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

print_header "Pull Request"

ensure_repo_root

# Get current branch if not provided
if [ -z "$branch_name" ]; then
    branch_name=$(git branch --show-current)
    print_info "Using current branch: $branch_name"
fi

# If no subcommand, show menu
if [ -z "$subcommand" ]; then
    echo -e "${CYAN}What would you like to do?${NC}"
    echo "A) Create PR to develop"
    echo "B) Merge PR and cleanup"
    echo "Q) Quit"
    echo
    read -rp "Select an option: " choice
    echo

    case $choice in
        A|a) subcommand="create" ;;
        B|b) subcommand="merge" ;;
        Q|q) print_info "Goodbye!"; exit 0 ;;
        *) print_error "Invalid option"; exit 1 ;;
    esac
fi

# Execute subcommand
case $subcommand in
    create)
        # Validate branch type
        if [[ ! "$branch_name" =~ ^(feature|fix)/ ]]; then
            print_error "Not a feature or fix branch. Use 'feature/*' or 'fix/*'."
            exit 1
        fi

        # Check if there are commits to create a PR from
        git fetch origin develop --quiet
        if ! git rev-list --count origin/develop.."$branch_name" | grep -q '^[1-9]'; then
            print_error "No commits found between origin/develop and $branch_name"
            print_info "Make some changes and commit them before creating a PR"
            exit 1
        fi

        # Push branch
        print_info "Pushing branch to origin..."
        git push -u origin "$branch_name"

        # Create PR
        print_info "Creating PR..."
        gh pr create --base develop --head "$branch_name" --fill

        print_success "PR created successfully!"
        print_info "Review: $(gh pr view --web)"
        ;;

    merge)
        # Remember where we started
        original_branch=$(git branch --show-current)
        
        # Validate PR exists
        if ! gh pr view "$branch_name" &>/dev/null; then
            print_error "No PR found for branch: $branch_name"
            exit 1
        fi

        # Get PR number
        pr_number=$(gh pr view "$branch_name" --json number -q '.number')

        # Merge PR with full commit history (not squashed)
        print_info "Merging PR #$pr_number..."
        gh pr merge "$pr_number" --merge

        print_success "PR merged!"

        # Switch to develop
        echo
        print_info "Switching to develop..."
        git checkout develop

        # Prompt to pull latest changes to develop
        echo
        read -rp "Pull latest changes to develop? [Y/n]: " pull_develop
        if [[ ! "$pull_develop" =~ ^[Nn]$ ]]; then
            print_info "Pulling latest changes..."
            git pull origin develop --ff-only
            print_success "Develop updated to latest"
        else
            print_warning "Skipped pulling develop. You may be out of sync with remote."
        fi
        
        # Switch back to original branch if it wasn't the branch being merged
        # and it wasn't already develop
        if [ "$original_branch" != "$branch_name" ] && [ "$original_branch" != "develop" ]; then
            echo
            print_info "Switching back to $original_branch..."
            git checkout "$original_branch"
        fi

        print_success "PR merged and cleaned up!"
        ;;

    *)
        print_error "Invalid subcommand: $subcommand"
        show_usage
        exit 1
        ;;
esac
