# Summarize Current Branch

You are analyzing the current git branch to provide comprehensive context for continuing work.

## Your Task

Perform the following analysis in parallel where possible:

1. **Branch Information**
   - Get current branch name and compare to main
   - Check if branch is ahead/behind main
   - List all commits on this branch (not in main)

2. **Code Changes Analysis**
   - Show full diff between current branch and main
   - Identify all modified files
   - Categorize changes (new features, bug fixes, refactoring, etc.)

3. **Work Context**
   - Analyze commit messages to understand the work's purpose
   - Identify any patterns or conventions being followed
   - Note any incomplete work or TODOs in the changes

4. **Current State**
   - Check for uncommitted changes
   - Check for untracked files
   - Note any merge conflicts or issues

## Output Format

Provide a concise summary with:

### Branch Overview
- Branch name and relationship to main
- Number of commits ahead/behind

### Work Summary
- High-level description of what this branch accomplishes
- Key changes made (categorized by type)

### Files Changed
- List of modified files with brief descriptions

### Next Steps
- Suggested next steps based on the current state
- Any blockers or issues to address

### Full Context
- All commit messages
- Complete diff for reference

## Implementation

Use these git commands to gather information:
```bash
# Branch info
git rev-parse --abbrev-ref HEAD
git rev-list --left-right --count main...HEAD

# Commits on this branch
git log main..HEAD --oneline
git log main..HEAD --format='%H%n%an%n%ae%n%at%n%s%n%b%n--commit-end--'

# Changes
git diff main...HEAD --stat
git diff main...HEAD

# Current state
git status --porcelain
```

Analyze all this information and provide the structured summary above.
