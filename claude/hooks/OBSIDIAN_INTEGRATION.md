# Obsidian Integration for Claude Sessions

This integration automatically logs all Claude AI coding sessions to your Obsidian vault, creating a searchable knowledge base of your AI-assisted development work.

## Features

- **Automatic Session Logging**: Every Claude session is logged to Obsidian
- **Smart File Naming**: 
  - JIRA ticket branches: `PRO-1234.md`
  - Regular branches: `2024-01-15.md`
- **Organized Structure**: `claude-sessions/parent_dir/project_name/`
- **Rich Metadata**: Branch info, timestamps, file changes, commands
- **Daily Summaries**: Automatic daily summary generation
- **Git Integration**: Tracks git status and changes

## Setup

1. **Configure Obsidian Vault Path**
   ```bash
   # Edit the config file
   vim ~/.claude/hooks/obsidian-config.sh
   
   # Update the vault path to match your Obsidian vault
   export OBSIDIAN_VAULT="$HOME/Documents/Obsidian/YourVault"
   ```

2. **Source the Configuration**
   ```bash
   # Add to your .bashrc or .zshrc
   source ~/.claude/hooks/obsidian-config.sh
   ```

3. **Test the Integration**
   ```bash
   # Run the test function
   test_obsidian_integration
   ```

## What Gets Logged

### File Structure
```
Obsidian Vault/
└── claude-sessions/
    └── parent_directory/
        └── project_name/
            ├── PRO-1234.md      # JIRA ticket session
            ├── 2024-01-15.md    # Daily session
            └── 2024-01-15-summary.md  # Daily summary
```

### Session Contents
- **Header**: Project info, branch, JIRA ticket
- **Activity Log**: 
  - File modifications with timestamps
  - Commands executed
  - Test results
  - Git status updates
- **Metadata**: Tags, links, related files

### Example Session File
```markdown
---
type: claude-session
project: my-app
branch: PRO-1234-new-feature
ticket: PRO-1234
date: 2024-01-15
tags: [claude, ai-development, my-app, PRO-1234]
---

# Claude Session: PRO-1234

**Project**: `company/my-app`
**Branch**: `PRO-1234-new-feature`
**JIRA**: [[PRO-1234]]
**Started**: 2024-01-15 10:30:00

## Session Activity

### [10:30:15] File Modified
- **File**: `src/components/NewFeature.tsx`
- **Action**: Created

### [10:31:22] Command Executed
```bash
npm test
```

### [10:32:45] Test Results
```
✓ All tests passed (15/15)
```
```

## Configuration Options

Edit `~/.claude/hooks/obsidian-config.sh`:

```bash
# Core settings
export OBSIDIAN_VAULT="$HOME/Documents/Obsidian/Development"
export CLAUDE_BASE_DIR="claude-sessions"
export ENABLE_OBSIDIAN_LOGGING="true"

# Feature flags
export OBSIDIAN_LOG_COMMANDS="true"
export OBSIDIAN_LOG_FILE_CHANGES="true"
export OBSIDIAN_LOG_GIT_STATUS="true"
export OBSIDIAN_CREATE_DAILY_SUMMARY="true"
```

## Disabling Temporarily

To disable logging for a session:
```bash
export ENABLE_OBSIDIAN_LOGGING="false"
```

## Troubleshooting

1. **Vault not found**: Check `OBSIDIAN_VAULT` path
2. **Permission denied**: Ensure write permissions to vault
3. **No logs appearing**: Run `test_obsidian_integration`

## Benefits

- **Knowledge Base**: Build a searchable history of AI interactions
- **Project Documentation**: Automatic project activity tracking
- **JIRA Integration**: Link sessions to tickets
- **Learning Resource**: Review past sessions for patterns
- **Team Sharing**: Share session logs with team members

## Advanced Usage

### Custom Tags
Sessions automatically include tags based on:
- Project name
- JIRA ticket
- Date
- Custom tags can be added manually

### Obsidian Queries
Use Obsidian's search to find:
- All sessions for a project: `tag:#project-name`
- JIRA ticket work: `tag:#PRO-1234`
- Daily work: `tag:#2024-01-15`

### Graph View
Obsidian's graph view shows connections between:
- Sessions and JIRA tickets
- Projects and daily summaries
- Related development work