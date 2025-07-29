# Generate JIRA-Linked Commit Message

Analyze staged changes and generate a commit message with JIRA ticket number from the current branch.

**IMPORTANT**: 
- DO NOT COMMIT - only output the commit message and copy it to clipboard
- DO NOT include any "Co-authored-by: Claude" or emoji signatures
- Generate clean, professional commit messages only

## Steps:

1. **Extract ticket number from branch**
   - Run `git branch --show-current` to get current branch name
   - Look for these patterns in the branch name:
     - `PRO-####` (e.g., PRO-1234)
     - `BUG-###` (e.g., BUG-123)
   - If no matching pattern found:
     - Proceed without ticket prefix
     - Do NOT suggest the user change their branch name
     - Simply generate a standard commit message

2. **Analyze staged changes**
   - Run `git diff --cached` to see only staged changes
   - If nothing is staged:
     - Assume user wants to commit all modified files
     - Run `git diff` to see all unstaged changes
     - Run `git status --short` to see all modified/new files
   - If this is the first commit (no HEAD exists):
     - Run `git diff --cached --stat` to see what files will be committed
   - For context on branch changes:
     - Check if on main/master: `git branch --show-current`
     - If on feature branch, optionally show: `git log --oneline main..HEAD` (if main exists)
   - Focus on what's actually being committed in THIS commit

3. **Check for new TODO comments**
   - Run `git diff --cached` to scan staged changes for new TODO comments
   - Look for patterns like:
     - `TODO:`
     - `TODO(`
     - `// TODO`
     - `# TODO`
     - `/* TODO`
   - If new TODOs are found:
     - Display the new TODO comments and their locations
     - Ask explicitly: "New TODO comments detected. Do you want to continue with the commit? (y/n)"
     - If user says no, suggest they address the TODOs first
     - If user says yes, proceed with commit message generation
   - If no new TODOs found, continue normally

4. **Generate commit message format:**
   ```
   [PRO-####] Brief description (50 chars total)

   Detailed explanation of changes, why they were made,
   and any important context. Wrap at 72 characters.
   ```
   
   **If no ticket number found**, use format:
   ```
   Brief description (50 chars max)

   Detailed explanation of changes, why they were made,
   and any important context. Wrap at 72 characters.
   ```

5. **Copy to clipboard:**
   - After generating the commit message, use `pbcopy` to copy it to clipboard
   - Display the commit message to the user
   - Add a note that it has been copied to clipboard

## Guidelines:
- **Subject line**: 
  - If ticket found: Start with `[PRO-####]` or `[BUG-###]`, 50 chars max total
  - If no ticket: Just the description, 50 chars max
- **Use present tense**: "Add feature" not "Added feature"
- **Body**: Wrap at 72 characters, explain what and why (not how)
- **Professional tone**: Friendly but not overly casual

## Example Output:

**With PRO ticket:**
```
[PRO-1234] Add user authentication flow

Implemented login and registration endpoints with JWT tokens.
Added password reset functionality and email verification
to ensure secure user onboarding.
```

**With BUG ticket:**
```
[BUG-567] Fix memory leak in image processor

Properly dispose of image buffers after processing.
Added cleanup in finally block to ensure resources
are released even on exceptions.
```

**Without ticket (normal branch):**
```
Refactor database connection pooling

Extracted connection logic into separate module for
better testability and reuse across services.
```

## What to avoid:
- Overly casual language ("wild ride", "here's the kicker")
- References to developers or blame
- Ending subject line with period
- Past tense in subject line
- Forcing ticket numbers when branch doesn't contain PRO-#### or BUG-###

## Special Cases:
- **Initial commit**: Use "Initial commit" or "Initialize repository with [description]"
- **On main branch**: No ticket prefix unless branch name contains PRO-#### or BUG-###
- **Sequential commits**: Focus only on staged changes, not entire branch diff
- **Nothing staged**: Analyze all modified files (assume user will stage all)
- **Feature branches without tickets**: Generate normal commit message without prefix