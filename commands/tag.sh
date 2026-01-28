#!/usr/bin/env bash

# Tag production release

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Show usage
show_usage() {
    cat <<EOF
Usage: tag.sh [VERSION] [OPTIONS]

Tag and release to production.

ARGUMENTS:
  VERSION             Semantic version (e.g., 1.2.0)

OPTIONS:
  -h, --help         Show this help message

EXAMPLES:
  # Tag production release
  tag.sh 1.2.0

  # Interactive mode
  tag.sh
EOF
}

# Parse arguments
version=""

# First positional argument is the version (if not a flag)
if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
    version="$1"
    shift
fi

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

print_header "Tag Production Release"

ensure_repo_root

current_branch=$(git branch --show-current)

# Validate we're on main branch
if [ "$current_branch" != "main" ]; then
    print_error "Not on main branch."
    print_info "Current: $current_branch"
    print_info "Switch to main first: git checkout main"
    exit 1
fi

# Get version
if [ -z "$version" ]; then
    current_version=$(get_current_version)
    print_info "Current version: $current_version"
    read -rp "Enter version to tag [$current_version]: " input_version
    version="${input_version:-$current_version}"
fi

if ! validate_version "$version"; then
    print_error "Invalid version format: $version. Use semantic versioning (e.g., 1.2.0)"
    exit 1
fi

# Check if local main is up to date
git fetch origin main --quiet
local_hash=$(git rev-parse HEAD)
remote_hash=$(git rev-parse "origin/main")

if [ "$local_hash" != "$remote_hash" ]; then
    print_error "Your local 'main' branch is not up to date with remote"
    print_info "Pull latest changes first: git pull origin main"
    exit 1
fi

release_tag="v$version"

# Check if tag already exists
if git rev-parse "$release_tag" >/dev/null 2>&1; then
    print_error "Tag $release_tag already exists!"
    exit 1
fi

print_warning "This will create tag $release_tag and trigger production deployment."
read -rp "Continue? [y/N]: " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_info "Cancelled"
    exit 0
fi

print_info "Creating production tag: $release_tag"
git tag "$release_tag"
git push origin "$release_tag"

print_success "Production tag $release_tag created!"
print_info "Production deployment will start automatically"
