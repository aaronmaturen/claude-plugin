---
description: "Audit AI agent prompts for best practices in prompt engineering, tool definitions, safety guardrails, and consistency patterns."
argument-hint: "[path]"
---
# AI Agent Prompt Audit

Audit AI agent prompts for best practices in prompt engineering, tool definitions, safety guardrails, and consistency patterns.

**Usage:**
- `/ai-agent-audit` - Audit current directory
- `/ai-agent-audit /path/to/project` - Audit specified path
- `/ai-agent-audit --branch` or `-b` - Audit only files changed in current branch

## Audit Philosophy

This audit focuses on **effective, safe, maintainable AI agent prompts**. The goal is identifying:
- Prompts that lack clarity or structure
- Missing safety guardrails and boundaries
- Inconsistent patterns across agents
- Token inefficiency (verbose where concise would work)
- Poor tool definitions that confuse the model
- Missing examples that would help the model

## Confidence Scoring

Score each finding 0-100 based on certainty and impact:

| Score | Meaning | Action |
|-------|---------|--------|
| 90-100 | Definite issue, blocks users/functionality | Report with "Critical" label |
| 80-89 | Likely issue, degrades experience | Report with "High" label |
| 60-79 | Possible issue, needs manual verification | Include in detailed report only |
| < 60 | Speculative, may be false positive | Suppress from report |

**Only surface findings with score >= 80 in the summary.** Lower-confidence findings go in an appendix for manual review.

### Scoring Criteria

For AI agent prompt audits:
- **Prompt Clarity**: Is the issue objectively measurable (e.g., missing identity) or subjective (e.g., could be clearer)?
- **Safety Risk**: Does this create security/safety issues (high score) or just inefficiency (lower score)?
- **Model Confusion Likelihood**: Will this definitely confuse the model (high score) or only in edge cases (lower score)?
- **Measurability**: Can we verify this through code/structure analysis, or is it based on predicted behavior?

## Common Setup

This audit uses the standard branch-mode pattern. The setup below:
1. Parses `--branch` / `-b` flags
2. Identifies changed files when in branch mode
3. Creates `search_files()` helper for consistent searching
4. Detects relevant framework/tooling

**Note:** This pattern is consistent across all audit commands for maintainability.

## Best Practices Reference

### Prompt Engineering Fundamentals
1. **Clear Role/Identity** - Agent knows who it is and its purpose
2. **Explicit Constraints** - What the agent should NOT do
3. **Structured Output** - When specific formats are needed
4. **Examples** - Few-shot learning for complex tasks
5. **Error Guidance** - How to handle edge cases

### Claude-Specific Best Practices
1. **XML Tags** - Use `<tags>` to structure complex prompts
2. **Thinking** - Encourage step-by-step reasoning for complex tasks
3. **Role Prompts** - Clear system prompts beat user-message role-play
4. **Tool Descriptions** - Clear, specific, with examples
5. **Context Windows** - Respect token limits, use progressive disclosure

## Investigation Process

### 0. **Setup and Discovery**

```bash
# Parse arguments for branch mode
BRANCH_MODE=false
APP_PATH="."

for arg in $ARGUMENTS; do
    case "$arg" in
        --branch|-b)
            BRANCH_MODE=true
            ;;
        *)
            APP_PATH="$arg"
            ;;
    esac
done

# Branch mode setup
if [[ "$BRANCH_MODE" == true ]]; then
    CURRENT_BRANCH=$(git branch --show-current)
    BASE_BRANCH="main"

    CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null | grep -E '\.(ts|js|py|md|txt)$' | grep -v "node_modules" | grep -v ".spec.")

    if [[ -z "$CHANGED_FILES" ]]; then
        echo "No relevant files changed compared to $BASE_BRANCH"
        exit 0
    fi

    echo "BRANCH MODE: Auditing only files changed in current branch"
    echo "   Branch: $CURRENT_BRANCH"
    echo "   Files to audit: $(echo "$CHANGED_FILES" | wc -l | tr -d ' ')"
    echo ""

    search_files() {
        local pattern="$1"
        local file_filter="${2:-}"
        if [[ -n "$file_filter" ]]; then
            echo "$CHANGED_FILES" | grep -E "$file_filter" | xargs grep -n "$pattern" 2>/dev/null
        else
            echo "$CHANGED_FILES" | xargs grep -n "$pattern" 2>/dev/null
        fi
    }
else
    echo "Full audit mode: $APP_PATH"

    search_files() {
        local pattern="$1"
        local file_filter="${2:-*.ts}"
        grep -rn "$pattern" --include="$file_filter" "$APP_PATH" 2>/dev/null | grep -v "node_modules"
    }
fi

# Detect AI framework
echo "=== AI Framework Detection ==="
grep -q "vercel/ai\|@ai-sdk" "$APP_PATH/package.json" 2>/dev/null && echo "   Vercel AI SDK detected"
grep -q "langchain" "$APP_PATH/package.json" 2>/dev/null && echo "   LangChain detected"
grep -q "@anthropic-ai/sdk" "$APP_PATH/package.json" 2>/dev/null && echo "   Anthropic SDK detected"
grep -q "openai" "$APP_PATH/package.json" 2>/dev/null && echo "   OpenAI SDK detected"
```

### 0.1 Eligibility Check (Quick - use haiku)

Before running a full audit, verify this audit is appropriate:

**Skip audit if:**
- No AI-related dependencies detected (no openai, anthropic, langchain, etc.)
- No prompt files or agent configuration files found
- No AI SDK imports in codebase

If skipping, output: "⏭️ Skipping AI agent audit - [reason]. This project doesn't appear to need this audit."

```bash
# Quick check for AI-related files and dependencies
AI_DEPS=0
grep -qE "openai|anthropic|langchain|@ai-sdk|vercel/ai|cohere|huggingface" "$APP_PATH/package.json" 2>/dev/null && AI_DEPS=1
[[ ! -f "$APP_PATH/package.json" ]] && grep -qE "openai|anthropic|langchain|cohere" "$APP_PATH/requirements.txt" 2>/dev/null && AI_DEPS=1

AI_FILE_COUNT=$(find "$APP_PATH" -type f \( -name "*prompt*.ts" -o -name "*prompt*.py" -o -name "*prompt*.md" -o -name "*.agent.ts" -o -name "*llm*" -o -name "*ai*.ts" \) -not -path "*/node_modules/*" -not -path "*/.venv/*" 2>/dev/null | wc -l | tr -d ' ')

if [[ "$AI_DEPS" -eq 0 ]] && [[ "$AI_FILE_COUNT" -eq 0 ]]; then
    echo "⏭️ Skipping AI agent audit - no AI dependencies or prompt files detected. This project doesn't appear to use AI agents."
    exit 0
fi

echo "✓ AI project detected - proceeding with audit"
[[ "$AI_FILE_COUNT" -gt 0 ]] && echo "   Found $AI_FILE_COUNT AI-related files"
```

### 1. **System Prompt Structure Audit**

#### 1.1 Find System Prompts

```bash
# Find system prompt files
echo "=== System Prompt Files ==="
find "$APP_PATH" -type f \( -name "*system*prompt*" -o -name "*prompt*system*" \) -not -path "*/node_modules/*" 2>/dev/null

# Find inline system prompts
grep -rn "system:\s*\`\|systemPrompt\|system_prompt\|SYSTEM_PROMPT" --include="*.ts" --include="*.js" "$APP_PATH" | grep -v "node_modules" | head -20

# Find generateSystemPrompt or similar functions
grep -rn "generateSystemPrompt\|buildSystemPrompt\|createSystemPrompt\|getSystemPrompt" --include="*.ts" "$APP_PATH" | grep -v "node_modules"
```

#### 1.2 System Prompt Quality Checks

**Check for essential components:**

| Component | Check For | Importance |
|-----------|-----------|------------|
| Identity/Role | "You are", "Your name is", "Act as" | Critical |
| Purpose | What the agent does, its goal | Critical |
| Constraints | "Do not", "Never", "Always" | High |
| Output Format | Expected response structure | Medium |
| Examples | Few-shot examples | Medium |
| Error Handling | "If you encounter", "When unsure" | Medium |

```bash
# Check for identity definition
grep -rn "You are\|Your name is\|Act as" --include="*prompt*.ts" --include="*prompt*.md" "$APP_PATH" | grep -v "node_modules" | head -10

# Check for constraints
grep -rn "Do not\|Never\|Must not\|CRITICAL\|IMPORTANT\|WARNING" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | head -20

# Check for examples in prompts
grep -rn "Example:\|For example\|e\.g\.\|<example>" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | head -10
```

#### 1.3 Token Efficiency

```bash
# Find large prompt files (potential bloat)
find "$APP_PATH" -type f \( -name "*prompt*.ts" -o -name "*prompt*.md" \) -not -path "*/node_modules/*" -exec wc -l {} + 2>/dev/null | sort -n | tail -10

# Check for repeated content patterns
grep -rn "IMPORTANT\|CRITICAL\|NOTE\|WARNING" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | wc -l
```

**Red flags:**
- Prompts over 1000 lines without tiered structure
- Same instructions repeated multiple times
- Overly verbose explanations where concise would work

### 2. **Tool Definition Audit**

#### 2.1 Find Tool Definitions

```bash
# Vercel AI SDK tools
grep -rn "tool(\|createTool\|defineTool" --include="*.ts" "$APP_PATH" | grep -v "node_modules" | head -20

# Find tool description patterns
grep -rn "description:\s*['\"\`]" --include="*.ts" "$APP_PATH" | grep -v "node_modules" | grep -v ".spec." | head -30

# Find Zod schemas for tools
grep -rn "z\.object\|z\.string\|z\.number" --include="*.ts" "$APP_PATH" | grep -v "node_modules" | wc -l
```

#### 2.2 Tool Description Quality

**Check each tool for:**

| Aspect | Good | Bad |
|--------|------|-----|
| Description | Clear, specific purpose | Vague or missing |
| Parameters | Well-documented with descriptions | No parameter descriptions |
| Return Value | Documented what it returns | No return documentation |
| When to Use | Clear trigger conditions | Ambiguous usage |
| Examples | Example inputs/outputs | No examples |

```bash
# Find tools without descriptions
grep -rn "tool(" -A 5 --include="*.ts" "$APP_PATH" | grep -v "description" | grep -v "node_modules" | head -20

# Find parameter schemas
grep -rn "parameters:\s*z\." -A 10 --include="*.ts" "$APP_PATH" | grep -v "node_modules" | head -30

# Check for .describe() on Zod schemas
grep -rn "\.describe(" --include="*.ts" "$APP_PATH" | grep -v "node_modules" | wc -l
```

#### 2.3 Tool Naming Conventions

```bash
# Extract tool names
grep -rn "tool\s*(" -A 2 --include="*.ts" "$APP_PATH" | grep "name:" | grep -v "node_modules"

# Check for consistent naming patterns
# Good: snake_case (get_entity_info) or camelCase (getEntityInfo)
# Bad: Mixed (Get_Entity_Info)
```

**Naming best practices:**
- Use verb_noun pattern (`get_entity`, `create_user`, `validate_config`)
- Be specific (`get_user_by_id` not `get_user`)
- Consistent case across all tools

### 3. **Entity Agent Description Audit** (for entity-based systems)

#### 3.1 Find Agent Descriptions

```bash
# Find agent description files
find "$APP_PATH" -name "*.agent.ts" -not -path "*/node_modules/*" 2>/dev/null

# Find agent registry
grep -rln "AgentDescription\|agentDescription\|EntityAgentDescription" --include="*.ts" "$APP_PATH" | grep -v "node_modules"

# Count agent descriptions
find "$APP_PATH" -name "*.agent.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l
```

#### 3.2 Progressive Disclosure Structure

```bash
# Check for tiered structure (tier1, tier2, tier3)
grep -rn "tier1\|tier2\|tier3" --include="*.agent.ts" "$APP_PATH" | grep -v "node_modules" | head -20

# Check tier content sizes
for tier in tier1 tier2 tier3; do
    echo "=== $tier usage ==="
    grep -rn "$tier:" --include="*.agent.ts" "$APP_PATH" | grep -v "node_modules" | wc -l
done
```

**Tier structure validation:**

| Tier | Purpose | Target Tokens |
|------|---------|---------------|
| tier1 | Quick reference, always in context | ~300 tokens |
| tier2 | Detailed reference, on-demand | ~1500 tokens |
| tier3 | Deep internals, troubleshooting | ~3000 tokens |

#### 3.3 Agent Description Completeness

```bash
# Check for required fields
for field in "shortDescription" "purpose" "criticalWarnings" "commonPatterns" "relationships"; do
    echo "=== Checking for $field ==="
    MISSING=$(find "$APP_PATH" -name "*.agent.ts" -not -path "*/node_modules/*" -exec grep -L "$field" {} \; 2>/dev/null)
    if [[ -n "$MISSING" ]]; then
        echo "Missing $field in:"
        echo "$MISSING"
    fi
done
```

### 4. **Safety & Guardrails Audit**

#### 4.1 Explicit Constraints

```bash
# Find safety-related language
grep -rn "must not\|should not\|never\|forbidden\|prohibited\|unsafe\|dangerous" --include="*prompt*.ts" --include="*prompt*.md" "$APP_PATH" | grep -v "node_modules" | head -20

# Find boundary definitions
grep -rn "boundary\|limit\|restrict\|scope\|allowed\|permitted" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | head -15
```

#### 4.2 Error Handling Guidance

```bash
# Find error handling instructions
grep -rn "if.*error\|when.*fail\|unable to\|cannot\|unknown" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | head -15

# Find fallback behavior
grep -rn "fallback\|default\|otherwise\|instead" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | head -10
```

#### 4.3 Output Validation

```bash
# Check for output format specifications
grep -rn "respond with\|return.*format\|output.*should\|JSON\|markdown" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | head -15

# Find structured output requirements
grep -rn "schema\|format\|structure" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | head -10
```

### 5. **Consistency Audit**

#### 5.1 Naming Conventions

```bash
# Check entity naming patterns
grep -rn "entityType:\|displayName:" --include="*.agent.ts" "$APP_PATH" | grep -v "node_modules"

# Check for consistent casing
grep -rn "entityType:" --include="*.ts" "$APP_PATH" | grep -v "node_modules" | awk -F"'" '{print $2}' | sort | uniq
```

#### 5.2 Pattern Consistency

```bash
# Find different prompt patterns (should be consistent)
grep -rn "You are\|Act as\|Your role" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules"

# Check for consistent structure across agents
find "$APP_PATH" -name "*.agent.ts" -not -path "*/node_modules/*" -exec head -30 {} \; 2>/dev/null | grep -E "export|interface|type" | sort | uniq -c
```

### 6. **Language/i18n Audit**

#### 6.1 Multi-language Support

```bash
# Find language configuration
grep -rn "language\|locale\|i18n\|LANGUAGE" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | head -15

# Find language-specific prompt generation
grep -rn "generateSystemPrompt.*language\|language.*prompt" --include="*.ts" "$APP_PATH" | grep -v "node_modules"

# Check for hardcoded English in prompts that should be i18n
grep -rn "please\|thank you\|sorry" --include="*prompt*.ts" "$APP_PATH" | grep -v "node_modules" | head -10
```

### 7. **Model Configuration Audit**

#### 7.1 Model Settings

```bash
# Find model configuration
grep -rn "model:\|maxTokens\|temperature\|topP" --include="*.ts" "$APP_PATH" | grep -v "node_modules" | head -20

# Find streaming configuration
grep -rn "streamText\|stream:\s*true" --include="*.ts" "$APP_PATH" | grep -v "node_modules" | head -10

# Check for model selection logic
grep -rn "getModel\|selectModel\|modelId" --include="*.ts" "$APP_PATH" | grep -v "node_modules" | head -10
```

#### 7.2 Token Management

```bash
# Find max token settings
grep -rn "maxTokens\|max_tokens\|MAX_TOKENS" --include="*.ts" "$APP_PATH" | grep -v "node_modules"

# Find context window management
grep -rn "contextWindow\|tokenCount\|truncate" --include="*.ts" "$APP_PATH" | grep -v "node_modules"
```

### 8. **Generate Report**

```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
AUDIT_DIR="${REPORT_BASE}/audits/ai-agent-$(basename $APP_PATH)-$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"
```

#### Report Structure:

```markdown
# AI Agent Prompt Audit Report

**Project:** [Project Name]
**Date:** [Audit Date]
**AI Framework:** [Vercel AI SDK / LangChain / etc.]
**Primary Model:** [Claude / GPT-4 / etc.]

## Executive Summary

### Overall Score: [A-F]

| Category | Score | Critical Issues |
|----------|-------|-----------------|
| System Prompts | | |
| Tool Definitions | | |
| Agent Descriptions | | |
| Safety Guardrails | | |
| Consistency | | |

### Top 3 Issues to Address

1. **[Issue]** - [Impact] - [Location]
2. **[Issue]** - [Impact] - [Location]
3. **[Issue]** - [Impact] - [Location]

## Detailed Findings

### System Prompts

#### Structure Analysis
**Status:** [Good/Needs Work/Critical]

| Component | Present | Quality |
|-----------|---------|---------|
| Identity/Role | Yes/No | |
| Purpose | Yes/No | |
| Constraints | Yes/No | |
| Examples | Yes/No | |
| Error Handling | Yes/No | |

**Issues Found:**
| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| | | | |

#### Token Efficiency
- Total system prompt tokens: [estimate]
- Progressive disclosure: [Yes/No]
- Redundancy score: [Low/Medium/High]

### Tool Definitions

#### Quality Audit
| Tool | Description Quality | Param Docs | When to Use | Examples |
|------|---------------------|------------|-------------|----------|
| | | | | |

**Missing or Weak Tool Descriptions:**
1. [tool_name] - [issue]

#### Naming Consistency
- Pattern used: [snake_case/camelCase/mixed]
- Inconsistencies found: [count]

### Agent Descriptions (if applicable)

#### Coverage
- Total entities: [count]
- With agent descriptions: [count]
- With complete tier structure: [count]

#### Tier Quality
| Entity | tier1 | tier2 | tier3 | Missing Fields |
|--------|-------|-------|-------|----------------|
| | | | | |

### Safety & Guardrails

#### Constraint Coverage
| Type | Present | Explicit |
|------|---------|----------|
| Behavioral boundaries | | |
| Output restrictions | | |
| Error handling | | |
| Fallback behavior | | |

**Missing Guardrails:**
1. [area] - [risk]

### Consistency

#### Cross-Agent Patterns
| Pattern | Consistent | Issues |
|---------|------------|--------|
| Naming | | |
| Structure | | |
| Tone | | |
| Error messages | | |

## Action Items

### Critical (P0)
1. [ ] [Action] - [File]

### High (P1)
1. [ ] [Action] - [File]

### Medium (P2)
1. [ ] [Action] - [File]

### Low (P3)
1. [ ] [Action] - [File]

## Best Practices Checklist

### System Prompts
- [ ] Clear identity and purpose defined
- [ ] Explicit constraints and boundaries
- [ ] Examples for complex behaviors
- [ ] Error handling guidance
- [ ] Appropriate length for context window

### Tool Definitions
- [ ] Every tool has a clear description
- [ ] Parameters documented with .describe()
- [ ] Return values documented
- [ ] When-to-use guidance in description
- [ ] Consistent naming convention

### Agent Descriptions
- [ ] All entities have descriptions
- [ ] Progressive disclosure (tier1/2/3) implemented
- [ ] Token budgets respected per tier
- [ ] Critical warnings highlighted
- [ ] Relationships documented

### Safety
- [ ] Behavioral boundaries explicit
- [ ] Output format constraints clear
- [ ] Error handling documented
- [ ] Fallback behaviors defined
- [ ] Sensitive operations flagged

---
**Audit Complete:** [Date/Time]
```

## Quick Reference: Common Issues

### System Prompt Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| No identity | Model confusion | Add "You are [Name], a [Role]..." |
| Missing constraints | Unexpected behavior | Add explicit "Do not..." rules |
| No examples | Poor complex task handling | Add few-shot examples |
| Too verbose | Token waste | Use tiered approach |
| Hardcoded values | Maintenance burden | Use template variables |

### Tool Definition Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| Vague description | Wrong tool selection | Be specific about purpose |
| No param descriptions | Incorrect parameters | Add .describe() to Zod |
| No usage guidance | Confusion | Add "Use this when..." |
| Inconsistent naming | Cognitive load | Standardize to snake_case |

### Progressive Disclosure Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| No tiers | Context bloat | Implement tier1/2/3 |
| Tier1 too large | Always exceeds budget | Trim to ~300 tokens |
| Missing tier3 | Can't troubleshoot | Add internals documentation |
| No token counting | Budget violations | Add token estimation |

## Claude-Specific Recommendations

### Effective Patterns

```xml
<!-- Use XML tags for structure -->
<instructions>
Clear, specific instructions here
</instructions>

<examples>
<example>
Input: ...
Output: ...
</example>
</examples>

<constraints>
- Do not...
- Never...
- Always...
</constraints>
```

### Tool Description Pattern

```typescript
tool({
  name: 'get_entity_info',
  description: `Retrieves detailed information about an entity type.

Use this when the user asks about:
- How to configure a specific entity
- What fields an entity requires
- Dependencies between entities

Parameters:
- entityType: The type of entity (e.g., 'organization', 'client')
- tier: Detail level (1=quick, 2=detailed, 3=internals)

Returns: Entity description at the requested detail level.

Example: get_entity_info('organization', 1) returns quick reference for organizations.`,
  parameters: z.object({
    entityType: z.string().describe('Entity type to look up'),
    tier: z.number().min(1).max(3).describe('Detail level: 1=quick, 2=detailed, 3=deep'),
  }),
  execute: async ({ entityType, tier }) => { ... }
})
```

### Progressive Disclosure Pattern

```typescript
const entityAgentDescription = {
  entityType: 'example',

  // tier1: Always in context (~300 tokens)
  tier1: {
    shortDescription: 'One sentence purpose',
    purpose: 'Why this entity exists',
    quickStart: { minimalExample: {...} },
    criticalWarnings: ['Most important warning'],
    relationships: { requires: [], requiredBy: [] }
  },

  // tier2: Retrieved on request (~1500 tokens)
  tier2: {
    extendedDescription: 'Full explanation...',
    requiredFields: [...],
    optionalFields: [...],
    commonPatterns: [...]
  },

  // tier3: For troubleshooting (~3000 tokens)
  tier3: {
    internalDetails: '...',
    databaseSchema: '...',
    debuggingTips: [...]
  }
}
```
