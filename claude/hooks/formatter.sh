#!/bin/bash
# Post-tool hook that automatically formats files after editing
# Supports Python, JavaScript, TypeScript, and other common formats

set -euo pipefail

# Read hook data from stdin
HOOK_DATA=$(cat)

# Extract working directory and tool information using jq with raw input
CWD=$(echo "$HOOK_DATA" | jq -r '.cwd // empty' 2>/dev/null || echo "")
TOOL_NAME=$(echo "$HOOK_DATA" | jq -r '.tool.name // empty' 2>/dev/null || echo "")
FILE_PATH=$(echo "$HOOK_DATA" | jq -r '.params.file_path // empty' 2>/dev/null || echo "")

# If jq parsing failed, exit gracefully
if [[ -z "$CWD" ]] || [[ -z "$TOOL_NAME" ]]; then
    exit 0
fi

# Only process Edit, MultiEdit, and Write tools
if [[ ! "$TOOL_NAME" =~ ^(Edit|MultiEdit|Write)$ ]]; then
    exit 0
fi

# Exit if no file path
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Convert absolute path to relative if needed
if [[ "$FILE_PATH" = /* ]]; then
    FILE_PATH=$(realpath --relative-to="$CWD" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
fi

# Change to working directory
cd "$CWD" || exit 0

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "  ℹ️  Not in a git repository, proceeding with formatting"
else
    # Get the base branch (default to main, fallback to master)
    BASE_BRANCH="main"
    if ! git rev-parse --verify "$BASE_BRANCH" > /dev/null 2>&1; then
        BASE_BRANCH="master"
        if ! git rev-parse --verify "$BASE_BRANCH" > /dev/null 2>&1; then
            echo "  ⚠️  Could not find main or master branch, proceeding with formatting"
        fi
    fi
    
    # Check if file has been changed on current branch compared to base
    if [[ -n "$BASE_BRANCH" ]] && git rev-parse --verify "$BASE_BRANCH" > /dev/null 2>&1; then
        # Get list of changed files
        CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || true)
        
        # Check if our file is in the list of changed files
        if [[ -n "$CHANGED_FILES" ]] && ! echo "$CHANGED_FILES" | grep -q "^${FILE_PATH}$"; then
            echo "  ℹ️  File not changed on current branch compared to $BASE_BRANCH, skipping formatting"
            exit 0
        fi
    fi
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if npx package exists
npx_exists() {
    npx --no-install "$1" --version >/dev/null 2>&1
}

# Function to run formatter
run_formatter() {
    local name=$1
    local cmd=$2
    
    echo "  → Running $name..."
    if eval "$cmd"; then
        echo "  ✓ $name completed"
    else
        echo "  ✗ $name failed"
    fi
}

echo "🔧 Formatting: $FILE_PATH"

# Determine file type and run appropriate formatters
case "$FILE_PATH" in
    *.py)
        # Python formatting
        if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
            # Try to use virtual environment if available
            if [[ -f ".venv/bin/activate" ]]; then
                source .venv/bin/activate
            elif [[ -f "venv/bin/activate" ]]; then
                source venv/bin/activate
            fi
            
            # Run Python formatters
            command_exists black && run_formatter "black" "black '$FILE_PATH'"
            command_exists isort && run_formatter "isort" "isort '$FILE_PATH'"
            command_exists autoflake && run_formatter "autoflake" "autoflake --in-place --remove-all-unused-imports --remove-unused-variables --ignore-init-module-imports '$FILE_PATH'"
        fi
        ;;
        
    *.js|*.jsx|*.ts|*.tsx|*.html|*.css|*.scss|*.less|*.json)
        # JavaScript/TypeScript formatting
        if [[ -f "package.json" ]]; then
            # Use npx to run project-local tools
            npx_exists prettier && run_formatter "prettier" "npx prettier --write '$FILE_PATH'"
            
            # ESLint only for JS/TS/HTML files
            case "$FILE_PATH" in
                *.js|*.jsx|*.ts|*.tsx|*.html)
                    npx_exists eslint && run_formatter "eslint" "npx eslint --fix '$FILE_PATH' 2>&1 | grep -v 'warning' || true"
                    ;;
            esac
        fi
        ;;
        
    *.rs)
        # Rust formatting
        if [[ -f "Cargo.toml" ]] && command_exists rustfmt; then
            run_formatter "rustfmt" "rustfmt '$FILE_PATH'"
        fi
        ;;
        
    *.go)
        # Go formatting
        if [[ -f "go.mod" ]] && command_exists gofmt; then
            run_formatter "gofmt" "gofmt -w '$FILE_PATH'"
        fi
        ;;
        
    *.rb)
        # Ruby formatting
        if [[ -f "Gemfile" ]] && command_exists rubocop; then
            run_formatter "rubocop" "rubocop -a '$FILE_PATH'"
        fi
        ;;
        
    *.java)
        # Java formatting
        if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
            if command_exists google-java-format; then
                run_formatter "google-java-format" "google-java-format -i '$FILE_PATH'"
            fi
        fi
        ;;
        
    *.sh)
        # Shell script formatting
        command_exists shfmt && run_formatter "shfmt" "shfmt -w '$FILE_PATH'"
        ;;
esac

echo "✓ Formatting complete"