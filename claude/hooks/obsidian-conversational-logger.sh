#!/bin/bash

# Obsidian Conversational Logger - Captures full conversation context
# This Stop hook creates truly conversational logs in Obsidian

# Debug mode - uncomment to enable
# set -x

# Source configuration
source ~/.claude/hooks/obsidian-config.sh

# Read JSON input from stdin
HOOK_INPUT=$(cat)

# Extract transcript_path from JSON input using python
CLAUDE_TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | python3 -c "
import json
import sys
try:
    data = json.loads(sys.stdin.read())
    print(data.get('transcript_path', ''))
except:
    print('')
")

# Check if transcript path was extracted
if [ -z "$CLAUDE_TRANSCRIPT_PATH" ]; then
    echo "❌ Error: Could not extract transcript_path from hook input" >&2
    echo "Received input: $HOOK_INPUT" >&2
    exit 1
fi

# Check if transcript file exists
if [ ! -f "$CLAUDE_TRANSCRIPT_PATH" ]; then
    echo "❌ Error: Transcript file not found at: $CLAUDE_TRANSCRIPT_PATH" >&2
    exit 1
fi

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
echo "" >> "$FILE_PATH"
echo "---" >> "$FILE_PATH"
echo "" >> "$FILE_PATH"
echo "## Session: $(date +"%Y-%m-%d %H:%M:%S")" >> "$FILE_PATH"
echo "" >> "$FILE_PATH"

# Python script to extract full conversation from JSONL
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

def format_tool_use(content_or_tools):
    """Format tool usage in a readable way"""
    tools = []
    
    # Extract tool uses from content array or direct tool_uses array
    if isinstance(content_or_tools, list):
        for item in content_or_tools:
            if isinstance(item, dict) and item.get('type') == 'tool_use':
                tools.append(item)
            elif isinstance(item, dict) and 'name' in item:
                # Direct tool use object
                tools.append(item)
    
    if not tools:
        return ""
    
    output = []
    for tool in tools:
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
        elif tool_name == 'LS':
            path = tool.get('input', {}).get('path', '')
            output.append(f"📁 Listed directory: `{path}`")
        else:
            output.append(f"🔧 Used {tool_name}")
    
    return '\n'.join(output)

# Read the JSONL transcript and merge messages by ID
messages_by_id = {}
with open(sys.argv[1], 'r') as f:
    for line in f:
        line = line.strip()
        if line:
            try:
                data = json.loads(line)
                # Extract the message from the data structure
                if 'message' in data and isinstance(data['message'], dict):
                    msg = data['message']
                    msg_id = msg.get('id', data.get('uuid', ''))
                    
                    # For assistant messages, merge content and tool_uses
                    if msg.get('role') == 'assistant' and msg_id and msg_id in messages_by_id:
                        existing = messages_by_id[msg_id]
                        # Merge tool_uses
                        existing_tools = existing.get('tool_uses', [])
                        new_tools = msg.get('content', [])
                        if isinstance(new_tools, list):
                            for item in new_tools:
                                if isinstance(item, dict) and item.get('type') == 'tool_use':
                                    existing_tools.append(item)
                        existing['tool_uses'] = existing_tools
                    else:
                        # Store the message
                        messages_by_id[msg_id if msg_id else data.get('uuid', '')] = msg
            except json.JSONDecodeError:
                continue

# Convert to list maintaining order
messages = list(messages_by_id.values())

# Process each message in order
for msg in messages:
    role = msg.get('role', '')
    content = msg.get('content', '')
    tool_uses = msg.get('tool_uses', [])
    
    if role == 'user':
        # User message
        text_content = format_content(content)
        if text_content.strip():
            print("### 🧑 User\n")
            print(text_content)
            print()
    
    elif role == 'assistant':
        # Assistant message
        text_content = format_content(content)
        
        # Check for tool usage in content array
        tool_output = format_tool_use(content)
        
        # Also check for separate tool_uses array
        if not tool_output and tool_uses:
            tool_output = format_tool_use(tool_uses)
        
        # Only print if there's actual content (text or tools)
        if text_content.strip() or tool_output:
            print("### 🤖 Claude\n")
            
            # First show any tool usage
            if tool_output:
                print(tool_output)
                print()
            
            # Then show the text response
            if text_content.strip():
                print(text_content)
                print()

print("\n---\n")
print(f"*Session ended at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*")
EOF

# Log that we've updated the file
echo "📝 Conversation logged to Obsidian: $FILE_PATH"