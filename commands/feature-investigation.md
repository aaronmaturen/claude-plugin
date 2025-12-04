# Feature Investigation - AC-Driven Implementation Planning

Investigate and plan the implementation of a new feature with **Acceptance Criteria as the central organizing principle**. Every task, test, and verification ties back to specific AC.

**Feature Request:** $ARGUMENTS (JIRA issue key or feature description)

## Philosophy: AC-First Development

**Why features fail:** Acceptance criteria get buried in documentation, forgotten during implementation, and only remembered during QA when it's expensive to fix.

**This command ensures:**
1. AC are validated and clarified BEFORE any planning
2. Every task links to specific AC
3. Checkpoints verify AC progress throughout development
4. PR checklist explicitly maps to AC

## Investigation Process:

### 0. **Check for Previous Feature Planning**
```bash
# Setup report directory structure and check for existing planning
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
FEATURE_ID="$ARGUMENTS"
FEATURE_DIR="${REPORT_BASE}/features/${FEATURE_ID}"
PLAN_FILE="${FEATURE_DIR}/implementation-plan.md"
DESIGN_FILE="${FEATURE_DIR}/technical-design.md"
TASKS_FILE="${FEATURE_DIR}/task-breakdown.md"

# Check if we have previous planning for this feature
if [[ -f "$PLAN_FILE" ]]; then
    echo "🔍 Found previous planning for $FEATURE_ID"
    echo "📁 Location: $FEATURE_DIR"
    echo ""
    echo "=== Previous Planning Summary ==="
    
    # Extract key information from previous planning
    if grep -q "## Executive Summary" "$PLAN_FILE"; then
        echo "📋 Previous Analysis:"
        sed -n '/## Executive Summary/,/## Feature Details/p' "$PLAN_FILE" | head -n -1
        echo ""
    fi
    
    if grep -q "## Implementation Approach" "$PLAN_FILE"; then
        echo "🎯 Previous Implementation Strategy:"
        sed -n '/## Implementation Approach/,/## Technical Design/p' "$PLAN_FILE" | head -n -1
        echo ""
    fi
    
    # Check planning status
    LAST_MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$PLAN_FILE" 2>/dev/null || date -r "$PLAN_FILE" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
    echo "📅 Last Planning Session: $LAST_MODIFIED"
    
    # Check if there are incomplete tasks
    if grep -q "### Sprint Planning" "$PLAN_FILE"; then
        echo "📝 Outstanding Tasks:"
        grep -A 20 "### Sprint Planning" "$PLAN_FILE" | grep "^- \[ \]" | head -5 || echo "   (All completed or none found)"
        echo ""
    fi
    
    echo "==========================================="
    echo "💭 Claude: Based on previous planning above, I can either:"
    echo "   A) Continue refining the existing plan with new insights"
    echo "   B) Start fresh planning (previous plans will be backed up)"
    echo ""
    echo "📖 Previous plan available at: $PLAN_FILE"
    echo "🏗️ Technical design available at: $DESIGN_FILE"
    echo "📝 Task breakdown available at: $TASKS_FILE"
    echo ""
    echo "🤔 Please specify how you'd like to proceed with this feature planning."
    echo ""
else
    echo "🆕 No previous planning found for $FEATURE_ID"
    echo "📁 Will create new planning at: $FEATURE_DIR"
    echo "🔍 Starting fresh feature investigation..."
    echo ""
fi
```

### 1. **Fetch Feature Details from JIRA**
```bash
# Get feature details using jira CLI if it's a JIRA ticket
if [[ "$FEATURE_ID" =~ ^[A-Z]+-[0-9]+$ ]]; then
    jira issue view "$FEATURE_ID" --output json > /tmp/feature_details.json
    
    # Extract key information
    SUMMARY=$(jq -r '.fields.summary' /tmp/feature_details.json)
    DESCRIPTION=$(jq -r '.fields.description' /tmp/feature_details.json)
    REPORTER=$(jq -r '.fields.reporter.displayName' /tmp/feature_details.json)
    CREATED=$(jq -r '.fields.created' /tmp/feature_details.json)
    PRIORITY=$(jq -r '.fields.priority.name' /tmp/feature_details.json)
    STATUS=$(jq -r '.fields.status.name' /tmp/feature_details.json)
    COMPONENTS=$(jq -r '.fields.components[].name' /tmp/feature_details.json 2>/dev/null || echo "None")
    LABELS=$(jq -r '.fields.labels[]' /tmp/feature_details.json 2>/dev/null || echo "None")
    ACCEPTANCE_CRITERIA=$(jq -r '.fields.customfield_10100' /tmp/feature_details.json 2>/dev/null || echo "To be defined")
    
    # Get comments for additional context
    jira issue comment list "$FEATURE_ID" --output json > /tmp/feature_comments.json
else
    echo "📝 Feature description provided directly (not a JIRA ticket)"
    SUMMARY="$FEATURE_ID"
    DESCRIPTION="Feature to be investigated and planned"
fi

# Determine affected repositories based on feature scope
REPOS_AFFECTED=""
if [[ "$DESCRIPTION" =~ "UI" ]] || [[ "$DESCRIPTION" =~ "frontend" ]] || [[ "$LABELS" =~ "edu-clients" ]]; then
    REPOS_AFFECTED="$REPOS_AFFECTED edu-clients"
fi
if [[ "$DESCRIPTION" =~ "API" ]] || [[ "$DESCRIPTION" =~ "backend" ]] || [[ "$LABELS" =~ "api-workplace" ]]; then
    REPOS_AFFECTED="$REPOS_AFFECTED api-workplace"
fi
```

### 1.5 **GATE: Acceptance Criteria Validation** (CRITICAL)

**⚠️ STOP HERE if AC are missing or unclear. Do not proceed to planning.**

This is the most important step. Poor AC = wasted development time.

#### Extract and Display AC
```bash
echo "═══════════════════════════════════════════════════════════════"
echo "                 ACCEPTANCE CRITERIA REVIEW                     "
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [[ -n "$ACCEPTANCE_CRITERIA" ]] && [[ "$ACCEPTANCE_CRITERIA" != "null" ]] && [[ "$ACCEPTANCE_CRITERIA" != "To be defined" ]]; then
    echo "📋 Acceptance Criteria from JIRA:"
    echo "─────────────────────────────────"
    echo "$ACCEPTANCE_CRITERIA"
    echo ""
else
    echo "⚠️  NO ACCEPTANCE CRITERIA FOUND IN JIRA"
    echo ""
    echo "Before proceeding, we MUST define AC. Ask the product owner or define them now."
    echo ""
fi

echo "═══════════════════════════════════════════════════════════════"
```

#### AC Quality Checklist

**Claude, evaluate each AC against these criteria:**

| Quality Check | Pass? | Issue |
|---------------|-------|-------|
| **Specific** - Is it clear what "done" looks like? | | |
| **Measurable** - Can we write a test for it? | | |
| **Achievable** - Is it technically feasible? | | |
| **Relevant** - Does it tie to user value? | | |
| **Testable** - Can QA verify it? | | |

#### AC Clarification Questions

**For each unclear AC, generate clarifying questions:**

```markdown
## AC Clarification Needed

### AC 1: "[Original AC text]"
❓ Questions:
- [What specific behavior is expected?]
- [What are the edge cases?]
- [How should errors be handled?]

### AC 2: "[Original AC text]"
❓ Questions:
- [...]
```

#### Missing AC Detection

**Check for common missing AC:**
- [ ] Error handling - What happens when things fail?
- [ ] Loading states - What does the user see while waiting?
- [ ] Empty states - What if there's no data?
- [ ] Permissions - Who can access this?
- [ ] Mobile/responsive - Does it need to work on mobile?
- [ ] Accessibility - Any a11y requirements?
- [ ] Performance - Any speed requirements?
- [ ] Analytics - What events need tracking?

#### AC Refinement Output

**Create a canonical AC list with IDs for tracking:**

```markdown
## Refined Acceptance Criteria

### Functional Requirements
- **AC-1**: [Clear, testable criterion]
  - Test: [How to verify]
  - Edge cases: [What to watch for]

- **AC-2**: [Clear, testable criterion]
  - Test: [How to verify]
  - Edge cases: [What to watch for]

### Non-Functional Requirements
- **AC-NFR-1**: [Performance/security/accessibility criterion]
  - Test: [How to verify]
  - Threshold: [Specific number if applicable]

### Out of Scope (Explicitly)
- [Thing that might be assumed but isn't included]
```

**⚠️ CHECKPOINT: Before proceeding, confirm:**
1. All AC are clear and testable
2. Missing AC have been identified and added
3. Clarifying questions have been answered (or noted for follow-up)

---

### 2. **Feature Analysis & Scoping**
- Parse feature requirements and acceptance criteria
- Identify affected components/services (Frontend vs Backend vs Full-Stack)
- Determine user personas and use cases
- Analyze business value and impact
- Identify dependencies and constraints
- Research similar existing features in codebase

### 3. **Multi-Repository Investigation Strategy**

#### Codebase Analysis
```bash
# Check which repositories we have access to locally
CURRENT_REPO=$(basename $(git rev-parse --show-toplevel 2>/dev/null) || echo "none")
echo "Current repository: $CURRENT_REPO"

# Define repository paths (adjust based on your setup)
EDU_CLIENTS_PATH="${EDU_CLIENTS_PATH:-../edu-clients}"
API_WORKPLACE_PATH="${API_WORKPLACE_PATH:-../api-workplace}"

# Check availability
HAVE_EDU_CLIENTS=false
HAVE_API_WORKPLACE=false

if [[ -d "$EDU_CLIENTS_PATH/.git" ]]; then
    HAVE_EDU_CLIENTS=true
    echo "✓ Found edu-clients at: $EDU_CLIENTS_PATH"
fi

if [[ -d "$API_WORKPLACE_PATH/.git" ]]; then
    HAVE_API_WORKPLACE=true
    echo "✓ Found api-workplace at: $API_WORKPLACE_PATH"
fi
```

#### Implementation Research

**A. When Both Repos Are Available:**
- Search for similar features to use as templates
- Analyze existing patterns and conventions
- Check API endpoints that might be extended
- Review component libraries and design system
- Identify reusable services and utilities

**B. When Only One Repo Is Available:**
- Deep dive into available repo architecture
- For missing repo, document assumptions:
  - Expected API contracts
  - Data models needed
  - Integration points
  - Security considerations

**C. When Neither Repo Is Available:**
- Work from feature requirements
- Document needed research:
  - Architecture patterns to follow
  - Technology stack constraints
  - Performance requirements
  - Scalability considerations

### 4. **Cross-Repository Design Analysis**

#### Frontend (edu-clients) Planning:
- **User Interface**: Component hierarchy and state management
- **User Experience**: Flow diagrams and interaction patterns
- **API Integration**: Required endpoints and data contracts
- **Performance**: Loading strategies and optimizations
- **Accessibility**: WCAG compliance requirements

#### Backend (api-workplace) Planning:
- **API Design**: RESTful endpoints or GraphQL schema
- **Data Models**: Database schema and relationships
- **Business Logic**: Service layer architecture
- **Security**: Authentication and authorization
- **Performance**: Caching and query optimization

#### Integration Planning:
- **API Contract**: Request/response specifications
- **Error Handling**: Failure scenarios and recovery
- **Data Validation**: Client and server-side rules
- **Testing Strategy**: Integration test approach
- **Deployment**: Feature flags and rollout plan

### 5. **Technical Design Deep Dive**

#### Architecture Considerations
- **Scalability**: How will this feature scale?
- **Performance**: Expected load and response times
- **Security**: Threat model and mitigation
- **Maintainability**: Code organization and documentation
- **Monitoring**: Metrics and alerting needs

#### Design Patterns
- Identify applicable design patterns
- Review company/team conventions
- Consider SOLID principles
- Plan for extensibility

#### Technology Decisions
- Framework features to leverage
- Third-party libraries needed
- Build vs buy analysis
- Technical debt considerations

### 6. **Implementation Planning**

#### Phase 1: Foundation
- Core data models
- Basic API endpoints
- Minimal UI components
- Unit test structure

#### Phase 2: Core Features
- Complete business logic
- Full UI implementation
- Integration tests
- Error handling

#### Phase 3: Polish
- Performance optimization
- Enhanced UX features
- Comprehensive testing
- Documentation

#### Phase 4: Launch Preparation
- Feature flags setup
- Monitoring configuration
- Rollout planning
- Team training

### 7. **Generate/Update Documentation**

```bash
# Report structure already set up in step 0
mkdir -p "$FEATURE_DIR"

# If continuing from previous planning, backup existing files
if [[ -f "$PLAN_FILE" ]] && [[ "$CONTINUE_FROM_PREVIOUS" = true ]]; then
    BACKUP_DIR="${FEATURE_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$PLAN_FILE" "$BACKUP_DIR/implementation-plan.md" 2>/dev/null || true
    cp "$DESIGN_FILE" "$BACKUP_DIR/technical-design.md" 2>/dev/null || true
    cp "$TASKS_FILE" "$BACKUP_DIR/task-breakdown.md" 2>/dev/null || true
    echo "📁 Previous planning backed up to: $BACKUP_DIR"
fi
```

#### Main Implementation Plan:
```markdown
# Feature Implementation Plan: [[FEATURE_ID]]

**Feature:** [Summary]
**Planning Date:** [Date]
**Priority:** [Priority]
**Target Release:** [Version/Sprint]

---
## 🎯 ACCEPTANCE CRITERIA (Keep Visible Throughout Development)

> **⚠️ This section is the source of truth. Every task, test, and PR must trace back here.**

### Functional Requirements
| ID | Criterion | Status | Verified By |
|----|-----------|--------|-------------|
| AC-1 | [Criterion] | ⬜ Not Started | |
| AC-2 | [Criterion] | ⬜ Not Started | |
| AC-3 | [Criterion] | ⬜ Not Started | |

### Non-Functional Requirements
| ID | Criterion | Threshold | Status |
|----|-----------|-----------|--------|
| AC-NFR-1 | [Performance criterion] | [e.g., < 200ms] | ⬜ |
| AC-NFR-2 | [Accessibility criterion] | [e.g., WCAG AA] | ⬜ |

### Status Legend
- ⬜ Not Started
- 🔨 In Progress
- ✅ Implemented
- ✔️ Verified (tested and confirmed)

---

## Executive Summary

### Feature Overview
[Clear description of what we're building and why]

### Business Value
- **User Benefit:** [How this helps users]
- **Business Impact:** [Revenue/efficiency gains]
- **Strategic Alignment:** [How it fits company goals]

### Scope
- **In Scope:** [What we will build]
- **Out of Scope:** [What we won't build - be explicit!]
- **Future Considerations:** [What might come later]

## Feature Details

### User Stories
[List key user stories with As a/I want to/So that format]

### Success Metrics
[How we'll measure success - adoption, performance, quality]

## Implementation Approach

### High-Level Architecture
[Mermaid diagram placeholder - generate detailed diagram in report]

### Technology Stack
- **Frontend:** [Technologies]
- **Backend:** [Technologies]
- **Database:** [Technologies]
- **Infrastructure:** [Details]

## Technical Design

### Frontend Architecture
[Component structure, state management approach, API integration strategy]

### Backend Architecture
[API design approach, data models overview, business logic organization]

### Integration Points
[API contracts, error handling, data validation]

## Implementation Phases

### Phase 1: Foundation
[Core infrastructure tasks with checkboxes]

### Phase 2: Core Features
[Main feature development tasks with checkboxes]

### Phase 3: Enhancement
[Polish and optimization tasks with checkboxes]

### Phase 4: Launch Prep
[Deployment and monitoring setup with checkboxes]

## Risk Analysis

### Technical Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
[List key technical risks]

### Dependencies
[List external dependencies and prerequisites]

## Testing Strategy

### Test Coverage Goals
[Unit, integration, and E2E coverage targets]

### Test Plan
[High-level testing approach by type]

## Rollout Strategy

### Feature Flags
[Feature flag configuration approach]

### Rollout Phases
[Phased rollout plan from internal to full release]

## Success Criteria

### Definition of Done
[Checklist of completion requirements]

### Launch Criteria
[Checklist of launch readiness requirements]

## Related Resources
[Links to design mockups, API specs, test plans, similar features]

---

**Planning Complete:** [Date/Time]
**Next Review:** [Date]
```

#### Technical Design Document:
```markdown
# Technical Design: [[FEATURE_ID]]

## System Architecture
[Component diagram with mermaid - generate detailed version in report]
[Sequence diagrams for key flows]
[Data flow diagrams]

## API Specification
[Detailed endpoint documentation with request/response schemas]
[Data models and relationships]
[Error codes and handling]

## Security Design
[Authentication flow and token management]
[Authorization model and permission checks]
[Data protection and encryption measures]

## Performance Design
[Caching strategy and TTLs]
[Database optimization and indexes]
[Scaling and load handling approach]

## Deployment Architecture
[Infrastructure requirements and cloud resources]
[CI/CD pipeline and deployment process]
[Monitoring, metrics, and alerting setup]
```

#### Task Breakdown:
```markdown
# Task Breakdown: [[FEATURE_ID]]

## Epic: [Feature Name]

---
## 🎯 AC-to-Task Mapping

> **Every task must link to at least one AC. If a task doesn't serve an AC, question if it's needed.**

| AC ID | Criterion | Tasks | Test Tasks |
|-------|-----------|-------|------------|
| AC-1 | [Criterion] | FE-001, BE-001 | TEST-001 |
| AC-2 | [Criterion] | FE-002, FE-003, BE-002 | TEST-002 |
| AC-3 | [Criterion] | BE-003 | TEST-003 |
| AC-NFR-1 | [Performance] | BE-004 | PERF-001 |

---

### Frontend Tasks

| Task | Description | AC | Points | Depends On |
|------|-------------|-----|--------|------------|
| FE-001 | [Description] | AC-1 | 3 | - |
| FE-002 | [Description] | AC-2 | 2 | FE-001 |
| FE-003 | [Description] | AC-2 | 2 | FE-001 |
| FE-TEST-001 | Unit tests for AC-1 | AC-1 | 2 | FE-001 |
| FE-TEST-002 | Integration tests for AC-2 | AC-2 | 2 | FE-002, FE-003 |

### Backend Tasks

| Task | Description | AC | Points | Depends On |
|------|-------------|-----|--------|------------|
| BE-001 | [Description] | AC-1 | 3 | - |
| BE-002 | [Description] | AC-2 | 3 | BE-001 |
| BE-003 | [Description] | AC-3 | 2 | - |
| BE-TEST-001 | API tests for AC-1 | AC-1 | 2 | BE-001 |

### DevOps Tasks

| Task | Description | AC | Points |
|------|-------------|-----|--------|
| DO-001 | Feature flag setup | ALL | 1 |
| DO-002 | Monitoring for [metric] | AC-NFR-1 | 2 |

## Task Dependencies
[Mermaid diagram showing task dependencies - generate in report]

## Story Point Summary
- **Frontend:** [X] points
- **Backend:** [Y] points
- **DevOps:** [Z] points
- **Testing:** [T] points
- **Total:** [Total] points

## Sprint Allocation
[Sprint breakdown with point allocation]

---
## AC Coverage Check

**Before starting each sprint, verify:**
- [ ] Every AC has at least one implementation task
- [ ] Every AC has at least one test task
- [ ] No orphan tasks (tasks without AC linkage)
```

#### PR Checklist Template:

**Generate this file for use during PR review:**

```markdown
# PR Checklist: [[FEATURE_ID]] - [PR Title]

## 🎯 Acceptance Criteria Verification

**This PR addresses the following AC:**

| AC ID | Criterion | Implemented | Test Added | Manually Verified |
|-------|-----------|-------------|------------|-------------------|
| AC-1 | [Criterion] | ⬜ | ⬜ | ⬜ |
| AC-2 | [Criterion] | ⬜ | ⬜ | ⬜ |

## Pre-Merge Checklist

### Code Quality
- [ ] Code follows project conventions
- [ ] No unnecessary changes outside feature scope
- [ ] Error handling covers edge cases from AC

### Testing
- [ ] Unit tests cover happy path for each AC
- [ ] Unit tests cover error cases for each AC
- [ ] Integration tests added (if applicable)
- [ ] Manual testing completed for each AC

### AC-Specific Verification

#### AC-1: [Criterion]
- [ ] Implemented as specified
- [ ] Test proves it works: [link to test or describe]
- [ ] Edge case handled: [describe]

#### AC-2: [Criterion]
- [ ] Implemented as specified
- [ ] Test proves it works: [link to test or describe]
- [ ] Edge case handled: [describe]

### Non-Functional Requirements
- [ ] AC-NFR-1: [Performance] - Measured: [result]
- [ ] AC-NFR-2: [Accessibility] - Verified: [how]

## Remaining AC (if partial PR)
| AC ID | Status | Planned PR |
|-------|--------|------------|
| AC-3 | Not started | PR #XXX |

## Screenshots/Videos (if UI changes)
[Attach evidence of AC being met]
```

### 8. **Create Visual Diagrams**
Generate Excalidraw diagrams for:
- Feature architecture overview
- User flow diagrams
- Component hierarchy
- API sequence diagrams
- Deployment topology

## Example Usage:
```
Command: /feature-investigation PROJ-5678

Output:
🆕 No previous planning found for PROJ-5678
📁 Will create new planning at: ~/Documents/technical-analysis/features/PROJ-5678

✓ Feature retrieved: "Add real-time collaboration to document editor"
✓ Priority: High | Components: Frontend, API, WebSocket
✓ Found edu-clients and api-workplace repositories

Analyzing codebase...
✓ WebSocket infrastructure exists
✓ Editor component found
✓ Redis pub/sub available

Creating implementation plan...

Feature Breakdown:
- Frontend: Real-time cursor tracking, conflict resolution
- Backend: WebSocket rooms, operational transform
- Infrastructure: Redis pub/sub, horizontal scaling

Implementation Phases: 4 phases over 8 weeks
Team needed: 2 FE, 2 BE developers
Complexity: High (WebSocket, real-time sync, conflict resolution)

Generating documentation...
✓ Implementation plan: ~/Documents/technical-analysis/features/PROJ-5678/implementation-plan.md
✓ Technical design: ~/Documents/technical-analysis/features/PROJ-5678/technical-design.md
✓ Task breakdown: ~/Documents/technical-analysis/features/PROJ-5678/task-breakdown.md

View complete plan in report directory.
```

---

## Development Checkpoints (Use During Implementation)

### Checkpoint 1: Before Starting Any Task
```
🎯 AC Check:
- Which AC does this task address? [AC-X]
- What does "done" look like for this AC?
- What test will prove this AC is met?
```

### Checkpoint 2: Before Creating a PR
```
🎯 PR Readiness Check:
- [ ] I can identify which AC this PR addresses
- [ ] I have a test for each AC in this PR
- [ ] I have manually verified each AC works
- [ ] I have updated AC status in implementation-plan.md
```

### Checkpoint 3: Before Merging
```
🎯 Merge Gate:
- [ ] All AC in this PR are marked ✅ Implemented
- [ ] Reviewer has verified AC implementation
- [ ] No AC regression in existing functionality
```

### Checkpoint 4: Before Feature Release
```
🎯 Release Gate:
- [ ] ALL AC are marked ✔️ Verified
- [ ] QA has signed off on each AC
- [ ] No outstanding clarification questions
- [ ] Performance thresholds met (AC-NFR-*)
```

---

## Quick Reference: AC Status Updates

**During development, keep the AC table updated:**

```bash
# In implementation-plan.md, update AC status:
# ⬜ Not Started → 🔨 In Progress → ✅ Implemented → ✔️ Verified

# Example:
| AC-1 | User can login with email | ✅ Implemented | FE-001, BE-001 |
| AC-2 | Error shown for invalid creds | 🔨 In Progress | |
```

---

## Notes:
- **AC-First**: Every planning decision traces back to acceptance criteria
- **Checkpoints**: Built-in gates prevent missing AC during development
- **PR Checklist**: Generated template ensures AC verification before merge
- **Task Mapping**: Every task links to specific AC (no orphan work)
- Handles multi-repository feature planning
- Includes risk analysis and mitigation strategies
- Generates monitoring and rollout strategies

## Key Differences from Standard Planning:
1. **Gate at Step 1.5** - Won't proceed without clear AC
2. **AC Table at Top** - Always visible, not buried in docs
3. **AC-to-Task Mapping** - Every task justifies its existence
4. **PR Checklist Template** - Forces AC verification before merge
5. **Development Checkpoints** - Reminders during implementation