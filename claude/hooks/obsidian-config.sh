#!/bin/bash

# Obsidian Integration Configuration
# Source this file in your shell profile to configure Obsidian integration

# Path to your Obsidian vault (adjust this to your vault location)
export OBSIDIAN_VAULT="$HOME/Documents/Obsidian/Development"

# Base directory within Obsidian vault for Claude sessions
export CLAUDE_BASE_DIR="claude-sessions"

# Enable/disable Obsidian logging (set to false to disable)
export ENABLE_OBSIDIAN_LOGGING="true"

# Additional configuration options
export OBSIDIAN_LOG_COMMANDS="true"        # Log bash commands
export OBSIDIAN_LOG_FILE_CHANGES="true"    # Log file modifications
export OBSIDIAN_LOG_GIT_STATUS="true"      # Include git status
export OBSIDIAN_CREATE_DAILY_SUMMARY="true" # Create daily summary files

# Function to test Obsidian integration
test_obsidian_integration() {
    echo "Testing Obsidian integration..."
    echo "Vault path: $OBSIDIAN_VAULT"
    
    if [[ -d "$OBSIDIAN_VAULT" ]]; then
        echo "✅ Obsidian vault found"
        
        # Test creating a test file
        TEST_DIR="$OBSIDIAN_VAULT/$CLAUDE_BASE_DIR/test"
        mkdir -p "$TEST_DIR"
        TEST_FILE="$TEST_DIR/test-$(date +%s).md"
        echo "# Test File" > "$TEST_FILE"
        
        if [[ -f "$TEST_FILE" ]]; then
            echo "✅ Successfully created test file"
            rm "$TEST_FILE"
            rmdir "$TEST_DIR" 2>/dev/null || true
        else
            echo "❌ Failed to create test file"
        fi
    else
        echo "❌ Obsidian vault not found at $OBSIDIAN_VAULT"
        echo "   Please update OBSIDIAN_VAULT in this file"
    fi
}

# Add to your .bashrc or .zshrc:
# source ~/.claude/hooks/obsidian-config.sh