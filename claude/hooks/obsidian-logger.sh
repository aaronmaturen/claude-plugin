#!/bin/bash

# Obsidian Logger Hook
# Main hook that integrates with Claude's hook system
# Logs all interactions to Obsidian vault

set -euo pipefail

# Configuration - can be overridden by environment variables
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/Obsidian/Development}"
CLAUDE_BASE_DIR="${CLAUDE_BASE_DIR:-claude-sessions}"
ENABLE_LOGGING="${ENABLE_OBSIDIAN_LOGGING:-true}"

# Check if logging is enabled
if [[ "$ENABLE_LOGGING" != "true" ]]; then
    exit 0
fi

# Ensure Obsidian vault exists
if [[ ! -d "$OBSIDIAN_VAULT" ]]; then
    echo "Warning: Obsidian vault not found at $OBSIDIAN_VAULT" >&2
    exit 0
fi

# Get project information
PROJECT_PATH=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_PATH")
PARENT_DIR=$(basename "$(dirname "$PROJECT_PATH")")

# Get current git branch and extract JIRA ticket if present
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
JIRA_TICKET=""

# Enhanced JIRA pattern matching
if [[ "$CURRENT_BRANCH" =~ ([A-Z]+-[0-9]+) ]]; then
    JIRA_TICKET="${BASH_REMATCH[1]}"
fi

# Determine file name based on context
if [[ -n "$JIRA_TICKET" ]]; then
    SESSION_FILE="${JIRA_TICKET}.md"
else
    SESSION_FILE="$(date +%Y-%m-%d).md"
fi

# Create Obsidian directory structure
OBSIDIAN_DIR="${OBSIDIAN_VAULT}/${CLAUDE_BASE_DIR}/${PARENT_DIR}/${PROJECT_NAME}"
mkdir -p "$OBSIDIAN_DIR"

# Full file path
FILE_PATH="${OBSIDIAN_DIR}/${SESSION_FILE}"
TIMESTAMP=$(date "+%H:%M:%S")

# Initialize file if needed
if [[ ! -f "$FILE_PATH" ]]; then
    cat > "$FILE_PATH" << EOF
---
type: claude-session
project: ${PROJECT_NAME}
parent: ${PARENT_DIR}
branch: ${CURRENT_BRANCH}
ticket: ${JIRA_TICKET:-none}
date: $(date +%Y-%m-%d)
tags: [claude, ai-development, ${PROJECT_NAME}${JIRA_TICKET:+, ${JIRA_TICKET}}]
---

# Claude Session: ${SESSION_FILE%.md}

**Project**: \`${PARENT_DIR}/${PROJECT_NAME}\`  
**Branch**: \`${CURRENT_BRANCH}\`  
${JIRA_TICKET:+**JIRA**: [[${JIRA_TICKET}]]  }
**Started**: $(date "+%Y-%m-%d %H:%M:%S")

## Session Activity

EOF
fi

# Function to log with proper formatting
log_entry() {
    local entry_type="$1"
    local content="$2"
    
    case "$entry_type" in
        "command")
            # Skip logging raw commands - we'll log meaningful actions instead
            ;;
        
        "file_change")
            echo "" >> "$FILE_PATH"
            echo "### [$TIMESTAMP] File Modified" >> "$FILE_PATH"
            echo "- **File**: \`$content\`" >> "$FILE_PATH"
            
            # Try to capture the change type
            if [[ -f "$content" ]]; then
                echo "- **Action**: Modified" >> "$FILE_PATH"
            else
                echo "- **Action**: Created/Deleted" >> "$FILE_PATH"
            fi
            ;;
        
        "test_result")
            echo "" >> "$FILE_PATH"
            echo "### [$TIMESTAMP] Test Results" >> "$FILE_PATH"
            echo "\`\`\`" >> "$FILE_PATH"
            echo "$content" >> "$FILE_PATH"
            echo "\`\`\`" >> "$FILE_PATH"
            ;;
        
        "error")
            echo "" >> "$FILE_PATH"
            echo "### [$TIMESTAMP] ⚠️ Error" >> "$FILE_PATH"
            echo "\`\`\`" >> "$FILE_PATH"
            echo "$content" >> "$FILE_PATH"
            echo "\`\`\`" >> "$FILE_PATH"
            ;;
        
        "action")
            echo "" >> "$FILE_PATH"
            echo "### [$TIMESTAMP] 🤖 Claude Action" >> "$FILE_PATH"
            echo "$content" >> "$FILE_PATH"
            ;;
        
        *)
            echo "" >> "$FILE_PATH"
            echo "### [$TIMESTAMP] $entry_type" >> "$FILE_PATH"
            echo "$content" >> "$FILE_PATH"
            ;;
    esac
}

# Main hook logic - detect what triggered this hook
if [[ -n "${CLAUDE_HOOK_TYPE:-}" ]]; then
    case "$CLAUDE_HOOK_TYPE" in
        "post_edit")
            log_entry "file_change" "${CLAUDE_FILE_PATH:-unknown}"
            ;;
        
        "post_command")
            log_entry "command" "${CLAUDE_COMMAND:-unknown}"
            ;;
        
        "test_complete")
            log_entry "test_result" "${CLAUDE_TEST_OUTPUT:-No output}"
            ;;
        
        *)
            log_entry "event" "Hook type: $CLAUDE_HOOK_TYPE"
            ;;
    esac
fi

# If called directly with arguments
if [[ $# -gt 0 ]]; then
    log_entry "$1" "${2:-}"
fi

# Add git status periodically
if [[ -d .git ]] && [[ $(($RANDOM % 10)) -eq 0 ]]; then
    GIT_STATUS=$(git status --short 2>/dev/null || echo "")
    if [[ -n "$GIT_STATUS" ]]; then
        echo "" >> "$FILE_PATH"
        echo "#### Current Git Status" >> "$FILE_PATH"
        echo "\`\`\`" >> "$FILE_PATH"
        echo "$GIT_STATUS" >> "$FILE_PATH"
        echo "\`\`\`" >> "$FILE_PATH"
    fi
fi

exit 0