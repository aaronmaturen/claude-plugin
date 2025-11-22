# Git Revise History - Remove Claude Attributions

Iterate through git commit history to remove Claude attributions and rewrite placeholder commit messages with informative descriptions based on actual code changes.

**IMPORTANT WARNING**:
- This command uses `git rebase -i` to rewrite history
- **NEVER** use this on commits that have been pushed to shared branches
- **ALWAYS** confirm with the user before proceeding with history rewriting
- History rewriting will change commit SHAs and can cause issues for collaborators

## Steps:

### 1. **Safety Checks**
```bash
# Check if we're on a branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ -z "$CURRENT_BRANCH" ]]; then
    echo "❌ Error: Not on a branch (detached HEAD state)"
    echo "Please checkout a branch before revising history"
    exit 1
fi

# Check if on main/master
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
    echo "⚠️  WARNING: You are on the $CURRENT_BRANCH branch"
    echo "❌ Refusing to rewrite history on main/master branch"
    echo "Please create a feature branch first"
    exit 1
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo "⚠️  WARNING: You have uncommitted changes"
    echo "Please commit or stash your changes before revising history"
    git status --short
    exit 1
fi

# Check if branch has been pushed to remote
PUSHED_TO_REMOTE=$(git branch -r --contains HEAD 2>/dev/null | grep -v HEAD || echo "")
if [[ -n "$PUSHED_TO_REMOTE" ]]; then
    echo "⚠️  DANGER: This branch has been pushed to remote"
    echo "📡 Remote branches containing current HEAD:"
    echo "$PUSHED_TO_REMOTE"
    echo ""
    echo "⚠️  Rewriting history will require force-push and can cause issues for collaborators"
    echo "❌ This command is designed for local-only branches"
    echo ""
    echo "If you absolutely need to proceed (and no one else is using this branch),"
    echo "please confirm you understand the risks."
    # Let the user decide whether to continue
    # The AskUserQuestion should be handled by Claude in the conversation
fi

echo "✓ Safety checks passed"
echo "📍 Current branch: $CURRENT_BRANCH"
echo ""
```

### 2. **Prompt User for Revision Scope**

Ask the user how they want to scope the history revision using the AskUserQuestion tool:

**Question:** "How would you like to scope the commit history revision?"

**Options:**
1. **Current branch commits** - Revise all commits on this branch since it diverged from main/master
   - Description: "Revises commits from where your branch diverged from the base branch (main/master)"
   - Use case: Most common - clean up an entire feature branch

2. **Specific commit** - Start from a specific commit hash or reference
   - Description: "Revises commits starting from a specific commit you provide (e.g., abc1234, HEAD~5)"
   - Use case: Only want to revise recent commits or a specific range

3. **Interactive selection** - Show recent commits and let user choose the starting point
   - Description: "Shows the last 20 commits and lets you pick where to start"
   - Use case: Want to see commit history before deciding

### 3. **Determine Revision Range**

Based on user selection:

#### Option 1: Current Branch Commits
```bash
# Find the merge base with main or master
BASE_BRANCH="main"
if ! git show-ref --verify --quiet refs/heads/main; then
    if git show-ref --verify --quiet refs/heads/master; then
        BASE_BRANCH="master"
    else
        echo "❌ Error: Neither 'main' nor 'master' branch found"
        echo "Please specify a base branch manually"
        exit 1
    fi
fi

MERGE_BASE=$(git merge-base HEAD $BASE_BRANCH)
REVISION_START="$MERGE_BASE"

echo "📊 Branch diverged from $BASE_BRANCH at: $MERGE_BASE"
echo ""
echo "Commits to be revised:"
git log --oneline "$MERGE_BASE..HEAD"
echo ""
COMMIT_COUNT=$(git rev-list --count "$MERGE_BASE..HEAD")
echo "📝 Total commits to revise: $COMMIT_COUNT"
```

#### Option 2: Specific Commit
```bash
# User should provide the commit reference
echo "Please provide the commit reference to start from:"
echo "Examples: abc1234, HEAD~5, v1.0.0"
echo ""
# Read user input via AskUserQuestion
# REVISION_START will be set to user-provided commit

# Validate the commit exists
if ! git rev-parse --verify "$REVISION_START" >/dev/null 2>&1; then
    echo "❌ Error: Commit '$REVISION_START' not found"
    exit 1
fi

echo "📊 Starting revision from: $REVISION_START"
echo ""
echo "Commits to be revised:"
git log --oneline "$REVISION_START..HEAD"
echo ""
COMMIT_COUNT=$(git rev-list --count "$REVISION_START..HEAD")
echo "📝 Total commits to revise: $COMMIT_COUNT"
```

#### Option 3: Interactive Selection
```bash
# Show last 20 commits with numbers
echo "Recent commit history:"
echo ""
git log --oneline -20 --decorate

echo ""
echo "Please specify:"
echo "- A commit hash (e.g., abc1234)"
echo "- A relative reference (e.g., HEAD~5 for 5 commits back)"
echo "- A tag or branch name"
echo ""
# User provides selection via AskUserQuestion
# Validate and set REVISION_START
```

### 4. **Analyze Commits for Claude Attributions**

```bash
# Scan commits for Claude attributions and placeholder messages
echo "🔍 Analyzing commits for Claude attributions and placeholder messages..."
echo ""

COMMITS_WITH_CLAUDE=0
COMMITS_WITH_PLACEHOLDERS=0

# Analyze each commit
git log --format="%H|||%s|||%b" "$REVISION_START..HEAD" | while IFS='|||' read -r hash subject body; do
    HAS_CLAUDE=false
    IS_PLACEHOLDER=false

    # Check for Claude attributions in commit message
    if echo "$body" | grep -qi "co-authored-by: claude"; then
        HAS_CLAUDE=true
        ((COMMITS_WITH_CLAUDE++))
    fi

    if echo "$body" | grep -qi "Generated with.*Claude Code"; then
        HAS_CLAUDE=true
        ((COMMITS_WITH_CLAUDE++))
    fi

    if echo "$body" | grep -qi "🤖.*Claude"; then
        HAS_CLAUDE=true
        ((COMMITS_WITH_CLAUDE++))
    fi

    # Check for placeholder messages
    if echo "$subject" | grep -qiE "(wip|placeholder|temp|temporary|fixup|test commit|update|fix)$"; then
        IS_PLACEHOLDER=true
        ((COMMITS_WITH_PLACEHOLDERS++))
    fi

    # Show commits that need revision
    if [[ "$HAS_CLAUDE" == true ]] || [[ "$IS_PLACEHOLDER" == true ]]; then
        echo "📝 ${hash:0:7}: $subject"
        if [[ "$HAS_CLAUDE" == true ]]; then
            echo "   ↳ Contains Claude attribution"
        fi
        if [[ "$IS_PLACEHOLDER" == true ]]; then
            echo "   ↳ Appears to be placeholder message"
        fi
        echo ""
    fi
done

echo "Summary:"
echo "- Commits with Claude attributions: $COMMITS_WITH_CLAUDE"
echo "- Commits with placeholder messages: $COMMITS_WITH_PLACEHOLDERS"
echo ""
```

### 5. **Confirm Before Proceeding**

Use AskUserQuestion to confirm:
- Show the user the summary of what will be changed
- Clearly explain that commit SHAs will change
- Warn about force-push requirements if already pushed
- Ask for explicit confirmation to proceed

### 6. **Perform Interactive Rebase**

**CRITICAL**: This command DOES NOT actually run `git rebase -i` automatically because:
1. Interactive rebase requires manual editor interaction
2. We need to guide the user through the process
3. Each commit may need different handling

Instead, provide the user with:

```bash
echo "📋 To revise the commits, you'll need to run an interactive rebase:"
echo ""
echo "Run this command:"
echo "  git rebase -i $REVISION_START"
echo ""
echo "⚙️  I'll help you process each commit during the rebase."
echo ""
echo "In the rebase editor that opens:"
echo "1. For commits with Claude attributions: change 'pick' to 'reword'"
echo "2. For commits with placeholder messages: change 'pick' to 'reword'"
echo "3. For commits that are fine as-is: leave as 'pick'"
echo "4. Save and close the editor"
echo ""
echo "After you start the rebase, I'll help you write proper commit messages"
echo "for each commit marked as 'reword'."
echo ""
```

**Alternative Automated Approach** (if user prefers):

For automated processing, use a script-based approach:

```bash
# Create a custom git filter to clean commit messages
echo "🔄 Creating automated revision process..."

# Set up git filter-branch or use git-filter-repo if available
if command -v git-filter-repo >/dev/null 2>&1; then
    echo "✓ Using git-filter-repo for safe history rewriting"

    # Create message filter script
    cat > /tmp/claude-filter.py << 'FILTER_SCRIPT'
#!/usr/bin/env python3
import sys
import re

message = sys.stdin.read()

# Remove Claude attributions
message = re.sub(r'\n*🤖[^\n]*Claude[^\n]*\n*', '\n', message, flags=re.IGNORECASE)
message = re.sub(r'\n*Co-Authored-By:\s*Claude\s*<[^>]*>\n*', '\n', message, flags=re.IGNORECASE)
message = re.sub(r'\n*Generated with.*Claude Code.*\n*', '\n', message, flags=re.IGNORECASE)

# Clean up extra newlines
message = re.sub(r'\n{3,}', '\n\n', message)
message = message.strip()

sys.stdout.write(message)
FILTER_SCRIPT

    chmod +x /tmp/claude-filter.py

    # Run git-filter-repo with message filter
    git-filter-repo --force \
        --commit-callback "$(cat << 'CALLBACK'
# Python callback to clean messages
commit.message = subprocess.check_output(
    ['/tmp/claude-filter.py'],
    input=commit.message,
    text=True
).encode()
CALLBACK
)" \
        --refs HEAD \
        "$REVISION_START..HEAD"
else
    echo "⚠️  git-filter-repo not found, using interactive rebase instead"
    echo "Install with: pip install git-filter-repo"
    echo ""
    # Fall back to interactive guidance
fi
```

### 7. **Process Each Commit During Rebase**

When the rebase pauses for each 'reword' commit:

```bash
# This happens during the rebase when git pauses for reword
# Claude should help with this interactively

# Get the current commit being reworded
CURRENT_COMMIT=$(git rev-parse HEAD)

echo "✏️  Rewriting commit: $(git log -1 --oneline)"
echo ""

# Show the changes in this commit
echo "📊 Changes in this commit:"
git show --stat --format="" HEAD
echo ""

# Get the current message
CURRENT_MSG=$(git log -1 --format=%B HEAD)

echo "Current message:"
echo "---"
echo "$CURRENT_MSG"
echo "---"
echo ""

# Check what needs to be cleaned
HAS_CLAUDE_ATTR=false
if echo "$CURRENT_MSG" | grep -qi "co-authored-by: claude\|generated with.*claude\|🤖.*claude"; then
    HAS_CLAUDE_ATTR=true
fi

IS_PLACEHOLDER=false
if echo "$CURRENT_MSG" | grep -qiE "^(wip|placeholder|temp|update|fix)"; then
    IS_PLACEHOLDER=true
fi

# Generate new message
if [[ "$HAS_CLAUDE_ATTR" == true ]] || [[ "$IS_PLACEHOLDER" == true ]]; then
    echo "Generating improved commit message based on changes..."

    # Analyze the diff to write a proper message
    # Extract file changes
    FILES_CHANGED=$(git show --name-only --format="" HEAD)
    DIFF_STAT=$(git show --stat HEAD)

    echo ""
    echo "📝 Based on the changes, here's a suggested commit message:"
    echo ""

    # Claude should analyze the changes and generate an appropriate message
    # following conventional commit format if there's a JIRA ticket in branch

    # Extract ticket from branch name
    BRANCH=$(git branch --show-current)
    TICKET=$(echo "$BRANCH" | grep -oE "(PRO|BUG)-[0-9]+" | head -1)

    # Generate message based on changes
    # This is where Claude would analyze the diff and write a proper message

    echo "Suggested format:"
    if [[ -n "$TICKET" ]]; then
        echo "[$TICKET] <concise description of what changed>"
    else
        echo "<concise description of what changed>"
    fi
    echo ""
    echo "<detailed explanation of why and any important context>"
    echo ""

    # Let user edit or confirm the message
fi
```

### 8. **Handle Placeholder Messages Specifically**

For commits identified as placeholders:

```bash
# Analyze the actual changes to generate a meaningful message
analyze_commit_changes() {
    local commit_hash=$1

    # Get file changes
    local files=$(git show --name-only --format="" "$commit_hash")
    local stats=$(git show --stat --format="" "$commit_hash")
    local diff=$(git show --format="" "$commit_hash")

    echo "Files modified:"
    echo "$files"
    echo ""
    echo "Statistics:"
    echo "$stats"
    echo ""

    # Suggest message components based on changes
    # - If new files: "Add <feature>"
    # - If deleted files: "Remove <feature>"
    # - If modified existing: "Update <feature>" or "Fix <issue>"
    # - If tests added: "Add tests for <feature>"
    # - If docs changed: "Update documentation for <feature>"

    # Claude should analyze the diff intelligently here
}
```

### 9. **Completion and Summary**

```bash
echo "✅ History revision complete!"
echo ""
echo "📊 Summary of changes:"
git log --oneline "$REVISION_START..HEAD"
echo ""

# Check if history diverged from remote
if git branch -r --contains "$REVISION_START" >/dev/null 2>&1; then
    echo "⚠️  IMPORTANT: This branch has been pushed to remote"
    echo ""
    echo "To update the remote branch, you'll need to force push:"
    echo "  git push --force-with-lease origin $CURRENT_BRANCH"
    echo ""
    echo "⚠️  Only do this if:"
    echo "   - No one else is working on this branch"
    echo "   - You've coordinated with your team"
    echo "   - You understand the implications of rewriting public history"
    echo ""
else
    echo "✓ This is a local-only branch, safe to continue working"
fi

echo ""
echo "All Claude attributions have been removed and placeholder messages rewritten!"
```

## Guidelines:

### What to Remove:
- `Co-Authored-By: Claude <noreply@anthropic.com>`
- `🤖 Generated with [Claude Code](https://claude.com/claude-code)`
- Any other Claude/AI attribution footers or signatures
- Emoji-based attributions (🤖, 🔧, etc. when clearly AI-generated)

### What to Preserve:
- Actual co-author attributions for human collaborators
- JIRA ticket references (e.g., `[PRO-1234]`)
- Meaningful commit message content
- Conventional commit format prefixes (feat:, fix:, etc.)

### Placeholder Message Detection:
Identify commits as placeholders if subject line is:
- "wip", "WIP", "work in progress"
- "temp", "temporary"
- "fixup", "squash"
- "test commit"
- Just "update" or "fix" with no context
- Very generic like "changes", "updates", "modifications"

### Rewriting Placeholder Messages:
1. Analyze the actual code changes (diff)
2. Identify what was changed (files, functions, features)
3. Determine the type of change (add, update, fix, refactor, etc.)
4. Extract JIRA ticket from branch name if present
5. Write a proper commit message:
   - Subject: Clear, concise description (50 chars max)
   - Body: Explain what and why (not how)
   - Include ticket reference if found
   - Use present tense
   - Be specific about what changed

### Example Transformations:

**Before:**
```
wip

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**After (analyzing changes shows new user validation):**
```
[PRO-1234] Add user input validation to registration form

Implemented email and password validation with error
messages to prevent invalid user data from being submitted.
```

**Before:**
```
update

some changes to the api
```

**After (analyzing changes shows endpoint addition):**
```
[BUG-567] Add retry logic to payment API endpoint

Added exponential backoff retry mechanism to handle
transient network failures during payment processing.
```

## Safety Features:

1. **Pre-flight checks**:
   - Refuse to run on main/master
   - Check for uncommitted changes
   - Warn about pushed commits
   - Validate all git references

2. **User confirmation**:
   - Show exactly what will be changed
   - Explain consequences clearly
   - Require explicit approval
   - Offer to abort at any time

3. **Backup recommendations**:
   - Suggest creating a backup branch first
   - Recommend: `git branch backup-$(date +%Y%m%d) before proceeding`

4. **Recovery information**:
   - Show original commit SHAs before changes
   - Explain how to use reflog if needed
   - Provide `git reset --hard ORIG_HEAD` escape hatch

## Example Usage:

```
Command: /git-revise-history

Output:
✓ Safety checks passed
📍 Current branch: feature/user-profile-updates

How would you like to scope the commit history revision?
1. Current branch commits (5 commits since diverging from main)
2. Specific commit (provide a commit hash or reference)
3. Interactive selection (see recent commits first)

[User selects: 1 - Current branch commits]

📊 Branch diverged from main at: a1b2c3d
Commits to be revised:
e5f6g7h Update user profile
d4e5f6g wip
c3d4e5f Fix validation bug
b2c3d4e Add new fields
a1b2c3d Initial profile work

📝 Total commits to revise: 5

🔍 Analyzing commits for Claude attributions and placeholder messages...

📝 d4e5f6g: wip
   ↳ Contains Claude attribution
   ↳ Appears to be placeholder message

📝 a1b2c3d: Initial profile work
   ↳ Contains Claude attribution

Summary:
- Commits with Claude attributions: 2
- Commits with placeholder messages: 1

⚠️  This will rewrite 5 commits and change their SHAs
✓ This is a local-only branch (not pushed to remote)

Do you want to proceed with history revision? [y/N]

[User confirms: y]

🔄 Starting interactive rebase process...

Run this command:
  git rebase -i a1b2c3d

I'll help you rewrite each commit message as we go.
```

## Notes:
- Uses interactive rebase for safety and control
- Analyzes actual code changes to write meaningful messages
- Preserves JIRA ticket references and conventional commit format
- Removes all Claude attributions cleanly
- Provides clear guidance throughout the process
- Includes multiple safety checks and confirmations
- Offers both manual and automated approaches
- Generates contextual commit messages from diffs
