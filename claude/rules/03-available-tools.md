# Available CLI Tools

The following CLI tools are available and configured in the environment:

## GitHub CLI (gh)
Use `gh` commands for all GitHub operations (PRs, issues, API calls)
- Already authenticated with the user's GitHub account
- Examples:
  - `gh pr view <number>` - View PR details
  - `gh pr list` - List PRs
  - `gh api` - Make GitHub API calls
  - `gh issue create` - Create issues
  - `gh pr checkout <number>` - Checkout a PR branch
  - `gh pr diff` - View PR diff

## Jira CLI (jira)
Use `jira` commands for Jira operations
- Configured with the user's Jira instance
- Examples:
  - `jira issue list` - List issues
  - `jira issue view <key>` - View issue details
  - `jira sprint list` - List sprints
  - `jira me` - Show current user
  - `jira issue create` - Create new issue
  - `jira issue assign <key> <user>` - Assign issue

## Git
Standard git commands are available
- Remember: NEVER commit or push automatically
- Common operations:
  - `git status` - Check working tree status
  - `git diff` - Show unstaged changes
  - `git diff --cached` - Show staged changes
  - `git branch` - List branches
  - `git log` - View commit history
  - `git add` - Stage files (when requested)

## Best Practices
- When working with PRs or Jira tickets, prefer using these CLI tools over web scraping or manual API calls
- Always check tool availability before using (commands might fail if not installed/configured)
- Use structured output formats when available (e.g., `--json` flags)