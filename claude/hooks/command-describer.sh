#!/bin/bash

# Command Describer Hook
# Adds meaningful descriptions to commands before logging them

set -euo pipefail

# Get the command from environment
COMMAND="${CLAUDE_COMMAND:-}"

# Function to describe common commands
describe_command() {
    local cmd="$1"
    
    # Extract the base command
    local base_cmd=$(echo "$cmd" | awk '{print $1}')
    
    case "$base_cmd" in
        "git")
            case "$cmd" in
                *"git status"*) echo "Checking repository status" ;;
                *"git diff"*) echo "Reviewing code changes" ;;
                *"git add"*) echo "Staging files for commit" ;;
                *"git commit"*) echo "Creating a new commit" ;;
                *"git push"*) echo "Pushing changes to remote" ;;
                *"git pull"*) echo "Pulling latest changes" ;;
                *"git branch"*) echo "Managing branches" ;;
                *"git log"*) echo "Reviewing commit history" ;;
                *) echo "Running git operation: $cmd" ;;
            esac
            ;;
        
        "npm"|"yarn"|"pnpm")
            case "$cmd" in
                *"install"*) echo "Installing dependencies" ;;
                *"test"*) echo "Running tests" ;;
                *"build"*) echo "Building the project" ;;
                *"start"*|*"dev"*) echo "Starting development server" ;;
                *"lint"*) echo "Running linter" ;;
                *"typecheck"*) echo "Running type checker" ;;
                *) echo "Running $base_cmd: $cmd" ;;
            esac
            ;;
        
        "ls")
            echo "Listing directory contents"
            ;;
        
        "cd")
            local dir=$(echo "$cmd" | sed 's/cd //')
            echo "Navigating to: $dir"
            ;;
        
        "mkdir")
            echo "Creating directory structure"
            ;;
        
        "rm"|"rmdir")
            echo "Removing files/directories"
            ;;
        
        "cp"|"mv")
            echo "Moving/copying files"
            ;;
        
        "cat"|"less"|"more")
            echo "Reading file contents"
            ;;
        
        "grep"|"rg"|"ag")
            echo "Searching for patterns in files"
            ;;
        
        "find")
            echo "Finding files in directory tree"
            ;;
        
        "chmod"|"chown")
            echo "Changing file permissions"
            ;;
        
        "python"|"python3")
            case "$cmd" in
                *"test"*) echo "Running Python tests" ;;
                *"setup.py"*) echo "Running Python setup" ;;
                *) echo "Executing Python script" ;;
            esac
            ;;
        
        "make")
            echo "Running build process"
            ;;
        
        "docker")
            case "$cmd" in
                *"build"*) echo "Building Docker image" ;;
                *"run"*) echo "Running Docker container" ;;
                *"compose"*) echo "Managing Docker Compose services" ;;
                *) echo "Docker operation: $cmd" ;;
            esac
            ;;
        
        *)
            # For other commands, just use a generic description
            echo "Executing: $cmd"
            ;;
    esac
}

# Main execution
if [[ -n "$COMMAND" ]]; then
    DESCRIPTION=$(describe_command "$COMMAND")
    
    # Log the meaningful action
    CLAUDE_HOOK_TYPE="action" sh ~/.claude/hooks/obsidian-logger.sh "action" "$DESCRIPTION"
fi

exit 0