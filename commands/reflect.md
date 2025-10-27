# ATM Reflect Command

You are an expert at analyzing conversation patterns and improving documentation. Your task is to review the current conversation history and existing Claude rules to identify gaps and suggest improvements.

## Analysis Process

1. **Review Current Rules**: First locate the Claude rules directory by checking these locations in order:
   - Current project's `claude/rules/` directory (if in an atm/claude-config project)
   - Global `~/.claude/rules/` or `$HOME/.claude/rules/` directory
   - Use the LS tool to discover all rule files in the found directory, then read each to understand the current rule structure and coverage.

2. **Analyze Conversation History**: Look for patterns in the current conversation where:
   - You had to ask clarifying questions that could have been avoided
   - The user had to provide context that should be documented
   - Repeated preferences or patterns emerged
   - Workflow inefficiencies were identified
   - Tool usage patterns were established

3. **Identify Rule Gaps**: Find areas where:
   - Missing rules caused confusion or inefficiency
   - Existing rules are too vague or incomplete
   - New patterns emerged that should be codified
   - Tool preferences or workflows were established ad-hoc

## Output Format

Provide your analysis in this structure:

### Conversation Analysis Summary
Brief overview of key patterns and themes from the conversation.

### Identified Rule Gaps
List specific areas where rules are missing or insufficient:

**Gap**: [Description of missing rule area]
**Evidence**: [Specific examples from conversation]
**Impact**: [How this affects workflow efficiency]

### Suggested Rule Updates

For each rule file that should be updated or created:

#### `claude/rules/[filename].md` [EXISTING/NEW]
**Proposed Addition/Update**:
```markdown
[Exact text to add or update]
```
**Rationale**: [Why this rule would improve future interactions]

**Note**: If suggesting a new rule file, clearly indicate it's NEW and explain why it deserves its own file rather than being added to an existing one.

### Implementation Priority
Rank suggested changes by impact:
1. **High Priority**: [Critical workflow improvements]
2. **Medium Priority**: [Helpful clarifications]
3. **Low Priority**: [Nice-to-have additions]

## Instructions
- Be specific and actionable in your suggestions
- Focus on rules that would prevent repeated clarifications
- Consider both technical and workflow patterns
- Ensure suggestions align with existing rule structure and tone
- Only suggest additions that have clear evidence from the conversation