#!/usr/bin/env bash

# Install gitflow command and bash completion

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITFLOW_SCRIPT="$SCRIPT_DIR/gitflow.sh"
COMPLETION_SCRIPT="$SCRIPT_DIR/gitflow-completion.bash"

print_info() {
    echo -e "\033[0;36m→\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m✓\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m✗\033[0m $1"
}

print_info "Installing gitflow command..."

# Detect shell
SHELL_RC=""
if [ -n "${BASH_VERSION:-}" ]; then
    if [ -f ~/.bashrc ]; then
        SHELL_RC=~/.bashrc
    elif [ -f ~/.bash_profile ]; then
        SHELL_RC=~/.bash_profile
    fi
elif [ -n "${ZSH_VERSION:-}" ]; then
    SHELL_RC=~/.zshrc
fi

if [ -z "$SHELL_RC" ]; then
    print_error "Could not detect shell configuration file"
    exit 1
fi

print_info "Detected shell config: $SHELL_RC"

# Check if aliases already exist
if grep -q "alias gitflow=" "$SHELL_RC" 2>/dev/null; then
    print_info "Gitflow aliases already exist, updating..."
    # Remove old aliases
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/alias gitflow=/d' "$SHELL_RC"
        sed -i '' '/alias gf=/d' "$SHELL_RC"
    else
        sed -i '/alias gitflow=/d' "$SHELL_RC"
        sed -i '/alias gf=/d' "$SHELL_RC"
    fi
fi

# Add aliases
echo "" >> "$SHELL_RC"
echo "# GitFlow automation" >> "$SHELL_RC"
echo "alias gitflow='bash $GITFLOW_SCRIPT'" >> "$SHELL_RC"
echo "alias gf='bash $GITFLOW_SCRIPT'" >> "$SHELL_RC"

print_success "Added gitflow and gf aliases"

# Add bash completion
if [ -n "${BASH_VERSION:-}" ]; then
    if grep -q "source.*gitflow-completion.bash" "$SHELL_RC" 2>/dev/null; then
        print_info "Bash completion already configured"
    else
        echo "source $COMPLETION_SCRIPT" >> "$SHELL_RC"
        print_success "Added bash completion"
    fi
fi

print_success "Installation complete!"
echo ""
print_info "To start using gitflow, run:"
echo "  source $SHELL_RC"
echo ""
print_info "Or open a new terminal session"
echo ""
print_info "Usage: gitflow [command] [options]"
echo "  Or use the short alias: gf [command] [options]"
echo "  Run 'gitflow help' for more information"
