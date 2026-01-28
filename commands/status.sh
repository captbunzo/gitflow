#!/usr/bin/env bash

# View git status, version, and open PRs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Show usage
show_usage() {
    cat <<EOF
Usage: status.sh [OPTIONS]

View git status, version, recent commits, and open PRs.

OPTIONS:
  -h, --help          Show this help message

EXAMPLES:
  status.sh
EOF
}

# Parse arguments
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

print_header "Git Status"

current_branch=$(get_current_branch)

print_info "Current branch: $current_branch"

current_version=$(get_current_version)
print_info "Current version: $current_version"

echo ""
git status

echo ""
print_info "Recent commits:"
git log --oneline -n 5

# Check for open PRs
echo ""
print_info "Open PRs:"
gh pr list || true
