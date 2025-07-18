# ATM Clear Command

This command creates a summary of work done, clears context, and provides the summary to the new session.

## Instructions:

1. **Analyze Current Session**
   - Review the conversation history
   - Identify key tasks completed
   - Note important context and decisions made
   - List files modified and their changes

2. **Create Work Summary**
   Generate a summary including:
   - **Project/Task Overview**: What was being worked on
   - **Changes Made**: Bullet points of completed work
   - **Key Files Modified**: List of files changed
   - **Important Context**: Any crucial information for continuity
   - **Next Steps**: What remains to be done (if applicable)

3. **Clear and Continue**
   - Use `/clear` command
   - Paste the summary to provide context for the new session
   - Format the continuation message to be helpful for picking up work

## Example Output Format:

```
## Summary of Work

### Task Overview:
Working on [feature/bug/refactoring] in [project name]

### Changes Made:
- [Change 1 description]
- [Change 2 description]
- [Change 3 description]

### Key Files Modified:
- path/to/file1.ext - [what changed]
- path/to/file2.ext - [what changed]

### Important Context:
- [Key decision or approach taken]
- [Dependencies or considerations]
- [Current branch name if relevant]

### Next Steps:
- [Task to continue with]
- [Any pending items]

/clear

## Continuing Work on [Project/Feature Name]

You were working on [brief description]. Recent changes included [key changes]. The project uses [relevant tech stack]. [Any other crucial context for continuity].
```

## Usage:
Simply run this command at the end of a session to summarize work and prepare for a clean handoff to the next session.