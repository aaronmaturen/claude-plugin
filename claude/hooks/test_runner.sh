#!/bin/bash
# Post-tool hook that runs tests and verifies coverage after editing files
# Only runs tests relevant to the modified files

set -euo pipefail

# Read hook data from stdin
HOOK_DATA=$(cat)

# Extract working directory and tool information using jq with error handling
CWD=$(echo "$HOOK_DATA" | jq -r '.cwd // empty' 2>/dev/null || echo "")
TOOL_NAME=$(echo "$HOOK_DATA" | jq -r '.tool.name // empty' 2>/dev/null || echo "")
FILE_PATH=$(echo "$HOOK_DATA" | jq -r '.params.file_path // empty' 2>/dev/null || echo "")

# If jq parsing failed, exit gracefully
if [[ -z "$CWD" ]] || [[ -z "$TOOL_NAME" ]]; then
    exit 0
fi

# Handle MultiEdit tool differently
if [[ "$TOOL_NAME" == "MultiEdit" ]]; then
    FILE_PATH=$(echo "$HOOK_DATA" | jq -r '.params.file_path // empty' 2>/dev/null || echo "")
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

# Check if this is a test file
if [[ "$FILE_PATH" =~ (test|spec|tests).*\.(py|js|jsx|ts|tsx|rs|go|rb|java)$ ]] || 
   [[ "$FILE_PATH" =~ .*\.(test|spec)\.(js|jsx|ts|tsx)$ ]] ||
   [[ "$FILE_PATH" =~ .*_test\.(go|py)$ ]] ||
   [[ "$FILE_PATH" =~ .*/tests?/.*$ ]]; then
    echo "  ℹ️  Test file edited, skipping test execution"
    exit 0
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "  ℹ️  Not in a git repository, proceeding with tests"
else
    # Get the base branch (default to main, fallback to master)
    BASE_BRANCH="main"
    if ! git rev-parse --verify "$BASE_BRANCH" > /dev/null 2>&1; then
        BASE_BRANCH="master"
        if ! git rev-parse --verify "$BASE_BRANCH" > /dev/null 2>&1; then
            echo "  ⚠️  Could not find main or master branch, proceeding with tests"
        fi
    fi
    
    # Check if file has been changed on current branch compared to base
    if [[ -n "$BASE_BRANCH" ]] && git rev-parse --verify "$BASE_BRANCH" > /dev/null 2>&1; then
        # Get list of changed files
        CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || true)
        
        # Check if our file is in the list of changed files
        if [[ -n "$CHANGED_FILES" ]] && ! echo "$CHANGED_FILES" | grep -q "^${FILE_PATH}$"; then
            echo "  ℹ️  File not changed on current branch compared to $BASE_BRANCH, skipping tests"
            exit 0
        fi
    fi
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run tests
run_tests() {
    local name=$1
    local cmd=$2
    
    echo "  → Running $name..."
    if eval "$cmd"; then
        echo "  ✓ $name passed"
        return 0
    else
        echo "  ✗ $name failed"
        return 1
    fi
}

echo "🧪 Running tests for: $FILE_PATH"

# Determine file type and run appropriate tests
case "$FILE_PATH" in
    *.py)
        # Python testing
        if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
            # Try to use virtual environment if available
            if [[ -f ".venv/bin/activate" ]]; then
                source .venv/bin/activate
            elif [[ -f "venv/bin/activate" ]]; then
                source venv/bin/activate
            fi
            
            # Extract module/app name from file path
            # For Django apps, get the app name
            APP_NAME=""
            if [[ "$FILE_PATH" =~ ^([^/]+)/.*\.py$ ]]; then
                APP_NAME="${BASH_REMATCH[1]}"
            fi
            
            
            # Check if it's a Django project
            if [[ -f "manage.py" ]] && [[ -n "$APP_NAME" ]]; then
                # Django-specific testing
                echo "  ℹ️  Django app detected: $APP_NAME"
                
                # Run tests for the specific app
                if [[ -d "$APP_NAME/tests" ]] || [[ -f "$APP_NAME/tests.py" ]]; then
                    run_tests "Django tests for $APP_NAME" "python manage.py test $APP_NAME --parallel --keepdb 2>&1 | tail -20"
                    
                    # Run coverage if available
                    if command_exists coverage; then
                        echo "  → Checking test coverage..."
                        coverage run --source="$APP_NAME" manage.py test "$APP_NAME" --parallel --keepdb >/dev/null 2>&1
                        echo "  📊 Coverage report for $APP_NAME:"
                        coverage report -m --include="$APP_NAME/*" --skip-covered | grep -E "(TOTAL|$FILE_PATH)" || true
                    fi
                fi
                
            # Check if it's a pytest project
            elif command_exists pytest && [[ -f "pytest.ini" || -f "setup.cfg" || -f "pyproject.toml" ]]; then
                # Pytest-specific testing
                echo "  ℹ️  Pytest project detected"
                
                # Find test file for the modified file
                TEST_FILE=""
                BASE_NAME=$(basename "$FILE_PATH" .py)
                DIR_NAME=$(dirname "$FILE_PATH")
                
                # Look for corresponding test file
                if [[ -f "${DIR_NAME}/test_${BASE_NAME}.py" ]]; then
                    TEST_FILE="${DIR_NAME}/test_${BASE_NAME}.py"
                elif [[ -f "${DIR_NAME}/tests/test_${BASE_NAME}.py" ]]; then
                    TEST_FILE="${DIR_NAME}/tests/test_${BASE_NAME}.py"
                elif [[ -f "tests/${DIR_NAME}/test_${BASE_NAME}.py" ]]; then
                    TEST_FILE="tests/${DIR_NAME}/test_${BASE_NAME}.py"
                fi
                
                if [[ -n "$TEST_FILE" ]] && [[ -f "$TEST_FILE" ]]; then
                    run_tests "pytest for $TEST_FILE" "pytest -xvs '$TEST_FILE' 2>&1 | tail -20"
                    
                    # Run coverage if available
                    if command_exists coverage; then
                        echo "  → Checking test coverage..."
                        coverage run -m pytest "$TEST_FILE" >/dev/null 2>&1
                        echo "  📊 Coverage report:"
                        coverage report -m --include="$FILE_PATH" | tail -5
                    fi
                else
                    echo "  ⚠️  No test file found for $FILE_PATH"
                fi
                
            # Generic Python unittest
            elif command_exists python; then
                echo "  ℹ️  Using generic Python testing"
                MODULE_PATH=$(echo "$FILE_PATH" | sed 's/\.py$//' | sed 's/\//./g')
                
                # Try to find and run tests
                if python -m unittest discover -s . -p "*test*.py" -k "$MODULE_PATH" >/dev/null 2>&1; then
                    run_tests "unittest" "python -m unittest discover -s . -p '*test*.py' -k '$MODULE_PATH' -v 2>&1 | tail -20"
                fi
            fi
        fi
        ;;
        
    *.js|*.jsx|*.ts|*.tsx)
        # JavaScript/TypeScript testing
        if [[ -f "package.json" ]]; then
            # Check for test scripts in package.json
            if grep -q '"test"' package.json; then
                # Find test file for the modified file
                BASE_NAME=$(basename "$FILE_PATH" | sed -E 's/\.(js|jsx|ts|tsx)$//')
                DIR_NAME=$(dirname "$FILE_PATH")
                
                # Common test file patterns
                TEST_PATTERNS=(
                    "${DIR_NAME}/__tests__/${BASE_NAME}.test.*"
                    "${DIR_NAME}/__tests__/${BASE_NAME}.spec.*"
                    "${DIR_NAME}/${BASE_NAME}.test.*"
                    "${DIR_NAME}/${BASE_NAME}.spec.*"
                    "test/${DIR_NAME}/${BASE_NAME}.test.*"
                    "test/${DIR_NAME}/${BASE_NAME}.spec.*"
                )
                
                TEST_FILE=""
                for pattern in "${TEST_PATTERNS[@]}"; do
                    for file in $pattern; do
                        if [[ -f "$file" ]]; then
                            TEST_FILE="$file"
                            break 2
                        fi
                    done
                done
                
                if [[ -n "$TEST_FILE" ]]; then
                    # Run jest if available
                    if grep -q "jest" package.json; then
                        run_tests "jest for $TEST_FILE" "npm test -- '$TEST_FILE' --coverage --coverageReporters=text-summary 2>&1 | tail -20"
                    else
                        run_tests "npm test" "npm test 2>&1 | tail -20"
                    fi
                else
                    echo "  ⚠️  No test file found for $FILE_PATH"
                fi
            fi
        fi
        ;;
        
    *.rs)
        # Rust testing
        if [[ -f "Cargo.toml" ]] && command_exists cargo; then
            # Extract module path from file
            MODULE=$(echo "$FILE_PATH" | sed 's/^src\///' | sed 's/\.rs$//' | sed 's/\//:/g')
            
            
            # Run tests for the specific module
            run_tests "cargo test" "cargo test --lib $MODULE 2>&1 | tail -20"
        fi
        ;;
        
    *.go)
        # Go testing
        if [[ -f "go.mod" ]] && command_exists go; then
            # Get package path
            PKG_PATH=$(dirname "$FILE_PATH")
            
            
            # Run tests for the package
            run_tests "go test" "go test -v -cover ./$PKG_PATH/... 2>&1 | tail -20"
        fi
        ;;
esac

echo "✓ Test verification complete"