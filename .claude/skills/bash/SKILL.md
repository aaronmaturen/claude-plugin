---
name: bash
description: This skill should be used when the user asks to 'write a bash script', 'create a shell command', 'work with bash', or 'debug shell commands'. Provides bash patterns and best practices specific to this plugin's command system.
version: 1.0.0
metadata:
  internal: false
---

# Bash

Bash patterns for ATM command development, focusing on command availability checks, clipboard integration, and report generation.

## Capabilities

- **Command Availability Checks**: Verify external CLIs before use (`gh`, `jira`, `git`)
- **Clipboard Integration**: macOS/Linux clipboard handling
- **Report Generation**: Structured output to `~/Documents/technical-analysis/`
- **Branch Detection**: Extract JIRA tickets from branch names
- **Git Operations**: Staged changes, diffs, history manipulation

## Command Availability Pattern

Always check for external tools before use:

```bash
# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is required but not installed."
    echo "Install: brew install gh"
    exit 1
fi

# Check authentication status
if ! gh auth status &> /dev/null; then
    echo "Error: GitHub CLI not authenticated."
    echo "Run: gh auth login"
    exit 1
fi
```

**Common tools to check:**
- `gh` - GitHub CLI
- `jira` - JIRA CLI
- `git` - Version control
- `pbcopy` / `xclip` - Clipboard tools

## Clipboard Integration

Cross-platform clipboard handling:

```bash
# macOS (primary target)
echo "content" | pbcopy

# Linux fallback
if command -v xclip &> /dev/null; then
    echo "content" | xclip -selection clipboard
elif command -v xsel &> /dev/null; then
    echo "content" | xsel --clipboard --input
else
    echo "Warning: No clipboard tool found (install xclip or xsel)"
fi
```

## Report Generation

Standardized report output:

```bash
# Use environment variable with fallback
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"

# Create directory structure
REPORT_DIR="$REPORT_BASE/audits"
mkdir -p "$REPORT_DIR"

# Generate timestamped filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORT_DIR/angular-style-audit_${TIMESTAMP}.md"

# Write report
cat > "$REPORT_FILE" <<EOF
# Angular Style Audit

Date: $(date +%Y-%m-%d)

## Findings
...
EOF

echo "Report saved: $REPORT_FILE"
```

## JIRA Ticket Extraction

Extract ticket IDs from branch names:

```bash
# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Extract JIRA ticket (e.g., PRO-1234, BUG-567)
TICKET=$(echo "$BRANCH" | grep -oE '[A-Z]+-[0-9]+' | head -1)

if [ -z "$TICKET" ]; then
    echo "No JIRA ticket found in branch name"
    read -p "Enter ticket ID manually (or press enter to skip): " TICKET
fi
```

## Git Staged Changes

Analyze staged changes for commit messages:

```bash
# Get staged diff
STAGED_DIFF=$(git diff --cached)

if [ -z "$STAGED_DIFF" ]; then
    echo "No staged changes found."
    echo "Run: git add <files>"
    exit 1
fi

# Get staged file list
STAGED_FILES=$(git diff --cached --name-only)

# Get diff with context
git diff --cached --unified=3
```

## Branch Mode Detection

Support `--branch` or `-b` flags for auditing only changed files:

```bash
# Parse arguments
BRANCH_MODE=false
for arg in "$@"; do
    if [[ "$arg" == "--branch" ]] || [[ "$arg" == "-b" ]]; then
        BRANCH_MODE=true
    fi
done

# Get files to audit
if [ "$BRANCH_MODE" = true ]; then
    # Only changed files
    FILES=$(git diff --name-only main...HEAD | grep '\.ts$')
else
    # All files
    FILES=$(find src -name '*.ts')
fi
```

## Error Handling

Graceful failures with informative messages:

```bash
# Exit on undefined variables
set -u

# Function with error handling
fetch_pr_details() {
    local pr_number=$1
    
    if ! PR_DATA=$(gh pr view "$pr_number" --json title,body,headRefName 2>&1); then
        echo "Error: Failed to fetch PR #$pr_number"
        echo "$PR_DATA"
        return 1
    fi
    
    echo "$PR_DATA"
}
```

## Multi-Repository Pattern

Support for related repositories:

```bash
# Check for frontend repo
EDU_CLIENTS_PATH="${EDU_CLIENTS_PATH:-../edu-clients}"

if [ -d "$EDU_CLIENTS_PATH/.git" ]; then
    echo "Found frontend repo at $EDU_CLIENTS_PATH"
    # Search both repos
    grep -r "pattern" src/ "$EDU_CLIENTS_PATH/src/"
else
    echo "Frontend repo not found (searched: $EDU_CLIENTS_PATH)"
    echo "Set EDU_CLIENTS_PATH to override"
fi
```

## Best Practices

1. **Always check command availability** before use
2. **Use environment variables with defaults** for paths (`REPORT_BASE`, `EDU_CLIENTS_PATH`)
3. **Provide install instructions** in error messages
4. **Support both macOS and Linux** where possible (clipboard, paths)
5. **Create directories before writing** (`mkdir -p`)
6. **Use timestamps** for report filenames to avoid collisions
7. **Quote variables** to handle spaces: `"$VAR"` not `$VAR`

## Common Pitfalls

- **Unquoted variables**: `cd $PATH` breaks with spaces → `cd "$PATH"`
- **Missing availability checks**: Assume `gh` exists → check with `command -v`
- **Hardcoded paths**: `/Users/aaron/...` → use `$HOME` or env vars
- **Silent failures**: `gh pr view` fails silently → capture stderr and check exit code
- **macOS-only clipboard**: `pbcopy` fails on Linux → provide fallback

## Limitations

- **Clipboard integration** requires `pbcopy` (macOS) or `xclip`/`xsel` (Linux)
- **JIRA CLI** authentication must be configured (`jira init`)
- **GitHub CLI** authentication must be configured (`gh auth login`)
- **Report generation** assumes `~/Documents/technical-analysis/` is writable
- **Branch name parsing** assumes format like `feature/PRO-1234-description`

## References

- [GitHub CLI Manual](https://cli.github.com/manual/)
- [JIRA CLI](https://github.com/ankitpokhrel/jira-cli)
- [Bash Best Practices](https://google.github.io/styleguide/shellguide.html)