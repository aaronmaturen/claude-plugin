---
description: Install atm rules to your global Claude configuration
---

# Setup Rules Command

This command helps you install the atm rules into your global Claude configuration.

## Instructions

You are helping the user install the atm rule modules into their global Claude configuration directory.

### Steps:

1. **Check for existing CLAUDE.md**
   - Check if `~/.claude/CLAUDE.md` exists
   - If it exists, ask the user if they want to backup their current configuration before proceeding

2. **Create rules directory**
   - Create `~/.claude/rules/` directory if it doesn't exist

3. **Copy rule modules**
   - Copy all rule files from `${CLAUDE_PLUGIN_ROOT}/claude/rules/` to `~/.claude/rules/`
   - The rule files are:
     - `01-general-instructions.md`
     - `02-git-workflow.md`
     - `03-available-tools.md`
     - `04-project-specific.md`
     - `05-debugging-methodology.md`

4. **Update or create CLAUDE.md**
   - If `~/.claude/CLAUDE.md` exists, suggest adding references to the new rules
   - If it doesn't exist, copy `${CLAUDE_PLUGIN_ROOT}/claude/CLAUDE.md` to `~/.claude/CLAUDE.md`

5. **Confirm installation**
   - List the files that were installed
   - Explain that these rules will now be active in all Claude sessions

### Important Notes

- These rules provide workflow guidelines, git best practices, and project-specific conventions
- Users can customize the rules by editing the files in `~/.claude/rules/`
- The rules are modular and can be enabled/disabled by editing `~/.claude/CLAUDE.md`
