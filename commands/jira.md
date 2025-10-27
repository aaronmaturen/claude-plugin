# JIRA Ticket Implementation Research

Analyze a JIRA ticket, understand requirements, and research the codebase to identify where changes need to be made.

**Usage**: `/atm-jira TICKET-123`

## Process:

1. **Fetch JIRA ticket details**
   - Use `jira issue view {{TICKET}}` to get ticket information
   - Extract title, description, acceptance criteria, and any technical notes

2. **Analyze requirements**
   - Parse the ticket description and acceptance criteria
   - Identify key features, changes, or fixes needed
   - Note any mentioned files, components, or areas of the codebase

3. **Research codebase using ultraplan**
   - Enter ultraplan mode to perform comprehensive codebase analysis
   - Based on requirements, search for relevant files and patterns
   - Use appropriate search strategies:
     - Function/class names mentioned in ticket
     - Feature areas affected
     - Similar existing implementations
     - Error messages or log entries if it's a bug
   - Look for:
     - Entry points and API endpoints
     - Business logic implementations
     - Database models and migrations
     - Configuration files
     - Test files that need updates

4. **Create implementation plan**
   - List all files that need to be modified
   - Identify new files that need to be created
   - Note any dependencies or related systems
   - Highlight potential risks or considerations

5. **Generate structured output**
   ```
   📋 TICKET-123: [Title from JIRA]
   
   📝 Requirements Summary:
   - Key requirement 1
   - Key requirement 2
   
   🔍 Research Findings:
   
   Files to Modify:
   - path/to/file1.ext (reason for change)
   - path/to/file2.ext (reason for change)
   
   New Files Needed:
   - path/to/newfile.ext (purpose)
   
   Related Components:
   - Component A (how it's affected)
   - Component B (integration points)
   
   💡 Implementation Notes:
   - Important consideration 1
   - Potential gotcha or risk
   
   🚀 Suggested Approach:
   1. Start with...
   2. Then implement...
   3. Finally test...
   ```

## Example Usage:

```bash
/atm-jira PRO-1234
```

This will:
1. Fetch PRO-1234 from JIRA
2. Analyze the requirements
3. Use ultraplan to research the codebase
4. Output a comprehensive implementation guide

## Notes:
- Requires JIRA CLI to be configured (`jira` command)
- Uses ultraplan for intelligent code searching
- Focuses on WHERE changes need to be made, not HOW to implement them
- Provides context for developers to start implementation efficiently