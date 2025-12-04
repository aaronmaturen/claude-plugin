# Problem Solver - External Research Investigation

Research-focused investigation for issues that may have known solutions externally. Use this BEFORE or ALONGSIDE `/bug-investigation` when:
- Error messages suggest dependency/framework issues
- You're not sure if this is a known problem
- Stack traces point to library code
- Recent dependency updates might be the cause

**Problem:** $ARGUMENTS (Error message, JIRA ID, or problem description)

## When to Use This vs Bug Investigation

| Use `/problem-solver` | Use `/bug-investigation` |
|-----------------------|--------------------------|
| "Has anyone seen this before?" | "Why is OUR code doing this?" |
| Dependency/library errors | Application logic bugs |
| Framework behavior questions | Business logic issues |
| Version compatibility issues | Integration between our services |
| Unknown error origins | Known location in codebase |

**Best Practice:** Run `/problem-solver` first for external context, then `/bug-investigation` for internal root cause.

## Investigation Process

### 1. **Problem Context Extraction**

```bash
# If JIRA ID provided
if [[ "$ARGUMENTS" =~ ^[A-Z]+-[0-9]+$ ]]; then
    jira issue view "$ARGUMENTS" --output json > /tmp/problem_details.json
    DESCRIPTION=$(jq -r '.fields.description' /tmp/problem_details.json)
    SUMMARY=$(jq -r '.fields.summary' /tmp/problem_details.json)
fi
```

#### Extract Key Signals
```markdown
## Problem Signals

### Error Pattern
- **Error Message:** [Exact error text]
- **Error Type:** [TypeError/NetworkError/ValidationError/etc.]
- **Stack Trace Location:** [First non-node_modules frame]

### Technology Context
- **Framework:** [Angular X.X / Django X.X]
- **Language:** [TypeScript X.X / Python X.X]
- **Key Dependencies:** [List relevant packages + versions]
- **Runtime:** [Node X.X / Python X.X]

### Timing Context
- **When Started:** [Date/commit if known]
- **Recent Changes:** [Deployments, dependency updates]
- **Frequency:** [Always/Intermittent/Environment-specific]
```

### 2. **Hypothesis Generation**

Before researching, form testable hypotheses:

```markdown
## Hypotheses (Rank by Likelihood)

| # | Hypothesis | Testable? | Research Query |
|---|------------|-----------|----------------|
| H1 | [Dependency version incompatibility] | Yes | "[package] [version] [error]" |
| H2 | [Framework breaking change] | Yes | "[framework] [version] breaking changes" |
| H3 | [Known library bug] | Yes | "[library] github issues [error]" |
| H4 | [Configuration issue] | Yes | "[framework] [config option] [symptom]" |
| H5 | [Our code logic error] | Yes | → Route to /bug-investigation |
```

### 3. **External Research Phase**

#### 3.1 GitHub Issues Search

**Search Strategy:**
```
# Primary search
[package-name] [exact-error-message]

# Broader search
[framework] [error-type] [symptom]

# Version-specific
[package] [version] regression OR breaking
```

**Document Findings:**
| Repository | Issue # | Title | Status | Relevance |
|------------|---------|-------|--------|-----------|
| | | | Open/Closed | High/Medium/Low |

**Solution Patterns Found:**
- [ ] Workaround available
- [ ] Fix in newer version
- [ ] Configuration change needed
- [ ] Known limitation (no fix)

#### 3.2 Stack Overflow Research

**Search Strategy:**
```
# Exact error
"[exact error message]" [framework]

# Symptom-based
[framework] [what's happening] [what should happen]
```

**Quality Filters:**
- Answers with 10+ upvotes
- Accepted answers
- Recent answers (within 2 years for active frameworks)

**Document Findings:**
| Question | Score | Answer Quality | Applicable? |
|----------|-------|----------------|-------------|
| [Link] | | Accepted/High-voted | Yes/Partial/No |

#### 3.3 Official Documentation Check

**Check These Sources:**
- [ ] Migration guide (if recent version upgrade)
- [ ] Changelog/Release notes
- [ ] Known issues page
- [ ] API deprecation notices
- [ ] Configuration reference

**Version-Specific Notes:**
```markdown
## Documentation Findings

### Breaking Changes in [Version]
- [Change 1]: [Impact on our code]
- [Change 2]: [Impact on our code]

### Deprecation Warnings
- [Deprecated API]: [Replacement]

### Configuration Changes
- [Old config]: [New config]
```

#### 3.4 Dependency Analysis

```bash
# Check for recent updates that might have caused issues
# For Node.js
npm ls [suspected-package]
npm view [package] time --json | jq 'to_entries | sort_by(.value) | reverse | .[0:5]'

# For Python
pip show [package]
pip index versions [package]
```

**Dependency Timeline:**
| Package | Our Version | Latest | Last Update | Breaking Changes? |
|---------|-------------|--------|-------------|-------------------|
| | | | | |

### 4. **Solution Confidence Assessment**

```markdown
## Research Confidence Score

### Source Validation
| Source Type | Found | Quality | Confidence |
|-------------|-------|---------|------------|
| GitHub Issues | X issues | [Relevant/Partial] | X% |
| Stack Overflow | X answers | [Accepted/Voted] | X% |
| Official Docs | [Yes/No] | [Clear/Vague] | X% |
| Community Blogs | X posts | [Recent/Dated] | X% |

### Overall Confidence: [X]%

**Confidence Thresholds:**
- **>85%**: Clear solution, proceed with implementation
- **60-85%**: Likely solution, verify with testing
- **<60%**: Uncertain, escalate to `/bug-investigation` for internal analysis
```

### 5. **Solution Synthesis**

```markdown
## Recommended Solution

### Primary Solution (Confidence: X%)
**Source:** [GitHub Issue #X / SO Answer / Docs]

**The Fix:**
```[language]
// Code change or configuration
```

**Why This Works:**
[Explanation of why this solves the root cause]

**Implementation Steps:**
1. [ ] [Step 1]
2. [ ] [Step 2]
3. [ ] [Step 3]

**Rollback Plan:**
[How to revert if this doesn't work]

### Alternative Solutions
| Alternative | Confidence | Trade-offs |
|-------------|------------|------------|
| [Option B] | X% | [Pros/Cons] |
| [Option C] | X% | [Pros/Cons] |

### If No External Solution Found
→ This is likely app-specific. Proceed to `/bug-investigation` for internal root cause analysis.
```

### 6. **Handoff to Bug Investigation**

If external research doesn't fully solve the issue:

```markdown
## Handoff to Internal Investigation

### External Research Summary
- **Hypotheses Tested:** [List]
- **Hypotheses Eliminated:** [List]
- **Remaining Hypotheses:** [For internal investigation]

### Context for Bug Investigation
- **Not a Known Issue:** [External research found nothing]
- **Partial Solution:** [External fix + internal changes needed]
- **Our Implementation:** [Known issue, but our usage is different]

### Recommended Focus Areas
Based on external research, focus internal investigation on:
1. [Specific area of codebase]
2. [Specific integration point]
3. [Specific configuration]

→ Run: `/bug-investigation $ARGUMENTS`
```

---

## Integration with Other Commands

### Workflow: Unknown Problem
```
1. /problem-solver [error]     → External research
2. /bug-investigation [JIRA]   → Internal root cause (if needed)
3. /self-review                → Before PR
```

### Workflow: Dependency Issue
```
1. /problem-solver [error]     → Find known solution
2. Apply fix
3. /self-review                → Verify fix
```

### Workflow: App Logic Bug
```
1. /problem-solver [error]     → Quick check (optional)
2. /bug-investigation [JIRA]   → Primary investigation
3. /self-review                → Before PR
```

---

## Output Templates

### Quick Research Summary
```markdown
# Problem Research: [Brief Description]

**Confidence:** [X]%
**Solution Found:** [Yes/Partial/No]

## TL;DR
[One paragraph summary of findings and recommended action]

## Key Findings
- [Finding 1]
- [Finding 2]

## Recommended Action
[Specific next step]

## Sources
- [Link 1]
- [Link 2]
```

### Full Research Report
Save to: `$REPORT_BASE/research/[ISSUE-ID]/research-report.md`

---

## Notes
- **Research-First**: Check external sources before diving into code
- **Confidence-Based**: Route to internal investigation if confidence < 60%
- **Hypothesis-Driven**: Form and test specific hypotheses
- **Source Diversity**: Use multiple source types for validation
- **Handoff-Ready**: Provides context for `/bug-investigation` if needed
