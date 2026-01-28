#!/usr/bin/env bash

# Common utilities for GitFlow automation scripts

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Default configuration
export PACKAGE_MANAGER="auto"
export ENABLE_VERSIONING=true
export FEATURE_PREFIX="feature"
export FIX_PREFIX="fix"
export RELEASE_PREFIX="release"
export HOTFIX_PREFIX="hotfix"
export DEVELOP_BRANCH="develop"
export MAIN_BRANCH="main"

# Load configuration from .gitflowrc if it exists
load_config() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    
    if [ -n "$repo_root" ] && [ -f "$repo_root/.gitflowrc" ]; then
        # shellcheck source=/dev/null
        source "$repo_root/.gitflowrc"
    fi
}

# Detect package manager
detect_package_manager() {
    if [ "$PACKAGE_MANAGER" != "auto" ]; then
        echo "$PACKAGE_MANAGER"
        return
    fi
    
    # Check for lock files to determine package manager
    if [ -f "bun.lockb" ]; then
        echo "bun"
    elif [ -f "pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "yarn"
    elif [ -f "package-lock.json" ]; then
        echo "npm"
    elif [ -f "package.json" ]; then
        # Default to npm if package.json exists but no lock file
        echo "npm"
    else
        echo "none"
    fi
}

# Print functions
print_header() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if required commands are available
check_requirements() {
    local missing=()

    command -v git >/dev/null 2>&1 || missing+=("git")
    command -v gh >/dev/null 2>&1 || missing+=("gh")
    
    # Only check for package manager if versioning is enabled
    if [ "$ENABLE_VERSIONING" = true ]; then
        local pm
        pm=$(detect_package_manager)
        if [ "$pm" != "none" ] && ! command -v "$pm" >/dev/null 2>&1; then
            missing+=("$pm")
        fi
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing required commands: ${missing[*]}"
        echo "Please install them and try again."
        exit 1
    fi
}

# Check if there are uncommitted changes
check_clean_working_tree() {
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_error "You have uncommitted changes. Please commit or stash them first."
        git status --short
        exit 1
    fi
}

# Get current branch
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Get current version from package.json
get_current_version() {
    if [ ! -f "package.json" ]; then
        echo "0.0.0"
        return
    fi
    
    if command -v jq >/dev/null 2>&1; then
        jq -r '.version // "0.0.0"' package.json
    else
        # Fallback to grep/sed if jq not available
        grep -m 1 '"version"' package.json | sed 's/.*"version": "\(.*\)".*/\1/' || echo "0.0.0"
    fi
}

# Bump version using appropriate package manager
bump_version() {
    local version="$1"
    local pm
    pm=$(detect_package_manager)
    
    if [ "$pm" = "none" ]; then
        print_error "No package manager detected. Cannot bump version."
        return 1
    fi
    
    case "$pm" in
        npm)
            npm version "$version" --no-git-tag-version
            ;;
        yarn)
            yarn version --new-version "$version" --no-git-tag-version
            ;;
        pnpm)
            pnpm version "$version" --no-git-tag-version
            ;;
        bun)
            bun pm version "$version" --no-git-tag-version
            ;;
        *)
            print_error "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

# Validate semantic version format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 1
    fi
    return 0
}

# Find and change to repository root
ensure_repo_root() {
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_error "Not inside a git repository"
        exit 1
    fi

    # Get the repository root directory
    local repo_root
    repo_root=$(git rev-parse --show-toplevel)

    # Change to repository root
    cd "$repo_root" || {
        print_error "Failed to change to repository root: $repo_root"
        exit 1
    }
    
    # Load configuration
    load_config

    # Verify package.json exists if versioning is enabled
    if [ "$ENABLE_VERSIONING" = true ] && [ ! -f "package.json" ]; then
        print_warning "Versioning enabled but no package.json found"
        print_info "Set ENABLE_VERSIONING=false in .gitflowrc for non-Node projects"
    fi
}

# List branches matching a prefix, sorted by most recent commit (newest first)
# Usage: list_branches_by_prefix "release" -> lists release/* branches
list_branches_by_prefix() {
    local prefix="$1"
    git for-each-ref --sort=-committerdate --format='%(refname:short)' "refs/heads/${prefix}/*" 2>/dev/null
}

# Prompt user to select and switch to a branch from a list
# Usage: prompt_switch_to_branch "release" "release branch"
# Returns 0 if switched, 1 if no branches or user cancelled
prompt_switch_to_branch() {
    local prefix="$1"
    local branch_type="$2"
    
    # Get list of branches
    local branches
    branches=$(list_branches_by_prefix "$prefix")
    
    if [ -z "$branches" ]; then
        print_error "No ${branch_type}es found."
        print_info "Create one first with: gitflow branch ${prefix}"
        return 1
    fi
    
    # Convert to array
    local branch_array=()
    while IFS= read -r branch; do
        branch_array+=("$branch")
    done <<< "$branches"
    
    local count=${#branch_array[@]}
    
    echo -e "${CYAN}Available ${branch_type}es (most recent first):${NC}"
    echo
    
    local i=1
    for branch in "${branch_array[@]}"; do
        # Get the last commit date for context
        local commit_date
        commit_date=$(git log -1 --format='%cr' "$branch" 2>/dev/null || echo "unknown")
        printf "  %d) %-30s ${BLUE}(%s)${NC}\n" "$i" "$branch" "$commit_date"
        ((i++))
    done
    
    echo
    echo "  Q) Quit"
    echo
    
    read -rp "Select a ${branch_type} to switch to: " choice
    echo
    
    # Handle quit
    if [[ "$choice" =~ ^[Qq]$ ]]; then
        print_info "Cancelled."
        return 1
    fi
    
    # Validate selection
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
        print_error "Invalid selection: $choice"
        return 1
    fi
    
    local selected_branch="${branch_array[$((choice-1))]}"
    
    # Check for uncommitted changes before switching
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_error "You have uncommitted changes that would be overwritten."
        print_info "Please commit or stash your changes first:"
        echo
        git status --short
        echo
        print_info "Tip: Use 'git stash' to temporarily save changes"
        return 1
    fi
    
    print_info "Switching to $selected_branch..."
    if ! git checkout "$selected_branch"; then
        print_error "Failed to switch to $selected_branch"
        return 1
    fi
    
    print_success "Switched to $selected_branch"
    echo
    
    return 0
}
