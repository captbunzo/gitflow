# GitFlow Automation

Command-line tool for automating GitFlow workflows.

## Installation

To install the `gitflow` command with bash completion:

```bash
cd /path/to/gitflow
./install.sh
source ~/.bashrc  # or open a new terminal
```

After installation, you can run `gitflow` from anywhere in the repository.

## Quick Start

```bash
# Interactive menu
gitflow

# Show help
gitflow help

# Tab completion works for all commands
gitflow <TAB>
```

## Command Structure

All commands support both full names and single-letter aliases for faster typing.

### Available Commands

| Command | Alias | Description                                |
| ------- | ----- | ------------------------------------------ |
| branch  | b     | Manage branches (create/delete)            |
| pr      | p     | Manage pull requests (create/merge)        |
| release | r     | Manage releases (rc/ship)                  |
| hotfix  | h     | Manage hotfixes (ship)                     |
| tag     | t     | Tag production release                     |
| status  | s     | View git status and open PRs               |
| help    | ?     | Show help message                          |

### Branch Management

Create branches for different workflow types:

```bash
# Feature branch (full command)
gitflow branch feature add-new-command
gitflow branch feature user-authentication

# Feature branch (alias)
gitflow b feature add-new-command

# Fix branch
gitflow branch fix memory-leak
gitflow b fix correct-typo

# Release branch
gitflow branch release 1.2.0
gitflow b release 1.2.0

# Hotfix branch (version-based, matches release pattern)
gitflow branch hotfix 1.2.1
gitflow b hotfix 1.2.1
```

### Pull Request Workflow

Manage PRs from feature/fix branches to develop:

```bash
# Create PR from current branch (full command)
gitflow pr create

# Create PR from current branch (alias)
gitflow p create

# Create PR from specific branch
gitflow pr create feature/my-feature
gitflow p create feature/my-feature

# Merge PR and cleanup
gitflow pr merge
gitflow p merge

# Merge specific PR
gitflow pr merge feature/my-feature
gitflow p merge feature/my-feature
```

### Release Workflow

Manage releases from develop → staging → UAT → production:

```bash
# Create release candidate (RC) tag (full command)
gitflow release rc 1.2.0
gitflow release rc 1.2.0 --rc 2  # Second RC

# Create RC tag (alias)
gitflow r rc 1.2.0

# Ship release (merge to main and develop, tag production)
gitflow release ship 1.2.0
gitflow r ship 1.2.0
```

### Hotfix Workflow

Manage hotfixes from main → staging → UAT → production:

```bash
# Ship hotfix (merge to main and develop, tag production) (full command)
gitflow hotfix ship 1.2.1

# Ship hotfix (alias)
gitflow h ship 1.2.1
```

### Production Tagging

Tag production releases:

```bash
# Tag production release (full command)
gitflow tag 1.2.0

# Tag production release (alias)
gitflow t 1.2.0
```

### Status

View current git status, version, and open PRs:

```bash
# Full command
gitflow status

# Alias
gitflow s
```

### Help

Get help information:

```bash
# Full command
gitflow help

# Alias
gitflow ?
```

## Interactive Menu

When running without arguments, an interactive menu is displayed:

```
╔════════════════════════════════════════╗
║   GitFlow Automation Menu              ║
╚════════════════════════════════════════╝

Current branch: develop

Development:
  A) Create feature branch
  B) Create fix branch
  C) Create PR to develop
  D) Merge PR and cleanup

Release Management:
  E) Create release branch
  F) Create release candidate (RC) tag
  G) Ship release to production

Hotfix Management:
  H) Create hotfix branch
  I) Ship hotfix to production

Utilities:
  S) View status
  Q) Quit
```

## Complete GitFlow Workflow

### Feature Development

```bash
# 1. Create feature branch from develop (with alias)
gitflow b feature add-new-feature

# 2. Make changes, commit
git add .
git commit -m "Add new feature"

# 3. Create PR to develop (with alias)
gitflow p create

# 4. After review, merge PR (with alias)
gitflow p merge
```

### Release Cycle

```bash
# 1. Create release branch from develop (with alias)
gitflow b release 1.2.0

# 2. Branch is auto-pushed (triggers Staging deployment)
# No manual push needed!

# 3. Create RC tag (triggers UAT deployment) (with alias)
gitflow r rc 1.2.0

# 4. After UAT approval, ship release (with alias)
gitflow r ship 1.2.0
```

### Hotfix Cycle

```bash
# 1. Create hotfix branch from main (with alias)
gitflow b hotfix 1.2.1

# 2. Branch is auto-pushed (triggers Staging deployment)
# Make your fix, commit
git add .
git commit -m "Fix critical bug"
git push

# 3. After testing, ship hotfix (with alias)
gitflow h ship 1.2.1
```

## File Structure

```
gitflow/
├── gitflow.sh              # Main entry point
├── gitflow-completion.bash # Bash completion
├── install.sh              # Installation script
├── .gitflowrc.example      # Example configuration
├── README.md               # This file
├── LICENSE                 # License file
├── lib/
│   └── common.sh           # Shared utilities
└── commands/
    ├── branch.sh           # Branch management (create, delete)
    ├── pr.sh               # PR management (create, merge)
    ├── release.sh          # Release workflow (rc, ship)
    ├── hotfix.sh           # Hotfix workflow (ship)
    ├── tag.sh              # Production tagging
    └── status.sh           # Status view
```

## Requirements

- Git
- GitHub CLI (`gh`)
- jq (optional, for JSON parsing in completions)
- Node.js package manager (npm/yarn/pnpm/bun) if using versioning

## Configuration

Copy `.gitflowrc.example` to `.gitflowrc` in your repository root to customize:

- Package manager (npm/yarn/pnpm/bun/none)
- Enable/disable versioning
- Branch naming conventions
