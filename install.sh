#!/bin/bash
set -euo pipefail

# clair-de-config installer
# "Don't Panic" - this script will backup everything before making changes

# Colors for output (because life is too short for monochrome)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
say() {
    echo -e "${BLUE}→${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions
source "$SCRIPT_DIR/utilities"

# Enable error handling
set_error_trap
CLAIR_ROLLBACK_ON_ERROR=true

# Create unique backup directory
BACKUP_DIR=$(create_unique_backup "" "$SCRIPT_DIR/backups")

# Acquire lock for installation
acquire_lock
CLAIR_LOCK_ACQUIRED=true

# Welcome message
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              clair-de-config Installation Script              ║"
echo "║                                                               ║"
echo "║  Synchronizing your Claude configuration across the cosmos    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the right directory
if [[ ! -f "$SCRIPT_DIR/README.md" ]] || [[ ! -f "$SCRIPT_DIR/clair-de-config" ]]; then
    error "This script must be run from the clair-de-config directory"
    exit 1
fi

# Check for required dependencies
say "Checking for required dependencies..."

# Check for Homebrew
if ! command -v brew >/dev/null 2>&1; then
    error "Homebrew is not installed"
    say "Install it from: https://brew.sh"
    say "Run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
else
    success "Homebrew found"
fi

# Check for GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
    warn "GitHub CLI is not installed"
    say "Installing GitHub CLI via Homebrew..."
    brew install gh || {
        error "Failed to install GitHub CLI"
        exit 1
    }
fi

# Check if GitHub CLI is authenticated
if ! gh auth status >/dev/null 2>&1; then
    warn "GitHub CLI is not authenticated"
    say "Please authenticate with: gh auth login"
    say "This is required for the atm-implement-pr-feedback and atm-pr-review commands"
else
    success "GitHub CLI authenticated"
fi

# Check for jira-cli
if ! command -v jira >/dev/null 2>&1; then
    warn "jira-cli is not installed"
    say "Installing jira-cli via Homebrew..."
    brew tap ankitpokhrel/jira-cli 2>/dev/null || true
    brew install ankitpokhrel/jira-cli/jira-cli || {
        error "Failed to install jira-cli"
        say "You can install it manually with:"
        say "  brew tap ankitpokhrel/jira-cli"
        say "  brew install ankitpokhrel/jira-cli/jira-cli"
    }
fi

# Check if jira-cli is configured
if command -v jira >/dev/null 2>&1; then
    if ! jira me >/dev/null 2>&1; then
        warn "jira-cli is not configured"
        say "Please configure it with: jira init"
        say "This is optional but enhances the atm-commit-msg command"
    else
        success "jira-cli configured"
    fi
fi

say "Dependency check complete"
echo ""

# Backup directory already created by create_unique_backup
say "Creating backup directory at $BACKUP_DIR"
log_operation "backup_created" "$BACKUP_DIR"

# Backup existing configurations
backup_if_exists() {
    local source=$1
    local name=$2
    
    if [[ -e "$source" ]]; then
        say "Backing up existing $name"
        cp -r "$source" "$BACKUP_DIR/$name"
        success "Backed up $name"
    fi
}

# Backup Claude configurations only (not aliases)
backup_if_exists "$HOME/.claude/settings.json" "claude-settings.json"
backup_if_exists "$HOME/.claude/CLAUDE.md" "CLAUDE.md"
backup_if_exists "$HOME/.claude/hooks" "claude-hooks"
backup_if_exists "$HOME/.claude/commands" "claude-commands"

# Create symlinks for Claude configurations only
create_symlink() {
    local source=$1
    local target=$2
    local name=$3
    
    # Validate source exists
    if [[ ! -e "$source" ]]; then
        error "Source file does not exist: $source"
        return 1
    fi
    
    # Remove existing file/symlink if it exists
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        say "Removing existing $name"
        rm -rf "$target"
    fi
    
    # Create parent directory if needed
    local target_dir=$(dirname "$target")
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi
    
    # Create symlink
    say "Creating symlink for $name"
    ln -s "$source" "$target"
    
    # Verify symlink was created correctly
    if verify_symlink "$target" "$source"; then
        success "Linked $name"
        log_operation "symlink_created" "$target"
    else
        error "Failed to create valid symlink for $name"
        return 1
    fi
}

# Create symlinks for Claude configurations
create_symlink "$SCRIPT_DIR/claude/settings.json" "$HOME/.claude/settings.json" "Claude settings"
create_symlink "$SCRIPT_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md" "Claude instructions"
create_symlink "$SCRIPT_DIR/claude/hooks" "$HOME/.claude/hooks" "Claude hooks"
create_symlink "$SCRIPT_DIR/claude/commands" "$HOME/.claude/commands" "Claude commands"

# Sync MCP servers
if [[ -x "$SCRIPT_DIR/bin/clair-mcp" ]]; then
    say "Syncing MCP servers..."
    "$SCRIPT_DIR/bin/clair-mcp" || {
        warn "Failed to sync MCP servers"
        say "You can manually sync them later with: $SCRIPT_DIR/bin/clair-mcp"
    }
else
    warn "clair-mcp script not found or not executable"
fi

# Update shell configuration with atomic writes
update_shell_rc() {
    local rc_file=$1
    local shell_name=$2
    
    if [[ -f "$rc_file" ]]; then
        local content
        content=$(cat "$rc_file")
        local updated=false
        
        # Check if clair-de-config aliases are already sourced
        if ! grep -q "$SCRIPT_DIR/aliases" "$rc_file"; then
            say "Adding clair-de-config aliases to $shell_name"
            content+="\n\n# Source clair-de-config aliases\n. \"$SCRIPT_DIR/aliases\""
            updated=true
        else
            warn "$shell_name already sources clair-de-config aliases"
        fi
        
        # Check if clair-de-config environment is already sourced
        if ! grep -q "$SCRIPT_DIR/.clair-de-config" "$rc_file"; then
            say "Adding clair-de-config environment to $shell_name"
            content+="\n\n# Source clair-de-config environment\n. \"$SCRIPT_DIR/.clair-de-config\""
            updated=true
        else
            warn "$shell_name already sources clair-de-config environment"
        fi
        
        # Check if obsidian-config.sh source is already present
        if ! grep -q "source ~/.claude/hooks/obsidian-config.sh" "$rc_file"; then
            say "Adding obsidian-config.sh to $shell_name"
            content+=$'\n\n# Add to your .bashrc or .zshrc:\n# source ~/.claude/hooks/obsidian-config.sh'
            updated=true
        else
            warn "$shell_name already sources obsidian-config.sh"
        fi
        
        # Atomic write if updated
        if [[ "$updated" == "true" ]]; then
            atomic_write "$rc_file" "$content"
            log_operation "file_modified" "$rc_file"
            success "Updated $shell_name"
        fi
    fi
}

# Update .zshrc
update_shell_rc "$HOME/.zshrc" ".zshrc"

# Update .bashrc if it exists
update_shell_rc "$HOME/.bashrc" ".bashrc"

# Make scripts executable
say "Making scripts executable"
chmod +x "$SCRIPT_DIR/clair-sync" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/clair-add-alias" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/clair-status" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/claude/hooks/"*.sh 2>/dev/null || true

# Final success message
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    Installation Complete!                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
success "Your Claude configuration is now synchronized"
success "Backup created at: $BACKUP_DIR"
echo ""
warn "Please restart your shell or run:"
echo "  source \"$SCRIPT_DIR/aliases\""
echo "  source \"$SCRIPT_DIR/.clair-de-config\""
echo ""
say "Available commands:"
echo "  • clair-sync       - Synchronize configurations"
echo "  • clair-add-alias  - Add a new alias"
echo "  • clair-status     - Check synchronization status"
echo ""
say "Your existing ~/.aliases file remains untouched"
say "clair-de-config aliases are sourced from: $SCRIPT_DIR/aliases"
echo ""
say "Remember: The answer to configuration synchronization is not 42,"
say "but it might involve running 'clair-sync' occasionally."
echo ""