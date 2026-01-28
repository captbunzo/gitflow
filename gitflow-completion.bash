#!/usr/bin/env bash

# Bash completion for gitflow command

_gitflow_complete() {
    local cur prev words cword
    _init_completion || return

    # Top-level commands
    local commands="branch pr release hotfix tag status help"

    # Subcommands for each command
    local branch_cmds="create delete feature fix release hotfix"
    local pr_cmds="create merge"
    local release_cmds="rc ship"
    local hotfix_cmds="ship"

    # Get the command position (skip aliases)
    local cmd_pos=1
    local cmd="${words[$cmd_pos]}"

    case $cword in
        1)
            # Complete top-level commands
            COMPREPLY=($(compgen -W "$commands" -- "$cur"))
            ;;
        2)
            # Complete subcommands based on command
            case "$cmd" in
                branch|b)
                    COMPREPLY=($(compgen -W "$branch_cmds" -- "$cur"))
                    ;;
                pr|p)
                    COMPREPLY=($(compgen -W "$pr_cmds" -- "$cur"))
                    ;;
                release|r)
                    COMPREPLY=($(compgen -W "$release_cmds" -- "$cur"))
                    ;;
                hotfix|h)
                    COMPREPLY=($(compgen -W "$hotfix_cmds" -- "$cur"))
                    ;;
                tag|t)
                    # Suggest current version from package.json if available
                    if [ -f package.json ] && command -v jq &>/dev/null; then
                        local version=$(jq -r '.version' package.json 2>/dev/null)
                        [ -n "$version" ] && COMPREPLY=("$version")
                    fi
                    ;;
            esac
            ;;
        3)
            # Complete branch types, version numbers, or branch names
            local subcmd="${words[2]}"
            case "$cmd" in
                branch|b)
                    case "$subcmd" in
                        create)
                            COMPREPLY=($(compgen -W "feature fix release hotfix" -- "$cur"))
                            ;;
                        delete)
                            # Suggest feature, fix, release, hotfix branches
                            local branches=$(git branch --format='%(refname:short)' 2>/dev/null | grep -E '^(feature|fix|release|hotfix)/')
                            COMPREPLY=($(compgen -W "$branches" -- "$cur"))
                            ;;
                    esac
                    ;;
                pr|p)
                    case "$subcmd" in
                        create|merge)
                            # Suggest feature and fix branches
                            local branches=$(git branch --format='%(refname:short)' 2>/dev/null | grep -E '^(feature|fix)/')
                            COMPREPLY=($(compgen -W "$branches" -- "$cur"))
                            ;;
                    esac
                    ;;
                release|r)
                    # Suggest version from package.json for both rc and ship
                    if [ -f package.json ] && command -v jq &>/dev/null; then
                        local version=$(jq -r '.version' package.json 2>/dev/null)
                        [ -n "$version" ] && COMPREPLY=("$version")
                    fi
                    ;;
                hotfix|h)
                    # Suggest version from package.json
                    if [ -f package.json ] && command -v jq &>/dev/null; then
                        local version=$(jq -r '.version' package.json 2>/dev/null)
                        [ -n "$version" ] && COMPREPLY=("$version")
                    fi
                    ;;
            esac
            ;;
        4)
            # Handle options after version (e.g., release rc 1.2.0 --rc)
            local subcmd="${words[2]}"
            case "$cmd" in
                release|r)
                    if [ "$subcmd" = "rc" ]; then
                        case "$cur" in
                            -*)
                                COMPREPLY=($(compgen -W "--rc -h --h -help --help" -- "$cur"))
                                ;;
                        esac
                    fi
                    ;;
            esac
            ;;
        *)
            # Handle options anywhere
            case "$cur" in
                -*)
                    COMPREPLY=($(compgen -W "-h --h -help --help" -- "$cur"))
                    ;;
            esac
            ;;
    esac

    return 0
}

# Register completion
complete -F _gitflow_complete gitflow
