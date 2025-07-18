#!/bin/bash

# Claude Summary Logger Hook
# Captures Claude's response summaries from the transcript
# Triggered by the Stop hook after Claude finishes responding

set -euo pipefail

# Configuration
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

# Get the transcript path from the hook environment
TRANSCRIPT_PATH="${transcript_path:-}"

if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
    echo "Debug: No transcript path provided or file not found: $TRANSCRIPT_PATH" >&2
    exit 0
fi

# Create a Python script to extract Claude's last response
python3 << 'PYTHON_SCRIPT' > /tmp/claude_response.txt
import json
import sys
import os

transcript_path = os.environ.get('TRANSCRIPT_PATH', '')

try:
    with open(transcript_path, 'r') as f:
        data = json.load(f)
    
    # Find the last assistant message
    messages = data.get('messages', [])
    
    for msg in reversed(messages):
        if msg.get('role') == 'assistant':
            content = msg.get('content', '')
            
            # Handle different content types
            if isinstance(content, str):
                # Simple string content
                print(content.strip())
                break
            elif isinstance(content, list):
                # Content with multiple parts (text and tool calls)
                text_parts = []
                for part in content:
                    if isinstance(part, dict) and part.get('type') == 'text':
                        text_parts.append(part.get('text', ''))
                
                if text_parts:
                    # Join all text parts
                    full_text = '\n\n'.join(text_parts).strip()
                    print(full_text)
                    break
            
except Exception as e:
    print(f"Error parsing transcript: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT

# Read the extracted response
if [[ -f /tmp/claude_response.txt ]]; then
    CLAUDE_RESPONSE=$(cat /tmp/claude_response.txt)
    rm -f /tmp/claude_response.txt
else
    echo "Debug: Failed to extract Claude's response" >&2
    exit 0
fi

# If we have a response, log it
if [[ -n "$CLAUDE_RESPONSE" ]]; then
    echo "" >> "$FILE_PATH"
    echo "### [$TIMESTAMP] 🤖 Claude Summary" >> "$FILE_PATH"
    echo "" >> "$FILE_PATH"
    echo "$CLAUDE_RESPONSE" >> "$FILE_PATH"
    echo "" >> "$FILE_PATH"
    echo "---" >> "$FILE_PATH"
fi

exit 0