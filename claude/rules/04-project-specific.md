# Project-Specific Rules

## Jira Integration
- Branch names typically follow the pattern: `feature/PRO-####-description`
- Always extract ticket numbers from branch names when generating commit messages
- PRO prefix may vary based on project

## Code Style
- Follow existing patterns in the codebase
- Match indentation and formatting of surrounding code
- Don't add comments unless explicitly requested
- Preserve existing code style over personal preferences

## Testing
- Check for test commands in package.json, Makefile, or similar
- Never assume specific test frameworks
- Ask user for test commands if unclear
- Run tests only when explicitly requested