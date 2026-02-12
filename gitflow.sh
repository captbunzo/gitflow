#!/usr/bin/env bash

# ==============================================================================
# GitFlow Automation - Main Entry Point
# ==============================================================================
#
# File: gitflow.sh
# Description: Main command-line interface for GitFlow automation.
#              Routes commands to appropriate subcommand scripts.
#
# Usage: gitflow.sh [COMMAND] [SUBCOMMAND] [OPTIONS]
#
# Commands:
#   - branch:  Create/delete feature, fix, release, and hotfix branches
#   - pr:      Create and merge pull requests
#   - release: Manage release workflow (RC tags, shipping to production)
#   - hotfix:  Ship hotfixes directly to production
#   - status:  View repository status and open PRs
#
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Show usage information
show_usage() {
    cat <<EOF
Usage: gitflow.sh [COMMAND] [SUBCOMMAND] [OPTIONS]

GitFlow automation for your git repository.

COMMANDS:
  b, branch SUBCOMMAND [OPTIONS]   Manage branches (create, delete)
  p, pr SUBCOMMAND [OPTIONS]       Manage pull requests (create, merge)
  r, release SUBCOMMAND [OPTIONS]  Manage releases (rc, ship)
  h, hotfix SUBCOMMAND [OPTIONS]   Manage hotfixes (ship)
  s, status                        View git status and open PRs
  ?, help                          Show this help message

EXAMPLES:
  gitflow.sh                           # Interactive menu
  gitflow.sh b create feature add-cmd  # Create feature branch
  gitflow.sh branch delete             # Delete branch (interactive)
  gitflow.sh p create                  # Create PR (alias)
  gitflow.sh pr merge                  # Merge PR and cleanup
  gitflow.sh r rc 1.2.0                # Create RC tag (alias)
  gitflow.sh release ship 1.2.0        # Ship to prod (merge + tag)
  gitflow.sh h ship 1.2.1              # Ship hotfix (alias)
  gitflow.sh s                         # View status (alias)

CONFIGURATION:
  Copy .gitflowrc.example to .gitflowrc in your repo root to customize:
  - Package manager (npm/yarn/pnpm/bun/none)
  - Enable/disable versioning
  - Branch naming conventions
EOF
}

# Main menu
show_menu() {
    print_header "GitFlow Automation Menu"

    local current_branch
    current_branch=$(git branch --show-current)

    echo -e "${BLUE}Current branch:${NC} $current_branch"
    echo ""
    echo "Development:"
    echo -e "  ${CYAN}A${NC}) Create feature branch"
    echo -e "  ${CYAN}B${NC}) Create fix branch"
    echo -e "  ${CYAN}C${NC}) Create PR to develop"
    echo -e "  ${CYAN}D${NC}) Merge PR and cleanup"
    echo ""
    echo "Release Management:"
    echo -e "  ${CYAN}E${NC}) Create release branch"
    echo -e "  ${CYAN}F${NC}) Create release candidate (RC) tag"
    echo -e "  ${CYAN}G${NC}) Ship release to production (merge + tag + deploy)"
    echo ""
    echo "Hotfix Management:"
    echo -e "  ${CYAN}H${NC}) Create hotfix branch"
    echo -e "  ${CYAN}I${NC}) Ship hotfix to production (merge + tag + deploy)"
    echo ""
    echo "Utilities:"
    echo -e "  ${CYAN}S${NC}) View status"
    echo -e "  ${CYAN}Q${NC}) Quit"
    echo ""
}

# Execute command from CLI arguments
execute_cli_command() {
    local cmd="$1"
    shift  # Remove command name, leaving only arguments

    case "$cmd" in
        # Branch creation
        b|branch|-branch|--branch)
            bash "$SCRIPT_DIR/commands/branch.sh" "$@"
            ;;

        # Pull request management
        p|pr|-pr|--pr)
            bash "$SCRIPT_DIR/commands/pr.sh" "$@"
            ;;

        # Release workflow
        r|release|-release|--release)
            bash "$SCRIPT_DIR/commands/release.sh" "$@"
            ;;

        # Hotfix workflow
        h|hotfix|-hotfix|--hotfix)
            bash "$SCRIPT_DIR/commands/hotfix.sh" "$@"
            ;;

        # Status
        s|status|-status|--status)
            bash "$SCRIPT_DIR/commands/status.sh" "$@"
            ;;

        # Help
        help|-help|--help|-h|--h|-?|--?|usage|-usage|--usage)
            show_usage
            exit 0
            ;;

        *)
            return 1
            ;;
    esac
}

# Execute command from interactive menu
execute_menu_command() {
    local choice="$1"

    case "$choice" in
        # Feature branch
        A|a)
            bash "$SCRIPT_DIR/commands/branch.sh" feature
            ;;

        # Fix branch
        B|b)
            bash "$SCRIPT_DIR/commands/branch.sh" fix
            ;;

        # Create PR
        C|c)
            bash "$SCRIPT_DIR/commands/pr.sh" create
            ;;

        # Merge PR
        D|d)
            bash "$SCRIPT_DIR/commands/pr.sh" merge
            ;;

        # Release branch
        E|e)
            bash "$SCRIPT_DIR/commands/branch.sh" release
            ;;

        # Release candidate
        F|f)
            bash "$SCRIPT_DIR/commands/release.sh" rc
            ;;

        # Ship release
        G|g)
            bash "$SCRIPT_DIR/commands/release.sh" ship
            ;;

        # Hotfix branch
        H|h)
            bash "$SCRIPT_DIR/commands/branch.sh" hotfix
            ;;

        # Ship hotfix
        I|i)
            bash "$SCRIPT_DIR/commands/hotfix.sh" ship
            ;;

        # Status
        S|s)
            bash "$SCRIPT_DIR/commands/status.sh"
            ;;

        # Quit
        Q|q)
            print_info "Goodbye!"
            exit 0
            ;;

        *)
            return 1
            ;;
    esac
}

# Interactive menu (runs once)
run_menu() {
    show_menu
    read -rp "Enter choice: " choice

    if ! execute_menu_command "$choice"; then
        print_error "Invalid choice."
        exit 1
    fi
}

# Main script
main() {
    ensure_repo_root
    check_requirements

    # If command provided, execute it directly
    if [ $# -gt 0 ]; then
        local cmd="$1"
        shift  # Remove command name, leaving arguments

        local result=0
        execute_cli_command "$cmd" "$@"
        result=$?

        if [ $result -eq 0 ]; then
            exit 0
        else
            print_error "Unknown command: $cmd"
            echo ""
            show_usage
            exit 1
        fi
    else
        # No command provided, show interactive menu
        run_menu
    fi
}

# Run main
main "$@"
