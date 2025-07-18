#!/bin/bash

# Obsidian Conversational Logger - Captures full conversation context
# This Stop hook creates truly conversational logs in Obsidian

# Source configuration
source ~/.claude/hooks/obsidian-config.sh

# Get environment info
PROJECT_NAME=$(basename "$PWD")
PARENT_DIR=$(basename "$(dirname "$PWD")")
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
JIRA_TICKET=$(echo "$GIT_BRANCH" | grep -oE '^[A-Z]+-[0-9]+' || echo "")

# Determine vault directory and file name
VAULT_DIR="$OBSIDIAN_VAULT/claude-sessions/$PARENT_DIR/$PROJECT_NAME"
if [ -n "$JIRA_TICKET" ]; then
    FILE_NAME="${JIRA_TICKET}.md"
else
    FILE_NAME="$(date +%Y-%m-%d).md"
fi
FILE_PATH="$VAULT_DIR/$FILE_NAME"

# Create directory if it doesn't exist
mkdir -p "$VAULT_DIR"

# Create/update file header if new file
if [ ! -f "$FILE_PATH" ]; then
    cat > "$FILE_PATH" << EOF
---
project: $PROJECT_NAME
parent: $PARENT_DIR
branch: $GIT_BRANCH
jira: $JIRA_TICKET
created: $(date +"%Y-%m-%d %H:%M:%S")
---

# Claude Sessions - $PROJECT_NAME

EOF
fi

# Add conversation separator
echo -e "\n---\n" >> "$FILE_PATH"
echo "## Session: $(date +"%Y-%m-%d %H:%M:%S")" >> "$FILE_PATH"
echo -e "\n" >> "$FILE_PATH"

# Python script to extract full conversation
python3 - "$CLAUDE_TRANSCRIPT_PATH" >> "$FILE_PATH" << 'EOF'
import json
import sys
import os
from datetime import datetime

def format_content(content):
    """Extract text content from various content formats"""
    if isinstance(content, str):
        return content
    elif isinstance(content, list):
        text_parts = []
        for item in content:
            if isinstance(item, dict) and item.get('type') == 'text':
                text_parts.append(item.get('text', ''))
        return '\n'.join(text_parts)
    return str(content)

def format_tool_use(tool_uses):
    """Format tool usage in a readable way"""
    if not tool_uses:
        return ""
    
    output = []
    for tool in tool_uses:
        tool_name = tool.get('name', 'Unknown')
        
        # Special handling for different tools
        if tool_name == 'Edit':
            file_path = tool.get('input', {}).get('file_path', 'unknown file')
            output.append(f"📝 Edited `{file_path}`")
        elif tool_name == 'Write':
            file_path = tool.get('input', {}).get('file_path', 'unknown file')
            output.append(f"📄 Created `{file_path}`")
        elif tool_name == 'Read':
            file_path = tool.get('input', {}).get('file_path', 'unknown file')
            output.append(f"👁️ Read `{file_path}`")
        elif tool_name == 'Bash':
            command = tool.get('input', {}).get('command', 'unknown command')
            # Truncate long commands
            if len(command) > 80:
                command = command[:77] + "..."
            output.append(f"💻 Ran: `{command}`")
        elif tool_name == 'Task':
            description = tool.get('input', {}).get('description', 'Task')
            output.append(f"🔍 Launched agent: {description}")
        elif tool_name == 'Grep':
            pattern = tool.get('input', {}).get('pattern', '')
            output.append(f"🔎 Searched for: `{pattern}`")
        elif tool_name == 'TodoWrite':
            output.append(f"✅ Updated todo list")
        else:
            output.append(f"🔧 Used {tool_name}")
    
    return '\n'.join(output)

# Read the transcript
with open(sys.argv[1], 'r') as f:
    data = json.load(f)

messages = data.get('messages', [])

# Process each message in order
for msg in messages:
    role = msg.get('role', '')
    content = msg.get('content', '')
    tool_uses = msg.get('tool_uses', [])
    
    if role == 'user':
        # User message
        print("### 🧑 User\n")
        print(format_content(content))
        print()
    
    elif role == 'assistant':
        # Assistant message
        print("### 🤖 Claude\n")
        
        # First show any tool usage
        if tool_uses:
            tool_output = format_tool_use(tool_uses)
            if tool_output:
                print(tool_output)
                print()
        
        # Then show the text response
        text_content = format_content(content)
        if text_content.strip():
            print(text_content)
            print()

print("\n---\n")
print(f"*Session ended at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*")
EOF

# Log that we've updated the file
echo "📝 Conversation logged to Obsidian: $FILE_PATH"