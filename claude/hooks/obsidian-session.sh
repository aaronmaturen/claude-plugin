#!/bin/bash

# Obsidian Session Logger Hook
# Automatically saves Claude session details and summaries to Obsidian vault
# Folder structure: claude/parent_directory/project_directory/
# Files: JIRA-TICKET.md or YYYY-MM-DD.md

set -euo pipefail

# Configuration
OBSIDIAN_VAULT="$HOME/Documents/Obsidian/Development"  # Adjust to your vault location
CLAUDE_BASE_DIR="claude"

# Get project information
PROJECT_PATH=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_PATH")
PARENT_DIR=$(basename "$(dirname "$PROJECT_PATH")")

# Get current git branch and extract JIRA ticket if present
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "no-git")
JIRA_TICKET=""

# Check for JIRA patterns in branch name
if [[ "$CURRENT_BRANCH" =~ (PRO|BUG|FEAT|TASK)-[0-9]+ ]]; then
    JIRA_TICKET="${BASH_REMATCH[0]}"
fi

# Determine file name
if [[ -n "$JIRA_TICKET" ]]; then
    FILE_NAME="${JIRA_TICKET}.md"
else
    FILE_NAME="$(date +%Y-%m-%d).md"
fi

# Create Obsidian directory structure
OBSIDIAN_DIR="${OBSIDIAN_VAULT}/${CLAUDE_BASE_DIR}/${PARENT_DIR}/${PROJECT_NAME}"
mkdir -p "$OBSIDIAN_DIR"

# Full file path
FILE_PATH="${OBSIDIAN_DIR}/${FILE_NAME}"

# Get session information
SESSION_TIME=$(date "+%Y-%m-%d %H:%M:%S")
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# Function to append session entry
append_session_entry() {
    local action="$1"
    local details="$2"
    
    # Create file with header if it doesn't exist
    if [[ ! -f "$FILE_PATH" ]]; then
        cat > "$FILE_PATH" << EOF
# Claude Session: ${FILE_NAME%.md}

**Project**: ${PARENT_DIR}/${PROJECT_NAME}
**Branch**: ${CURRENT_BRANCH}
${JIRA_TICKET:+**JIRA Ticket**: ${JIRA_TICKET}}
**Created**: $(date "+%Y-%m-%d")

---

## Session Log

EOF
    fi
    
    # Append session entry
    cat >> "$FILE_PATH" << EOF

### ${SESSION_TIME}
**Action**: ${action}
${details:+**Details**: ${details}}

EOF
}

# Function to add file changes
log_file_changes() {
    local files_changed="$1"
    if [[ -n "$files_changed" ]]; then
        echo "#### Files Modified" >> "$FILE_PATH"
        echo '```' >> "$FILE_PATH"
        echo "$files_changed" >> "$FILE_PATH"
        echo '```' >> "$FILE_PATH"
        echo "" >> "$FILE_PATH"
    fi
}

# Function to capture git diff
log_git_diff() {
    local diff_output=$(git diff --stat 2>/dev/null || echo "No git diff available")
    if [[ "$diff_output" != "No git diff available" ]] && [[ -n "$diff_output" ]]; then
        echo "#### Changes Summary" >> "$FILE_PATH"
        echo '```' >> "$FILE_PATH"
        echo "$diff_output" >> "$FILE_PATH"
        echo '```' >> "$FILE_PATH"
        echo "" >> "$FILE_PATH"
    fi
}

# Main hook logic based on Claude events
case "${CLAUDE_HOOK_EVENT:-unknown}" in
    "session_start")
        append_session_entry "Session Started" "Claude session initiated"
        ;;
    
    "tool_use")
        TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
        TOOL_PARAMS="${CLAUDE_TOOL_PARAMS:-}"
        append_session_entry "Tool Used: $TOOL_NAME" "$TOOL_PARAMS"
        
        # Log file changes for edit tools
        if [[ "$TOOL_NAME" =~ ^(Edit|MultiEdit|Write)$ ]]; then
            FILES_CHANGED=$(echo "$TOOL_PARAMS" | grep -oE '"file_path":\s*"[^"]+' | cut -d'"' -f4 || echo "")
            log_file_changes "$FILES_CHANGED"
        fi
        ;;
    
    "command_run")
        COMMAND="${CLAUDE_COMMAND:-unknown}"
        append_session_entry "Command Executed" "$COMMAND"
        ;;
    
    "session_end")
        append_session_entry "Session Ended" "Claude session completed"
        log_git_diff
        
        # Add session summary
        echo "---" >> "$FILE_PATH"
        echo "" >> "$FILE_PATH"
        echo "## Session Summary" >> "$FILE_PATH"
        echo "" >> "$FILE_PATH"
        echo "- **Duration**: Session completed at ${SESSION_TIME}" >> "$FILE_PATH"
        echo "- **Tools Used**: Check session log above" >> "$FILE_PATH"
        echo "- **Next Steps**: Review changes and plan next actions" >> "$FILE_PATH"
        ;;
    
    *)
        # For any other events, just log them
        append_session_entry "Event: ${CLAUDE_HOOK_EVENT}" "Unhandled event type"
        ;;
esac

# Add tags for better Obsidian organization
if [[ "${CLAUDE_HOOK_EVENT}" == "session_end" ]]; then
    echo "" >> "$FILE_PATH"
    echo "---" >> "$FILE_PATH"
    echo "" >> "$FILE_PATH"
    echo "## Tags" >> "$FILE_PATH"
    echo "" >> "$FILE_PATH"
    echo "#claude #development #${PROJECT_NAME} ${JIRA_TICKET:+#${JIRA_TICKET}}" >> "$FILE_PATH"
fi

# Return success
exit 0