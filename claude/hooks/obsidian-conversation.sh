#!/bin/bash

# Obsidian Conversation Logger Hook
# Captures full conversation context including prompts and responses
# This is a more comprehensive version that logs the entire interaction

set -euo pipefail

# Configuration
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/Obsidian/Development}"
CLAUDE_BASE_DIR="claude-sessions"
LOG_FILE="/tmp/claude-session-${CLAUDE_SESSION_ID:-$$}.log"

# Get project information
PROJECT_PATH=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_PATH")
PARENT_DIR=$(basename "$(dirname "$PROJECT_PATH")")

# Get current git branch and extract JIRA ticket if present
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "no-git")
JIRA_TICKET=""

# Check for JIRA patterns in branch name
if [[ "$CURRENT_BRANCH" =~ (PRO|BUG|FEAT|TASK|FIX|CHORE)-[0-9]+ ]]; then
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

# Function to initialize file
init_file() {
    if [[ ! -f "$FILE_PATH" ]]; then
        cat > "$FILE_PATH" << EOF
# Claude Session: ${FILE_NAME%.md}

**Project**: \`${PARENT_DIR}/${PROJECT_NAME}\`
**Path**: \`${PROJECT_PATH}\`
**Branch**: \`${CURRENT_BRANCH}\`
${JIRA_TICKET:+**JIRA Ticket**: [[${JIRA_TICKET}]]}
**Date**: $(date "+%Y-%m-%d")

---

## Session Log

EOF
    fi
}

# Function to log conversation turn
log_conversation() {
    local timestamp=$(date "+%H:%M:%S")
    local type="$1"
    local content="$2"
    
    init_file
    
    case "$type" in
        "user")
            cat >> "$FILE_PATH" << EOF

### 🧑 User [$timestamp]

$content

EOF
            ;;
        
        "assistant")
            cat >> "$FILE_PATH" << EOF

### 🤖 Claude [$timestamp]

$content

EOF
            ;;
        
        "tool")
            local tool_name="$3"
            local tool_result="$4"
            cat >> "$FILE_PATH" << EOF

#### 🔧 Tool: $tool_name

**Input:**
\`\`\`
$content
\`\`\`

**Result:**
\`\`\`
$tool_result
\`\`\`

EOF
            ;;
        
        "error")
            cat >> "$FILE_PATH" << EOF

#### ⚠️ Error [$timestamp]

\`\`\`
$content
\`\`\`

EOF
            ;;
    esac
}

# Function to add session metadata
add_metadata() {
    local key="$1"
    local value="$2"
    
    echo "- **$key**: $value" >> "$FILE_PATH"
}

# Function to create daily summary
create_daily_summary() {
    local summary_file="${OBSIDIAN_DIR}/$(date +%Y-%m-%d)-summary.md"
    
    if [[ ! -f "$summary_file" ]]; then
        cat > "$summary_file" << EOF
# Daily Summary: $(date "+%Y-%m-%d")

**Project**: ${PARENT_DIR}/${PROJECT_NAME}

## Sessions

EOF
    fi
    
    # Add link to this session
    echo "- [[${FILE_NAME%.md}]] - ${JIRA_TICKET:-$(date "+%H:%M")} session" >> "$summary_file"
}

# Function to generate session summary
generate_summary() {
    cat >> "$FILE_PATH" << EOF

---

## Session Summary

### Key Actions
$(grep -E "^### 🔧 Tool:" "$FILE_PATH" | sed 's/### 🔧 Tool: /- /' | sort | uniq || echo "- No tools used")

### Files Modified
\`\`\`
$(git diff --name-only 2>/dev/null || echo "No git changes detected")
\`\`\`

### Git Status
\`\`\`
$(git status --short 2>/dev/null || echo "Not a git repository")
\`\`\`

### Next Steps
- [ ] Review changes
- [ ] Run tests
- [ ] Commit changes

---

## Tags

#claude #ai-development #${PROJECT_NAME} ${JIRA_TICKET:+#${JIRA_TICKET}} #$(date +%Y-%m-%d)

## Links

${JIRA_TICKET:+- JIRA: [[${JIRA_TICKET}]]}
- Project: [[${PROJECT_NAME}]]
- Daily Summary: [[$(date +%Y-%m-%d)-summary]]

EOF
}

# Main hook logic
case "${1:-log}" in
    "init")
        init_file
        ;;
    
    "user")
        log_conversation "user" "${2:-No content}"
        ;;
    
    "assistant")
        log_conversation "assistant" "${2:-No content}"
        ;;
    
    "tool")
        log_conversation "tool" "${2:-No input}" "${3:-No tool name}" "${4:-No result}"
        ;;
    
    "summary")
        generate_summary
        create_daily_summary
        ;;
    
    "log")
        # Generic logging
        init_file
        echo "${2:-Log entry}" >> "$FILE_PATH"
        ;;
    
    *)
        echo "Unknown action: $1" >&2
        exit 1
        ;;
esac

exit 0