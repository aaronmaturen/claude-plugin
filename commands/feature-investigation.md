# Feature Investigation - UltraThink Implementation Analysis

Investigate and plan the implementation of a new feature using comprehensive analysis across multiple repositories (frontend/backend), then create a detailed implementation plan.

**Feature Request:** $ARGUMENTS (JIRA issue key or feature description)

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

## Executive Summary

### Feature Overview
[Clear description of what we're building and why]

### Business Value
- **User Benefit:** [How this helps users]
- **Business Impact:** [Revenue/efficiency gains]
- **Strategic Alignment:** [How it fits company goals]

### Scope
- **In Scope:** [What we will build]
- **Out of Scope:** [What we won't build]
- **Future Considerations:** [What might come later]

## Feature Details

### User Stories
[List key user stories with As a/I want to/So that format]

### Acceptance Criteria
[Checkboxes for measurable criteria]

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

### Frontend Tasks
[Components Development - FE-xxx tasks with story points]
[State Management - FE-xxx tasks with story points]
[API Integration - FE-xxx tasks with story points]
[Testing - FE-xxx tasks with story points]

### Backend Tasks
[API Development - BE-xxx tasks with story points]
[Database - BE-xxx tasks with story points]
[Business Logic - BE-xxx tasks with story points]
[Testing - BE-xxx tasks with story points]

### DevOps Tasks
[Infrastructure - DO-xxx tasks with story points]
[Deployment - DO-xxx tasks with story points]

### Documentation Tasks
[DOC-xxx tasks with story points]

## Task Dependencies
[Mermaid diagram showing task dependencies - generate in report]

## Story Point Summary
- **Frontend:** [X] points
- **Backend:** [Y] points
- **DevOps:** [Z] points
- **Documentation:** [W] points
- **Total:** [Total] points

## Sprint Allocation
[Sprint breakdown with point allocation]
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

## Notes:
- Focuses on planning new features rather than investigating bugs
- Includes comprehensive technical design documentation
- Creates detailed task breakdowns with story points
- Handles multi-repository feature planning
- Includes architecture diagrams and user flows
- Provides phased implementation approach
- Includes risk analysis and mitigation strategies
- Creates sprint planning and team allocation
- Generates monitoring and rollout strategies
- Links to design mockups and specifications
- Provides clear success criteria and DoD