# Implement PR Feedback

Analyze GitHub PR comments and implement suggested changes.

**PR URL:** $ARGUMENTS

## Steps:

1. **Parse PR Information**
   - Extract owner, repo, and PR number from the provided URL
   - Format: `https://github.com/{owner}/{repo}/pull/{number}`

2. **Fetch PR Details and Comments**
   - `gh pr view {number} --repo {owner}/{repo} --json title,body,state,files`
   - `gh api repos/{owner}/{repo}/pulls/{number}/comments` - Review comments
   - `gh api repos/{owner}/{repo}/issues/{number}/comments` - Issue comments
   - `gh api repos/{owner}/{repo}/pulls/{number}/reviews` - PR reviews
   - Handle API failures gracefully:
     - Check if `gh` is authenticated: `gh auth status`
     - Verify repo access permissions
     - Provide clear error messages if API calls fail

3. **Analyze Feedback**
   - Extract actionable suggestions from comments
   - Identify code change requests
   - Note any requested improvements or fixes
   - Filter out resolved conversations

4. **Categorize Feedback**
   - **Must Fix**: Blocking issues, bugs, security concerns
   - **Should Fix**: Code quality, best practices, performance
   - **Consider**: Style preferences, minor improvements

5. **Implementation Plan**
   - Create a todo list of all actionable items
   - Prioritize based on feedback importance
   - Group related changes together
   - Present the plan to the user with:
     - List of all actionable feedback
     - Priority levels for each item
     - Estimated complexity
   
6. **User Confirmation**
   - **PAUSE** for user input
   - Ask: "Review the implementation plan above. Would you like to proceed with these changes? (yes/no/edit)"
   - Allow user to:
     - Approve and continue
     - Skip certain items
     - Add additional context
     - Cancel the operation

7. **Create Safety Backup** (Optional)
   - Ask user: "Create a backup branch before making changes? (recommended)"
   - If yes: `git checkout -b {branch-name}-feedback-backup`
   - Return to PR branch: `git checkout {branch-name}`

8. **Execute Changes**
   - Checkout the PR branch locally
   - Implement each approved feedback item
   - Mark todos as completed after each change
   - Run tests after modifications
   - Stage changes and prepare commit messages (but DO NOT commit)

9. **Prepare Summary for User**
   - Generate a summary of all implemented changes
   - List any skipped feedback with reasoning
   - Prepare summary comment text for the PR:
     ```
     ## Feedback Implementation Summary
     
     ✅ Implemented:
     - [Item 1]: Fixed in commit abc123
     - [Item 2]: Updated in commit def456
     
     ⏭️ Skipped (with reasoning):
     - [Item 3]: Not applicable because...
     
     All requested changes have been addressed.
     ```

10. **Final Instructions for User**
   - Display summary of changes made
   - Remind user to:
     - Review the changes
     - Run tests locally
     - Push when ready: `git push`
     - Post the summary comment on the PR
   - **IMPORTANT**: DO NOT push changes - this is always a manual process

## Example Usage:
```
Command: atm-implement-pr-feedback https://github.com/acme/project/pull/123

Output:
- Fetching PR #123 feedback...
- Found 5 actionable comments
- Creating implementation plan...
- Implementing feedback...
```

## Additional Features:

### Dry Run Mode
Add `--dry-run` flag to preview changes without implementing:
```
Command: atm-implement-pr-feedback https://github.com/acme/project/pull/123 --dry-run
```
- Shows what would be changed
- Lists files that would be modified
- No actual changes made

### Error Handling
- Validates PR URL format before proceeding
- Checks GitHub CLI authentication
- Verifies repository access
- Handles rate limiting gracefully
- Provides clear error messages

## Notes:
- Requires GitHub CLI (`gh`) to be installed and authenticated
- Will automatically checkout the PR branch if not already on it
- Focuses only on actionable feedback, ignoring discussion comments
- Creates backup branch option for safety
- Supports marking comments as resolved