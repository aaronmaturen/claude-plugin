#!/bin/bash
# Determines if a file needs linting and which linters are available
# Usage: needs-lint.sh <file_path>

set -euo pipefail

FILE_PATH="${1:-}"

if [[ -z "$FILE_PATH" ]]; then
    echo "Usage: needs-lint.sh <file_path>"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if npx package exists
npx_exists() {
    npx --no-install "$1" --version >/dev/null 2>&1
}

# Output JSON format for easy parsing
output_json() {
    local needs_lint=$1
    local linters=$2
    echo "{\"needs_lint\": $needs_lint, \"linters\": [$linters]}"
}

# Check file extension and available linters
case "$FILE_PATH" in
    *.py)
        linters=()
        
        # Check for Python project
        if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
            # Check for virtual environment
            if [[ -f ".venv/bin/activate" ]]; then
                source .venv/bin/activate
            elif [[ -f "venv/bin/activate" ]]; then
                source venv/bin/activate
            fi
            
            # Check available Python linters
            command_exists black && linters+=("\"black\"")
            command_exists isort && linters+=("\"isort\"")
            command_exists autoflake && linters+=("\"autoflake\"")
            command_exists pylint && linters+=("\"pylint\"")
            command_exists flake8 && linters+=("\"flake8\"")
            command_exists mypy && linters+=("\"mypy\"")
            
            if [[ ${#linters[@]} -gt 0 ]]; then
                output_json "true" "$(IFS=,; echo "${linters[*]}")"
            else
                output_json "false" ""
            fi
        else
            output_json "false" ""
        fi
        ;;
        
    *.js|*.jsx|*.ts|*.tsx|*.html|*.css|*.scss|*.less|*.json)
        linters=()
        
        # Check for Node.js project
        if [[ -f "package.json" ]]; then
            # Check available JS/TS linters
            npx_exists prettier && linters+=("\"prettier\"")
            
            case "$FILE_PATH" in
                *.js|*.jsx|*.ts|*.tsx|*.html)
                    npx_exists eslint && linters+=("\"eslint\"")
                    ;;
            esac
            
            # Check for other linters
            npx_exists stylelint && [[ "$FILE_PATH" =~ \.(css|scss|less)$ ]] && linters+=("\"stylelint\"")
            npx_exists tslint && [[ "$FILE_PATH" =~ \.(ts|tsx)$ ]] && linters+=("\"tslint\"")
            
            if [[ ${#linters[@]} -gt 0 ]]; then
                output_json "true" "$(IFS=,; echo "${linters[*]}")"
            else
                output_json "false" ""
            fi
        else
            output_json "false" ""
        fi
        ;;
        
    *.rs)
        linters=()
        if [[ -f "Cargo.toml" ]]; then
            command_exists rustfmt && linters+=("\"rustfmt\"")
            command_exists clippy && linters+=("\"clippy\"")
            
            if [[ ${#linters[@]} -gt 0 ]]; then
                output_json "true" "$(IFS=,; echo "${linters[*]}")"
            else
                output_json "false" ""
            fi
        else
            output_json "false" ""
        fi
        ;;
        
    *.go)
        linters=()
        if [[ -f "go.mod" ]]; then
            command_exists gofmt && linters+=("\"gofmt\"")
            command_exists golint && linters+=("\"golint\"")
            command_exists go && linters+=("\"go vet\"")
            
            if [[ ${#linters[@]} -gt 0 ]]; then
                output_json "true" "$(IFS=,; echo "${linters[*]}")"
            else
                output_json "false" ""
            fi
        else
            output_json "false" ""
        fi
        ;;
        
    *.rb)
        linters=()
        if [[ -f "Gemfile" ]]; then
            command_exists rubocop && linters+=("\"rubocop\"")
            
            if [[ ${#linters[@]} -gt 0 ]]; then
                output_json "true" "$(IFS=,; echo "${linters[*]}")"
            else
                output_json "false" ""
            fi
        else
            output_json "false" ""
        fi
        ;;
        
    *.sh)
        linters=()
        command_exists shellcheck && linters+=("\"shellcheck\"")
        command_exists shfmt && linters+=("\"shfmt\"")
        
        if [[ ${#linters[@]} -gt 0 ]]; then
            output_json "true" "$(IFS=,; echo "${linters[*]}")"
        else
            output_json "false" ""
        fi
        ;;
        
    *)
        # Unknown file type
        output_json "false" ""
        ;;
esac