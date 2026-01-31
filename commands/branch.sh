#!/usr/bin/env bash

# Manage branches: create and delete for all workflow types

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Show usage
show_usage() {
    cat <<EOF
Usage: branch.sh SUBCOMMAND [TYPE] [NAME|VERSION]

Manage branches for GitFlow workflows.

SUBCOMMANDS:
  create              Create a new branch
  delete              Delete an existing branch

ARGUMENTS:
  TYPE                Branch type: feature, fix, release, hotfix
  NAME                Branch name (for feature/fix)
  VERSION             Semantic version (for release/hotfix)
  BRANCH              Full branch name to delete

OPTIONS:
  -h, --help         Show this help message

EXAMPLES:
  # Create branches
  branch.sh create feature add-new-command
  branch.sh create fix memory-leak
  branch.sh create release          # Interactive version selection
  branch.sh create release 1.2.0    # Direct version
  branch.sh create hotfix 1.2.1

  # Delete branches
  branch.sh delete feature/add-new-command
  branch.sh delete                  # Interactive selection

  # Interactive mode
  branch.sh
EOF
}

# ============================================================================
# CREATE BRANCH
# ============================================================================
create_branch() {
    local branch_type="$1"
    local branch_value="$2"

    # Interactive mode if no type provided
    if [ -z "$branch_type" ]; then
        echo "Select branch type:"
        echo -e "  ${CYAN}A${NC}) feature/*"
        echo -e "  ${CYAN}B${NC}) fix/*"
        echo -e "  ${CYAN}C${NC}) release/*"
        echo -e "  ${CYAN}D${NC}) hotfix/*"
        read -rp "Enter choice: " branch_type_choice

        case "$branch_type_choice" in
            A|a|1) branch_type="feature" ;;
            B|b|2) branch_type="fix" ;;
            C|c|3) branch_type="release" ;;
            D|d|4) branch_type="hotfix" ;;
            *) print_error "Invalid choice"; exit 1 ;;
        esac
    fi

    # Validate branch type
    if [[ ! "$branch_type" =~ ^(feature|fix|release|hotfix)$ ]]; then
        print_error "Invalid branch type: $branch_type. Must be 'feature', 'fix', 'release', or 'hotfix'"
        exit 1
    fi

    # Get current branch
    current_branch=$(git branch --show-current)

    # Determine expected base branch
    if [[ "$branch_type" == "hotfix" ]]; then
        expected_base="main"
    else
        expected_base="develop"
    fi

    # Verify we're on the correct base branch
    if [ "$current_branch" != "$expected_base" ]; then
        print_error "Cannot create $branch_type branch from '$current_branch'"
        print_info "You must be on '$expected_base' to create a $branch_type branch"
        print_info "Switch to $expected_base first: git checkout $expected_base"
        exit 1
    fi

    # Prompt for branch name/version
    if [[ "$branch_type" == "feature" || "$branch_type" == "fix" ]]; then
        if [ -z "$branch_value" ]; then
            read -rp "Enter branch name (e.g., 'add-new-command'): " branch_value
        fi

        if [ -z "$branch_value" ]; then
            print_error "Branch name cannot be empty"
            exit 1
        fi
    elif [[ "$branch_type" == "release" || "$branch_type" == "hotfix" ]]; then
        if [ -z "$branch_value" ]; then
            if [ "$branch_type" == "release" ]; then
                # Get the current version from package.json
                current_version=$(get_current_version)
                print_info "Current version: $current_version"
                echo ""
                
                # Calculate version suggestions
                patch_version=$(increment_patch "$current_version")
                minor_version=$(increment_minor "$current_version")
                major_version=$(increment_major "$current_version")
                
                echo -e "${CYAN}Select version for new release:${NC}"
                echo -e "  ${CYAN}1${NC}) $patch_version (patch - bug fixes)"
                echo -e "  ${CYAN}2${NC}) $minor_version (minor - new features)"
                echo -e "  ${CYAN}3${NC}) $major_version (major - breaking changes)"
                echo -e "  ${CYAN}C${NC}) Custom version"
                echo ""
                read -rp "Enter choice: " version_choice
                
                case "$version_choice" in
                    1) branch_value="$patch_version" ;;
                    2) branch_value="$minor_version" ;;
                    3) branch_value="$major_version" ;;
                    C|c) 
                        read -rp "Enter custom version (e.g., 1.2.0): " branch_value
                        ;;
                    *) 
                        print_error "Invalid choice"
                        exit 1
                        ;;
                esac
            else
                current_version=$(get_current_version)
                print_info "Current version: $current_version"
                read -rp "Enter new patch version (e.g., if current is 1.2.0, enter 1.2.1): " branch_value
            fi
        fi

        if [ -z "$branch_value" ]; then
            print_error "Version cannot be empty"
            exit 1
        fi

        if ! validate_version "$branch_value"; then
            print_error "Invalid version format. Use semantic versioning (e.g., 1.2.0)"
            exit 1
        fi
    fi

    # Check for clean working tree
    check_clean_working_tree

    # Check if local branch is up to date with remote
    git fetch origin "$expected_base" --quiet
    local_hash=$(git rev-parse HEAD)
    remote_hash=$(git rev-parse "origin/$expected_base")

    if [ "$local_hash" != "$remote_hash" ]; then
        print_error "Your local '$expected_base' branch is not up to date with remote"
        print_info "Pull latest changes first: git pull origin $expected_base"
        exit 1
    fi

    # Handle feature and fix branches
    if [[ "$branch_type" == "feature" || "$branch_type" == "fix" ]]; then
        full_branch_name="${branch_type}/${branch_value}"

        print_info "Creating branch: $full_branch_name"
        git checkout -b "$full_branch_name"

        print_success "Branch '$full_branch_name' created and checked out"
        print_info "Start working on your changes!"
    fi

    # Handle release and hotfix branches
    if [[ "$branch_type" == "release" || "$branch_type" == "hotfix" ]]; then
        full_branch_name="${branch_type}/v${branch_value}"

        print_info "Creating $branch_type branch: $full_branch_name"
        git checkout -b "$full_branch_name"

        # Only bump version if versioning is enabled
        if [ "$ENABLE_VERSIONING" = true ]; then
            print_info "Bumping version to $branch_value..."
            if ! bump_version "$branch_value"; then
                print_error "Failed to bump version"
                print_info "Cleaning up and returning to $expected_base..."
                git checkout "$expected_base"
                git branch -D "$full_branch_name"
                exit 1
            fi

            print_info "Committing version bump..."
            git add package.json
            git commit -m "chore: bump version to $branch_value"
        fi

        print_info "Pushing $branch_type branch to origin..."
        git push -u origin "$full_branch_name"

        print_success "$branch_type branch created: $full_branch_name"
        print_info "This will automatically deploy to Staging"

        if [ "$branch_type" == "release" ]; then
            print_warning "Test thoroughly before creating a release candidate!"
        else
            print_warning "Fix the issue, test thoroughly, then ship the hotfix!"
        fi
    fi
}

# ============================================================================
# DELETE BRANCH
# ============================================================================
delete_branch() {
    local branch_to_delete="$1"

    # Get list of deletable branches (feature, fix, release, hotfix)
    local branches
    branches=$(git branch --format='%(refname:short)' | grep -E '^(feature|fix|release|hotfix)/' || true)

    if [ -z "$branches" ]; then
        print_info "No feature, fix, release, or hotfix branches found"
        exit 0
    fi

    # Interactive selection if no branch provided
    if [ -z "$branch_to_delete" ]; then
        echo -e "${CYAN}Select branch to delete:${NC}"
        echo ""
        
        local -a branch_array
        readarray -t branch_array <<< "$branches"
        
        local i=1
        for branch in "${branch_array[@]}"; do
            echo -e "  ${CYAN}$i${NC}) $branch"
            ((i++))
        done
        
        echo -e "  ${CYAN}Q${NC}) Quit"
        echo ""
        read -rp "Enter choice: " choice

        if [[ "$choice" =~ ^[Qq]$ ]]; then
            print_info "Cancelled"
            exit 0
        fi

        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#branch_array[@]}" ]; then
            print_error "Invalid choice"
            exit 1
        fi

        branch_to_delete="${branch_array[$((choice-1))]}"
    fi

    # Validate branch name is deletable
    if [[ ! "$branch_to_delete" =~ ^(feature|fix|release|hotfix)/ ]]; then
        print_error "Cannot delete branch: $branch_to_delete"
        print_info "Only feature, fix, release, and hotfix branches can be deleted"
        print_info "Protected branches: main, develop"
        exit 1
    fi

    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/heads/$branch_to_delete"; then
        print_error "Branch does not exist: $branch_to_delete"
        exit 1
    fi

    # Get current branch
    current_branch=$(git branch --show-current)

    # Can't delete current branch
    if [ "$current_branch" == "$branch_to_delete" ]; then
        print_error "Cannot delete current branch"
        print_info "Switch to another branch first: git checkout develop"
        exit 1
    fi

    # Confirm deletion
    print_warning "This will delete branch: $branch_to_delete"
    
    # Check if branch has remote
    local has_remote=false
    if git show-ref --verify --quiet "refs/remotes/origin/$branch_to_delete"; then
        has_remote=true
        print_warning "This will also delete the remote branch on origin"
    fi
    
    read -rp "Continue? [y/N]: " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Cancelled"
        exit 0
    fi

    # Delete local branch
    print_info "Deleting local branch..."
    git branch -D "$branch_to_delete"

    # Delete remote branch if it exists
    if [ "$has_remote" = true ]; then
        print_info "Deleting remote branch..."
        if git push origin --delete "$branch_to_delete" 2>&1 | grep -q "remote ref does not exist"; then
            print_warning "Remote branch was already deleted"
        elif [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_error "Failed to delete remote branch"
            print_info "You may need to delete it manually or run: git fetch --prune"
        fi
        
        # Clean up stale remote-tracking branch
        git fetch --prune origin >/dev/null 2>&1 || true
    fi

    print_success "Branch deleted: $branch_to_delete"
}

# ============================================================================
# MAIN
# ============================================================================

# Parse arguments
subcommand=""
arg1=""
arg2=""

# First positional argument is the subcommand (or could be old-style branch type)
if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
    subcommand="$1"
    shift

    # Second positional argument
    if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
        arg1="$1"
        shift
        
        # Third positional argument
        if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
            arg2="$1"
            shift
        fi
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

print_header "Branch Management"

ensure_repo_root

# Interactive mode if no subcommand
if [ -z "$subcommand" ]; then
    echo -e "${CYAN}What would you like to do?${NC}"
    echo "A) Create a new branch"
    echo "B) Delete a branch"
    echo "Q) Quit"
    echo
    read -rp "Select an option: " choice
    echo

    case $choice in
        A|a) subcommand="create" ;;
        B|b) subcommand="delete" ;;
        Q|q) print_info "Goodbye!"; exit 0 ;;
        *) print_error "Invalid option"; exit 1 ;;
    esac
fi

# Handle old-style direct branch type commands (backward compatibility)
if [[ "$subcommand" =~ ^(feature|fix|release|hotfix)$ ]]; then
    # Old style: branch.sh feature add-cmd
    # Treat as: branch.sh create feature add-cmd
    create_branch "$subcommand" "$arg1"
    exit 0
fi

# Handle new subcommands
case $subcommand in
    create)
        create_branch "$arg1" "$arg2"
        ;;
    delete)
        delete_branch "$arg1"
        ;;
    *)
        print_error "Invalid subcommand: $subcommand"
        show_usage
        exit 1
        ;;
esac
