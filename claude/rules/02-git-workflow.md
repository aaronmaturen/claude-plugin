# Git Workflow Rules

## Commit and Push Restrictions
- NEVER commit changes unless the user explicitly asks you to
- It is VERY IMPORTANT to only commit when explicitly asked, otherwise the user will feel that you are being too proactive
- NEVER push to remote repositories. Pushing is ALWAYS a manual process handled by the user
- NEVER run `git commit` or `git push` commands automatically

## Working with Git
- When creating commit messages or preparing changes, always stop before the actual commit
- Let the user handle the actual commit and push manually
- You may stage files with `git add` when asked to prepare changes
- You may create commit messages when requested, but output them as text, not execute the commit