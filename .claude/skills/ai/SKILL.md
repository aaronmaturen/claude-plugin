---
name: ai
description: This skill should be used when the user asks to 'write a prompt', 'design an agent', 'create a system prompt', 'work with LLMs', or 'build AI tooling'. Provides patterns for prompt engineering, tool use, and agent design.
version: 1.0.0
metadata:
  internal: false
---

# AI

Patterns for prompt engineering, tool use design, and AI agent development.

## Capabilities

- **Prompt Engineering**: System prompts, few-shot examples, structured outputs
- **Tool Use Design**: When and how to expose tools to LLMs
- **Agent Orchestration**: Multi-agent patterns, task delegation
- **Claude Code Configuration**: CLAUDE.md, AGENTS.md, slash commands, skills

## System Prompt Structure

Effective system prompts follow a consistent structure:

```markdown
# Role & Identity
You are a [specific role] that [core responsibility].

# Core Rules
- NEVER [critical constraint]
- ALWAYS [required behavior]
- PREFER [soft guidance]

# Capabilities
What the agent can do, organized by category.

# Workflow
Step-by-step process for common tasks.

# Output Format
Expected structure of responses.
```

**Key principles:**
- Lead with identity and constraints
- Use NEVER/ALWAYS/PREFER for rule hierarchy
- Be specific about what NOT to do (prevents hallucination)
- Include examples for ambiguous cases

## Few-Shot Prompting

Provide examples to establish patterns:

```markdown
## Examples

### Example 1: Bug Fix
Input: "The login button doesn't work"
Analysis: User-facing bug, needs reproduction steps
Output: Ask for browser, error messages, steps to reproduce

### Example 2: Feature Request
Input: "Add dark mode"
Analysis: Feature request, needs scope clarification
Output: Ask about scope (full app vs specific pages), timeline, design specs
```

**Best practices:**
- 2-4 examples cover most cases
- Include edge cases that might confuse the model
- Show the reasoning, not just input/output

## Tool Use Design

### When to Create Tools

**Good candidates for tools:**
- Actions with side effects (file writes, API calls, git operations)
- Operations requiring external data (file reads, web fetches)
- Complex computations better done in code
- Operations that need to be auditable

**Keep as inline prompting:**
- Text transformation and analysis
- Decision-making logic
- Format conversion
- Summarization

### Tool Schema Best Practices

```json
{
  "name": "create_file",
  "description": "Creates a new file. Use for generating code, configs, or documentation. Fails if file exists.",
  "parameters": {
    "path": {
      "type": "string",
      "description": "Absolute path where file will be created"
    },
    "content": {
      "type": "string",
      "description": "Full file content to write"
    },
    "overwrite": {
      "type": "boolean",
      "description": "If true, overwrites existing files. Default: false",
      "default": false
    }
  },
  "required": ["path", "content"]
}
```

**Principles:**
- Description explains WHEN to use, not just what it does
- Parameter descriptions include format expectations
- Sensible defaults reduce required parameters
- Name is verb_noun format

## Agent Orchestration Patterns

### Specialist Delegation

Route tasks to specialized sub-agents:

```markdown
## Available Specialists

- **Researcher**: Explores codebases, reads docs, gathers context
- **Implementer**: Writes and modifies code
- **Reviewer**: Analyzes code quality, finds issues
- **Planner**: Breaks down complex tasks into steps

## Routing Rules

1. Unknown codebase? → Researcher first
2. Clear implementation task? → Implementer directly
3. PR review request? → Reviewer
4. Complex multi-step task? → Planner → then delegate
```

### Investigation-First Pattern

For debugging and exploration:

```markdown
## Investigation Workflow

1. **Gather Context**: Read relevant files, check git history
2. **Form Hypothesis**: What might be causing this?
3. **Verify**: Find evidence supporting or refuting
4. **Act**: Only make changes after understanding
5. **Validate**: Run tests, check behavior

NEVER skip to step 4 without completing 1-3.
```

## Claude Code Configuration

### CLAUDE.md Structure

Project-level instructions in `CLAUDE.md`:

```markdown
# Project Name

## Philosophy
Brief description of what this config prioritizes.

## Core Guardrails
- NEVER [critical things to avoid]
- ALWAYS [required behaviors]
- PREFER [soft preferences]

## When to Use Commands
Organized by use case, not alphabetically.

## Available Tools
External CLIs and their purposes.
```

### AGENTS.md for Documentation

Use `AGENTS.md` for detailed documentation that CLAUDE.md references:

```markdown
# CLAUDE.md
See [AGENTS.md](AGENTS.md) for project documentation and conventions.
```

This keeps CLAUDE.md focused on guardrails while AGENTS.md holds comprehensive docs.

### Slash Command Structure

Commands in `.claude/commands/`:

```markdown
---
name: command-name
description: When to use this command (shown in /help)
---

# Command Name

## Purpose
What this command accomplishes.

## Process
Step-by-step instructions for Claude to follow.

## Output Format
Expected deliverable structure.
```

### Skill File Structure

Skills in `.claude/skills/<category>/SKILL.md`:

```markdown
---
name: skill-name
description: Trigger phrases that activate this skill
version: 1.0.0
metadata:
  internal: false
---

# Skill Name

Description of what patterns this skill provides.

## Capabilities
Bulleted list of what this skill covers.

## Patterns
Detailed examples and code snippets.

## Best Practices
Guidelines for applying these patterns.

## Limitations
What this skill doesn't cover.
```

## Structured Output Patterns

### Markdown Reports

```markdown
## Output Format

Generate a markdown report with:

# [Title]

## Summary
2-3 sentence overview of findings.

## Findings

### [Category 1]
- **Issue**: Description
- **Location**: file:line
- **Severity**: High/Medium/Low
- **Fix**: Recommended action

## Recommendations
Prioritized list of next steps.
```

### JSON for Programmatic Use

```markdown
## Output Format

Return valid JSON:

{
  "status": "success" | "error",
  "findings": [
    {
      "type": "bug" | "smell" | "suggestion",
      "file": "path/to/file.ts",
      "line": 42,
      "message": "Description",
      "severity": 1-5
    }
  ],
  "summary": "Brief overview"
}
```

## Common Pitfalls

- **Vague system prompts**: "Be helpful" → specify exact behaviors
- **Tool overload**: 50 tools confuse the model → 5-10 focused tools
- **Missing constraints**: Model invents behaviors → explicit NEVER rules
- **No examples**: Ambiguous tasks get inconsistent results → few-shot
- **Monolithic agents**: One agent does everything → specialist delegation

## Best Practices

1. **Constraints before capabilities**: What NOT to do is clearer than what to do
2. **Specific over general**: "Use conventional commits" > "Write good commits"
3. **Examples over explanations**: Show, don't tell
4. **Escape hatches**: "Ask if unclear" prevents bad assumptions
5. **Audit trails**: Log reasoning, not just actions

## References

- [Anthropic Prompt Engineering Guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Tool Use Best Practices](https://docs.anthropic.com/en/docs/build-with-claude/tool-use)
