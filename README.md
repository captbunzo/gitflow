# GitFlow Automation

Command-line tool for automating GitFlow workflows in the Professor Koa repository.

## Installation

To install the `gitflow` command with bash completion:

```bash
cd scripts/gitflow
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
| branch  | b     | Create branch (feature/fix/release/hotfix) |
| pr      | p     | Manage pull requests (create/merge)        |
| release | r     | Manage releases (rc/finalize)              |
| hotfix  | h     | Manage hotfixes (finalize)                 |
| tag     | t     | Tag production release                     |
| status  | s     | View git status and open PRs               |
| menu    | m     | Show interactive menu                      |
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

# Finalize release (merge to main and develop)
gitflow release finalize 1.2.0
gitflow r finalize 1.2.0
```

### Hotfix Workflow

Manage hotfixes from main → staging → UAT → production:

```bash
# Finalize hotfix (merge to main and develop) (full command)
gitflow hotfix finalize 1.2.1

# Finalize hotfix (alias)
gitflow h finalize 1.2.1
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
  G) Finalize release to production

Hotfix Management:
  H) Create hotfix branch
  I) Finalize hotfix to production

Production:
  J) Tag production release

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

# 4. After UAT approval, finalize release (with alias)
gitflow r finalize 1.2.0

# 5. Tag production (triggers Production deployment) (with alias)
gitflow t 1.2.0
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

# 3. Create RC tag (triggers UAT deployment) (with alias)
gitflow r rc 1.2.1 --rc 1

# 4. After UAT approval, finalize hotfix (with alias)
gitflow h finalize 1.2.1

# 5. Tag production (triggers Production deployment) (with alias)
gitflow t 1.2.1
```

## File Structure

```
scripts/gitflow/
├── gitflow.sh              # Main entry point
├── README.md               # This file
├── lib/
│   └── common.sh          # Shared utilities
└── commands/
    ├── branch.sh          # Branch creation
    ├── pr.sh              # PR management (create, merge)
    ├── release.sh         # Release workflow (rc, finalize)
    ├── hotfix.sh          # Hotfix workflow (finalize)
    ├── tag.sh             # Production tagging
    └── status.sh          # Status view
```

## Requirements

- Git
- GitHub CLI (`gh`)
- Bun (for `bun run gitflow`)
- jq (for JSON parsing)

## See Also

- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Full GitFlow documentation
- [GitHub Actions](.github/workflows/) - CI/CD pipeline details
