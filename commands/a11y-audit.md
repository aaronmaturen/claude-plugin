---
description: "Audit a frontend application for WCAG 2.1/2.2 compliance, screen reader compatibility, keyboard accessibility, and inclusive design patterns."
argument-hint: "[app-path]"
---
# Accessibility Audit

Audit a frontend application for WCAG 2.1/2.2 compliance, screen reader compatibility, keyboard accessibility, and inclusive design patterns.

**Usage:**
- `/a11y-audit` - Full audit of current directory
- `/a11y-audit /path/to/app` - Full audit of specified path
- `/a11y-audit --branch` or `-b` - Audit only files changed in current branch
- `/a11y-audit --branch /path/to/app` - Branch audit in specified path

## Audit Philosophy

This audit focuses on **real user impact**. The goal is identifying:
- Barriers that prevent users from completing tasks
- Issues that degrade the experience for assistive technology users
- Quick wins that dramatically improve accessibility
- Patterns that need redesign vs. simple fixes

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

For accessibility audits:
- **WCAG Impact Level**: Does this violate Level A (critical), AA (standard), or AAA (enhanced) success criteria?
- **User Group Affected**: How many users does this block (e.g., all keyboard users vs. specific screen reader edge case)?
- **Task Completion Impact**: Does this prevent task completion, degrade experience, or cause minor inconvenience?
- **Certainty of Issue**: Can this be verified through code inspection, or does it require manual testing to confirm?

## Common Setup

This audit uses the standard branch-mode pattern. The setup below:
1. Parses `--branch` / `-b` flags
2. Identifies changed files when in branch mode
3. Creates `search_files()` helper for consistent searching
4. Detects relevant framework/tooling

**Note:** This pattern is consistent across all audit commands for maintainability.

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

    # Get changed files (relevant to a11y)
    CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null | grep -E '\.(html|tsx|jsx|ts|js|scss|css|vue|svelte)$')

    if [[ -z "$CHANGED_FILES" ]]; then
        echo "⚠️  No relevant files changed compared to $BASE_BRANCH"
        echo "   (Looking for: .html, .tsx, .jsx, .ts, .js, .scss, .css, .vue, .svelte)"
        echo ""
        echo "   Either:"
        echo "   - Run without --branch for full audit"
        echo "   - Make changes to UI files on this branch"
        exit 0
    fi

    echo "🌿 BRANCH MODE: Auditing only files changed in current branch"
    echo "   Branch: $CURRENT_BRANCH"
    echo "   Comparing to: $BASE_BRANCH"
    echo "   Files to audit: $(echo "$CHANGED_FILES" | wc -l | tr -d ' ')"
    echo ""
    echo "   Changed files:"
    echo "$CHANGED_FILES" | sed 's/^/   - /'
    echo ""

    # Create temp file with changed files for grep
    CHANGED_FILES_LIST=$(mktemp)
    echo "$CHANGED_FILES" > "$CHANGED_FILES_LIST"

    # Helper function for branch-aware searching
    search_files() {
        local pattern="$1"
        local file_pattern="${2:-}"  # Optional: .html, .ts, etc.

        if [[ -n "$file_pattern" ]]; then
            echo "$CHANGED_FILES" | grep -E "$file_pattern" | xargs grep -n "$pattern" 2>/dev/null
        else
            echo "$CHANGED_FILES" | xargs grep -n "$pattern" 2>/dev/null
        fi
    }

    # Count matches in branch mode
    count_matches() {
        local pattern="$1"
        local file_pattern="${2:-}"

        if [[ -n "$file_pattern" ]]; then
            echo "$CHANGED_FILES" | grep -E "$file_pattern" | xargs grep -c "$pattern" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}'
        else
            echo "$CHANGED_FILES" | xargs grep -c "$pattern" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}'
        fi
    }
else
    echo "📂 Full audit mode: $APP_PATH"

    # Full mode search helper
    search_files() {
        local pattern="$1"
        local file_pattern="${2:-\\.html$|\\.tsx$|\\.jsx$|\\.ts$|\\.js$|\\.scss$|\\.css$}"

        grep -rn "$pattern" --include="*.html" --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.scss" --include="*.css" "$APP_PATH/src" 2>/dev/null | grep -v node_modules
    }

    count_matches() {
        search_files "$1" "$2" | wc -l | tr -d ' '
    }
fi

# Detect framework
if [[ -f "$APP_PATH/angular.json" ]]; then
    echo "📦 Angular application detected"
    FRAMEWORK="angular"
elif [[ -f "$APP_PATH/package.json" ]]; then
    grep -q "react" "$APP_PATH/package.json" && echo "📦 React application detected" && FRAMEWORK="react"
    grep -q "vue" "$APP_PATH/package.json" && echo "📦 Vue application detected" && FRAMEWORK="vue"
fi

# Check for a11y tooling
grep -q "axe-core\|pa11y\|jest-axe" "$APP_PATH/package.json" 2>/dev/null && echo "✓ A11y testing tools detected"
grep -q "@angular/cdk" "$APP_PATH/package.json" 2>/dev/null && echo "✓ Angular CDK (includes a11y module) detected"
```

### 0.1 Eligibility Check (Quick - use haiku)

Before running a full audit, verify this audit is appropriate:

**Skip audit if:**
- No UI files exist (check for .html, .tsx, .jsx, .vue, .svelte files)
- Project is pure API/backend (no frontend framework detected)

If skipping, output: "⏭️ Skipping accessibility audit - [reason]. This project doesn't appear to need this audit."

```bash
# Quick check for UI files
UI_FILE_COUNT=$(find "$APP_PATH" -type f \( -name "*.html" -o -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" -o -name "*.svelte" \) -not -path "*/node_modules/*" -not -path "*/.venv/*" 2>/dev/null | wc -l | tr -d ' ')

if [[ "$UI_FILE_COUNT" -eq 0 ]]; then
    echo "⏭️ Skipping accessibility audit - no UI files found. This appears to be a pure API/backend project."
    exit 0
fi

echo "✓ Found $UI_FILE_COUNT UI files - proceeding with audit"
```

**Note on Branch Mode:** When using `--branch`, all grep commands below can be replaced with `branch_grep` to search only changed files. For example:
```bash
# Full audit:
grep -rn "<h1" --include="*.html" "$APP_PATH/src"

# Branch mode:
branch_grep "<h1"
```

### 0.5 **Parallel Agent Strategy**

To improve efficiency, spawn 3 parallel agents using the Task tool to audit different areas concurrently:

**Agent Configuration:**
- Use `Task` tool with `subagent_type="Explore"`
- Each agent runs independently on their assigned sections
- Agents score findings 0-100 based on user impact (0 = cosmetic, 100 = blocks core functionality)
- **Only report findings with score >= 80**

**Agent 1 (sonnet): Semantic HTML + Landmarks**
- Scope: Sections 1.1-1.3
- Focus: Heading hierarchy, landmark regions, semantic element usage
- Key issues: Missing `<main>`, skipped heading levels, interactive divs that should be buttons

**Agent 2 (sonnet): Keyboard + Focus + ARIA**
- Scope: Sections 4-5
- Focus: Keyboard navigation, focus management, ARIA attributes
- Key issues: Focus traps, tabindex anti-patterns, missing keyboard handlers, incorrect ARIA usage

**Agent 3 (sonnet): Forms + Images + Color**
- Scope: Sections 2-3, 6
- Focus: Form accessibility, image alt text, color contrast
- Key issues: Unlabeled inputs, missing alt text, color-only indicators

**Scoring Guidelines:**
- **90-100:** Blocks task completion for assistive tech users (e.g., form with no labels, keyboard trap)
- **80-89:** Major barrier causing significant degradation (e.g., missing landmarks, no focus indicators)
- **70-79:** Moderate issue, degraded experience (e.g., skipped heading levels, redundant ARIA)
- **<70:** Minor or cosmetic (don't report)

**Expected Output Format:**
Each agent returns a markdown table:

```markdown
## Agent [N] Findings (Score >= 80)

| Score | WCAG | Location | Issue | Fix | User Impact |
|-------|------|----------|-------|-----|-------------|
| 95 | 2.1.1 | LoginForm.tsx:45 | Submit div with onClick, no keyboard handler | Replace with <button> | Keyboard users cannot submit form |
| 85 | 1.3.1 | Header.tsx | No <main> landmark | Wrap content in <main> | Screen reader users cannot skip to content |
```

**Parallel Execution:**
```typescript
// Spawn all 3 agents simultaneously
Task("Agent 1: Audit sections 1.1-1.3 (Semantic HTML + Landmarks). Score findings 0-100. Only report score >= 80.", { subagent_type: "Explore" })
Task("Agent 2: Audit sections 4-5 (Keyboard + Focus + ARIA). Score findings 0-100. Only report score >= 80.", { subagent_type: "Explore" })
Task("Agent 3: Audit sections 2-3, 6 (Forms + Images + Color). Score findings 0-100. Only report score >= 80.", { subagent_type: "Explore" })
```

After all agents complete, consolidate their findings into the final report structure (Section 10).

### 1. **Semantic HTML Audit**

#### 1.1 Heading Structure

```bash
# Find heading usage
grep -rn "<h1\|<h2\|<h3\|<h4\|<h5\|<h6" --include="*.html" --include="*.tsx" --include="*.jsx" "$APP_PATH/src" | grep -v node_modules

# Count headings by level
for i in 1 2 3 4 5 6; do
    COUNT=$(grep -rn "<h$i" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | wc -l)
    echo "h$i: $COUNT"
done
```

**Check for:**
- Multiple `<h1>` per page (should be one)
- Skipped heading levels (h1 → h3 without h2)
- Headings used for styling instead of structure
- Non-heading elements styled as headings

#### 1.2 Landmark Regions

```bash
# Find landmark elements and roles
grep -rn "<main\|<nav\|<aside\|<header\|<footer\|<section\|role=\"main\"\|role=\"navigation\"\|role=\"banner\"\|role=\"contentinfo\"" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules
```

**Required landmarks:**
- `<main>` or `role="main"` - exactly one
- `<nav>` or `role="navigation"` - for navigation regions
- `<header>` or `role="banner"` - page header
- `<footer>` or `role="contentinfo"` - page footer

#### 1.3 Semantic Elements

```bash
# Find div/span with click handlers (should often be buttons)
grep -rn "div.*click\|span.*click\|<div.*onclick\|<span.*onclick" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | head -20

# Find divs with roles (check if native element would work)
grep -rn "role=\"button\"\|role=\"link\"\|role=\"checkbox\"\|role=\"tab\"" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules
```

### 2. **Image Accessibility**

#### 2.1 Alt Text Audit

```bash
# Find images
grep -rn "<img" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules

# Find images without alt
grep -rn "<img" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v "alt=" | grep -v node_modules

# Find empty alt (decorative) - verify these are truly decorative
grep -rn "alt=\"\"" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules
```

#### 2.2 Icon Accessibility

```bash
# Find icon usage (Material, FontAwesome, etc.)
grep -rn "mat-icon\|fa-\|<svg\|<i class=\"icon" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | head -30

# Check for aria-hidden on decorative icons
grep -rn "mat-icon\|<svg" --include="*.html" "$APP_PATH/src" | grep -v "aria-hidden\|aria-label" | grep -v node_modules | head -20
```

### 3. **Form Accessibility**

#### 3.1 Label Association

```bash
# Find form inputs
grep -rn "<input\|<select\|<textarea" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | wc -l

# Find inputs without labels (check for mat-label, aria-label, etc.)
grep -rn "<input" --include="*.html" "$APP_PATH/src" | grep -v "id=\|aria-label\|mat-label" | grep -v node_modules | head -20

# Find mat-form-field without mat-label
grep -rn "mat-form-field" -A 5 --include="*.html" "$APP_PATH/src" | grep -v "mat-label" | grep -v node_modules | head -20
```

#### 3.2 Error Handling

```bash
# Find error message patterns
grep -rn "mat-error\|error-message\|invalid\|aria-invalid\|aria-describedby" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | head -20

# Check for aria-invalid on inputs
grep -rn "aria-invalid" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules
```

#### 3.3 Required Fields

```bash
# Find required indicators
grep -rn "required\|aria-required" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | head -20
```

### 4. **Keyboard Accessibility**

#### 4.1 Focus Management

```bash
# Find tabindex usage
grep -rn "tabindex" --include="*.html" --include="*.tsx" --include="*.ts" "$APP_PATH/src" | grep -v node_modules

# Find tabindex > 0 (anti-pattern)
grep -rn "tabindex=\"[1-9]\|tabindex='[1-9]" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules

# Check for focus trapping in dialogs
grep -rn "cdkTrapFocus\|FocusTrap\|trapFocus" --include="*.html" --include="*.ts" "$APP_PATH/src" | grep -v node_modules
```

#### 4.2 Keyboard Event Handlers

```bash
# Find click without keyboard equivalent
grep -rn "(click)=\|onClick=" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | wc -l

# Find keydown/keyup handlers
grep -rn "keydown\|keyup\|keypress\|@HostListener.*key" --include="*.ts" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | wc -l
```

#### 4.3 Focus Visibility

```bash
# Check for focus styles
grep -rn ":focus\|:focus-visible\|:focus-within" --include="*.scss" --include="*.css" "$APP_PATH/src" | grep -v node_modules

# Check for outline: none (potential issue)
grep -rn "outline:\s*none\|outline:\s*0" --include="*.scss" --include="*.css" "$APP_PATH/src" | grep -v node_modules
```

### 5. **ARIA Usage**

#### 5.1 ARIA Attributes

```bash
# Find ARIA attribute usage
grep -rn "aria-" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | wc -l

# Common ARIA attributes
echo "=== ARIA Usage ==="
for attr in "aria-label" "aria-labelledby" "aria-describedby" "aria-hidden" "aria-live" "aria-expanded" "aria-selected" "aria-controls"; do
    COUNT=$(grep -rn "$attr" --include="*.html" --include="*.tsx" "$APP_PATH/src" | grep -v node_modules | wc -l)
    echo "$attr: $COUNT"
done
```

#### 5.2 Live Regions

```bash
# Find live regions
grep -rn "aria-live\|role=\"alert\"\|role=\"status\"\|LiveAnnouncer" --include="*.html" --include="*.ts" "$APP_PATH/src" | grep -v node_modules
```

### 6. **Color & Contrast**

#### 6.1 Color Usage

```bash
# Find color definitions (manual contrast check needed)
grep -rn "color:\|background-color:\|background:" --include="*.scss" --include="*.css" "$APP_PATH/src" | grep -v node_modules | grep -v "var(--" | head -30

# Check for CSS variables (good pattern)
grep -rn "var(--" --include="*.scss" --include="*.css" "$APP_PATH/src" | grep -v node_modules | wc -l
```

#### 6.2 Color-Only Indicators

```bash
# Find status/state classes that might rely on color alone
grep -rn "error\|success\|warning\|danger\|invalid\|valid" --include="*.scss" --include="*.css" "$APP_PATH/src" | grep "color:" | grep -v node_modules | head -20
```

### 7. **Motion & Animation**

```bash
# Find animations/transitions
grep -rn "animation:\|transition:\|@keyframes" --include="*.scss" --include="*.css" "$APP_PATH/src" | grep -v node_modules | wc -l

# Check for prefers-reduced-motion
grep -rn "prefers-reduced-motion" --include="*.scss" --include="*.css" "$APP_PATH/src" | grep -v node_modules
```

### 8. **Touch & Mobile**

```bash
# Find touch target sizing
grep -rn "min-width:\|min-height:\|padding:" --include="*.scss" --include="*.css" "$APP_PATH/src" | grep -v node_modules | head -20

# Check for touch-action
grep -rn "touch-action" --include="*.scss" --include="*.css" "$APP_PATH/src" | grep -v node_modules
```

### 9. **Automated Testing**

```bash
# Check for a11y testing setup
grep -rn "axe\|pa11y\|jest-axe\|cypress-axe" --include="*.ts" --include="*.js" --include="*.json" "$APP_PATH" | grep -v node_modules | head -10

# Find a11y tests
grep -rln "toHaveNoViolations\|checkA11y\|injectAxe" --include="*.spec.ts" --include="*.test.ts" "$APP_PATH/src" | grep -v node_modules
```

### 10. **Generate Report**

```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
AUDIT_DIR="${REPORT_BASE}/audits/a11y-$(basename $APP_PATH)-$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"
```

#### Report Structure:

```markdown
# Accessibility Audit Report

**Application:** [App Name]
**Date:** [Audit Date]
**WCAG Target:** 2.1 Level AA
**Framework:** [Angular/React/Vue]

## Executive Summary

### Accessibility Score: [A-F]

| Category | Score | Critical Issues |
|----------|-------|-----------------|
| Semantic HTML | | |
| Keyboard Access | | |
| Screen Reader | | |
| Visual Design | | |
| Forms | | |

### Impact Summary

| Severity | Count | User Impact |
|----------|-------|-------------|
| Critical | | Blocks task completion |
| Serious | | Major barrier |
| Moderate | | Degraded experience |
| Minor | | Inconvenience |

## Detailed Findings

### 1. Semantic HTML

#### Heading Structure
**Status:** [Good/Needs Work/Critical]

Issues found:
| Location | Issue | WCAG | Fix |
|----------|-------|------|-----|
| | | 1.3.1 | |

#### Landmarks
- [ ] `<main>` present: [Yes/No]
- [ ] `<nav>` labeled: [Yes/No]
- [ ] `<header>` present: [Yes/No]

### 2. Images & Icons

#### Missing Alt Text
| File | Element | Recommendation |
|------|---------|----------------|
| | | |

#### Decorative Images
Verify these are truly decorative:
| File | Element |
|------|---------|
| | |

### 3. Forms

#### Label Association
| Form | Field | Issue | Fix |
|------|-------|-------|-----|
| | | Missing label | Add mat-label |

#### Error Handling
- [ ] Errors announced to screen readers: [Yes/No]
- [ ] Error messages associated with fields: [Yes/No]
- [ ] Visual + text error indication: [Yes/No]

### 4. Keyboard Accessibility

#### Focus Issues
| Component | Issue | Fix |
|-----------|-------|-----|
| | No visible focus | Add :focus-visible styles |
| | Focus trap missing | Add cdkTrapFocus |

#### Interactive Elements
- Total click handlers: [X]
- With keyboard support: [Y]
- Gap: [X-Y] elements need keyboard access

### 5. ARIA Usage

#### Live Regions
- [ ] Dynamic content announced: [Yes/No]
- [ ] LiveAnnouncer used: [Yes/No]

#### Common Issues
| Pattern | Count | Issue |
|---------|-------|-------|
| aria-label on div | | Consider semantic element |
| Missing aria-expanded | | Add to expandable elements |

### 6. Color & Contrast

#### Contrast Issues (verify manually)
| Element | Foreground | Background | Ratio | Required |
|---------|------------|------------|-------|----------|
| | | | | 4.5:1 |

#### Color-Only Indicators
| Component | Issue | Fix |
|-----------|-------|-----|
| Error state | Red only | Add icon + text |

### 7. Motion

- [ ] `prefers-reduced-motion` respected: [Yes/No]
- [ ] Animations < 5 seconds or stoppable: [Yes/No]
- [ ] No content flashes > 3 times/second: [Yes/No]

### 8. Testing Coverage

- [ ] Automated a11y tests: [Yes/No]
- [ ] axe-core or similar: [Yes/No]
- [ ] a11y in CI pipeline: [Yes/No]

## Action Items

### Critical (Fix Immediately)
1. [ ] [Issue] - Blocks [user group]

### Serious (Fix This Sprint)
1. [ ] [Issue] - WCAG [criterion]

### Moderate (Plan for)
1. [ ] [Issue]

### Quick Wins (< 1 hour each)
1. [ ] Add alt text to [X] images
2. [ ] Add aria-label to [Y] icon buttons
3. [ ] Add :focus-visible styles

## Testing Recommendations

### Manual Testing Checklist
- [ ] Keyboard-only navigation through all features
- [ ] Screen reader testing (VoiceOver + NVDA)
- [ ] 200% zoom - content reflows
- [ ] High contrast mode
- [ ] Reduced motion preference

### Automated Testing Setup
```typescript
// Add to test setup
import 'jest-axe';

it('should have no a11y violations', async () => {
  const { container } = render(<MyComponent />);
  expect(await axe(container)).toHaveNoViolations();
});
```

## WCAG Reference

| Criterion | Level | Status |
|-----------|-------|--------|
| 1.1.1 Non-text Content | A | |
| 1.3.1 Info and Relationships | A | |
| 1.4.3 Contrast (Minimum) | AA | |
| 2.1.1 Keyboard | A | |
| 2.4.4 Link Purpose | A | |
| 2.4.7 Focus Visible | AA | |
| 4.1.2 Name, Role, Value | A | |

---
**Audit Complete:** [Date/Time]
**Next Review:** [Recommended date]
```

## Quick Reference

### WCAG Success Criteria Most Often Failed
1. **1.4.3 Contrast** - Text too light
2. **1.3.1 Info and Relationships** - Missing labels, bad structure
3. **4.1.2 Name, Role, Value** - Custom components without ARIA
4. **2.4.7 Focus Visible** - Hidden or removed focus indicators
5. **1.1.1 Non-text Content** - Missing alt text

### Tools for Deeper Testing
- **axe DevTools** - Browser extension
- **Lighthouse** - Chrome DevTools
- **WAVE** - Browser extension
- **Colour Contrast Analyser** - Desktop app
- **NVDA** - Free Windows screen reader
