# 🚀 GitFlow Automation

> A powerful command-line tool for automating GitFlow workflows with built-in safety checks and intelligent branch management.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

## Features

- ✅ **Interactive & CLI modes** - Use menus or direct commands
- ✅ **Safety checks** - Verifies branches are up-to-date before tagging/shipping
- ✅ **Smart branch switching** - Returns you to your original branch after operations
- ✅ **Tab completion** - Bash completion for all commands
- ✅ **Flexible versioning** - Works with or without package.json
- ✅ **Single-letter aliases** - Fast shortcuts for all commands

## Installation

To install the `gitflow` command with bash completion:

```bash
cd /path/to/gitflow
./install.sh
source ~/.bashrc  # or open a new terminal
```

After installation, you can run `gitflow` (or the short alias `gf`) from anywhere in the repository.

## Quick Start

```bash
# Interactive menu
gitflow
# or use the short alias
gf

# Show help
gitflow help
# or
gf help

# Tab completion works for all commands
gitflow <TAB>
gf <TAB>
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
| status  | s     | View git status and open PRs               |
| help    | ?     | Show help message                          |

### Branch Management

Create branches for different workflow types:

```bash
# Feature branch (full command)
gitflow branch create feature add-new-command
gitflow branch create feature user-authentication

# Feature branch (alias)
gitflow b create feature add-new-command

# Fix branch
gitflow branch create fix memory-leak
gitflow b create fix correct-typo

# Release branch (interactive version selection)
gitflow branch create release
gitflow b create release

# Release branch (direct version)
gitflow branch create release 1.2.0
gitflow b create release 1.2.0

# Hotfix branch
gitflow branch create hotfix 1.2.1
gitflow b create hotfix 1.2.1

# Delete branches (interactive)
gitflow branch delete
gitflow b delete

# Delete specific branch
gitflow branch delete feature/my-feature
gitflow b delete feature/my-feature
```

**Note:** Creating release/hotfix branches automatically pushes them to origin and triggers Staging deployment.

#### 📦 Smart Version Selection for Releases

When creating a release branch without specifying a version, an interactive menu is displayed based on the current version in `package.json`:

```
Current version: 1.2.3

Select version for new release:
  1) 1.2.4 (patch - bug fixes)
  2) 1.3.0 (minor - new features)
  3) 2.0.0 (major - breaking changes)
  C) Custom version

Enter choice:
```

This follows [Semantic Versioning](https://semver.org/):
- **Patch** (1.2.3 → 1.2.4): Bug fixes and minor changes
- **Minor** (1.2.3 → 1.3.0): New features, backward compatible
- **Major** (1.2.3 → 2.0.0): Breaking changes

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

**Note:** The `merge` command deletes the remote branch and returns you to your original branch if you weren't on the merged branch.

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

**Safety Features:**
- Automatically checks if your local branch is up-to-date with remote
- Prompts you to pull if behind remote before tagging/shipping
- Prevents tagging/shipping stale code
- Returns you to your original branch after completion

### Hotfix Workflow

Manage hotfixes from main → staging → production:

```bash
# Ship hotfix (merge to main and develop, tag production) (full command)
gitflow hotfix ship 1.2.1

# Ship hotfix (alias)
gitflow h ship 1.2.1
```

**Safety Features:**
- Automatically checks if your local branch is up-to-date with remote
- Prompts you to pull if behind remote before shipping
- Prevents shipping stale code
- Returns you to your original branch after completion

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
gitflow b create feature add-new-feature

# 2. Make changes, commit
git add .
git commit -m "Add new feature"

# 3. Push changes
git push

# 4. Create PR to develop (with alias)
gitflow p create

# 5. After review, merge PR (with alias)
gitflow p merge
```

### Release Cycle

```bash
# 1. Create release branch from develop (with interactive version selection)
gf b create release
# Choose from:
#   1) Patch version (e.g., 1.2.4) - for bug fixes
#   2) Minor version (e.g., 1.3.0) - for new features
#   3) Major version (e.g., 2.0.0) - for breaking changes
#   C) Custom version

# Or specify version directly
gf b create release 1.2.0

# 2. Branch is auto-pushed (triggers Staging deployment)
# No manual push needed!

# 3. Test on staging, make fixes if needed, then create RC tag
gf r rc 1.2.0

# 4. If issues found, create another RC
gf r rc 1.2.0 --rc 2

# 5. After approval, ship release (merges to main & develop, creates production tag)
gf r ship 1.2.0
```

**Safety checks during RC creation and shipping:**
- Verifies local branch matches remote
- Prompts to pull if out of sync
- Prevents tagging/shipping stale code
- Returns to original branch when done

### Hotfix Cycle

```bash
# 1. Create hotfix branch from main (with alias)
gf b create hotfix 1.2.1

# 2. Branch is auto-pushed (triggers Staging deployment)
# Make your fix, commit, push
git add .
git commit -m "Fix critical bug"
git push

# 3. After testing on staging, ship hotfix (merges to main & develop, creates production tag)
gf h ship 1.2.1
```

**Safety checks during shipping:**
- Verifies local branch matches remote
- Prompts to pull if out of sync  
- Prevents shipping stale code
- Returns to original branch when done

## Safety Features

GitFlow Automation includes multiple safety checks to prevent common mistakes:

### Branch Synchronization
- **Before tagging or shipping**: Automatically fetches and compares local/remote branches
- **If out of sync**: Prompts you to pull changes before proceeding
- **If diverged**: Stops and asks you to resolve conflicts manually
- **If unpushed commits**: Reminds you to push before continuing

### Smart Branch Switching
- **Automatic return**: Commands that temporarily switch branches will return you to your original branch
- **Clean working tree**: Checks for uncommitted changes before switching branches
- **Stale tracking refs**: Automatically cleans up when deleting branches

### Production Protection
- **Tag command**: Requires you to be on `main` branch (intentional "speed bump" for production)
- **Version validation**: Ensures semantic versioning format (e.g., 1.2.0)
- **Duplicate prevention**: Checks if tags already exist before creating them

### Error Handling
- **Graceful failures**: Clear error messages with actionable next steps
- **Remote branch cleanup**: Handles already-deleted remote branches gracefully
- **Uncommitted changes**: Prevents branch switches when you have uncommitted work

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
    └── status.sh           # Status view
```

## Requirements

- Git
- GitHub CLI (`gh`)
- jq (optional, for JSON parsing in completions)
- Node.js package manager (npm/yarn/pnpm/bun) if using versioning

## Configuration

Create a `.gitflowrc` file in your repository root to customize behavior. Copy from the example:

```bash
cp .gitflowrc.example .gitflowrc
```

### Configuration Options

```bash
# Package manager for versioning (auto, npm, yarn, pnpm, bun, or none)
# 'auto' detects based on lock files (default)
# Set to 'none' for non-Node.js projects
PACKAGE_MANAGER=auto

# Enable semantic versioning for release/hotfix branches
# When true, creates version bump commits in package.json
# Set to false for projects that don't use package.json versioning
ENABLE_VERSIONING=true

# Branch prefixes (optional, defaults shown)
FEATURE_PREFIX=feature
FIX_PREFIX=fix
RELEASE_PREFIX=release
HOTFIX_PREFIX=hotfix

# Base branches (optional, defaults shown)
DEVELOP_BRANCH=develop
MAIN_BRANCH=main
```

### Non-Node.js Projects

For projects without package.json (Go, Python, Java, etc.):

```bash
# In your .gitflowrc
PACKAGE_MANAGER=none
ENABLE_VERSIONING=false
```

This disables version bumping but keeps all other GitFlow features.

## Troubleshooting

### "Not inside a git repository"
Make sure you're running commands from within a git repository. GitFlow automatically changes to the repository root.

### "Missing required commands"
Install the required dependencies:
- **Git**: `sudo apt-get install git` (Linux) or `brew install git` (macOS)
- **GitHub CLI**: `brew install gh` or [download from GitHub](https://cli.github.com/)
- **jq** (optional): `brew install jq` or `sudo apt-get install jq`

### "Local branch is behind remote"
When you see this, GitFlow detected your local branch is out of date. Accept the prompt to pull, or manually run:
```bash
git pull origin <branch-name>
```

### "Branches have diverged"
Your local and remote branches have conflicting commits. Resolve manually:
```bash
git fetch origin
git status
# Resolve conflicts, then:
git merge origin/<branch-name>
# or
git rebase origin/<branch-name>
```

### "Remote ref does not exist" when deleting
This means the remote branch was already deleted (common if deleted via GitHub UI). GitFlow now handles this gracefully and continues with local cleanup.

### Tab completion not working
Reload your shell configuration:
```bash
source ~/.bashrc  # or ~/.zshrc for zsh
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### Development

The project structure is modular:
- `gitflow.sh` - Main entry point and menu system
- `commands/*.sh` - Individual command implementations
- `lib/common.sh` - Shared utilities and helpers
- `gitflow-completion.bash` - Bash completion script

### Testing

Test changes locally before submitting:
```bash
# Test in a git repository
cd /path/to/test/repo
/path/to/gitflow/gitflow.sh <command>
```

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Author

Created by [@captbunzo](https://github.com/captbunzo)

## Acknowledgments

Built to streamline GitFlow workflows with safety and automation in mind.
