# Angular Style Audit

Audit an Angular application's Material Design implementation, theming architecture, and CSS patterns. Focuses on sustainable, themeable styling.

**Related audits:**
- `/angular-architecture-audit` - Services, DI, state management, component structure
- `/angular-performance-audit` - Change detection, lazy loading, memory, bundles

**Target Application:** $ARGUMENTS (path to Angular app, defaults to current directory)

## Audit Philosophy

This audit focuses on **sustainable, themeable, maintainable code**. The goal is not perfection but identifying patterns that:
- Break when Material updates
- Fight the framework instead of leveraging it
- Create tech debt through inconsistency
- Will haunt you at 2am during an incident

## Investigation Process

### 0. **Setup and Discovery**

```bash
# Determine target path
APP_PATH="${ARGUMENTS:-.}"

# Verify it's an Angular app
if [[ ! -f "$APP_PATH/angular.json" ]] && [[ ! -f "$APP_PATH/package.json" ]]; then
    echo "❌ No Angular app found at: $APP_PATH"
    echo "Please provide the path to an Angular application"
    exit 1
fi

# Get Angular and Material versions
echo "📦 Detecting versions..."
ANGULAR_VERSION=$(grep '"@angular/core"' "$APP_PATH/package.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
MATERIAL_VERSION=$(grep '"@angular/material"' "$APP_PATH/package.json" | sed 's/.*: *"\([^"]*\)".*/\1/' || echo "Not installed")
echo "   Angular: $ANGULAR_VERSION"
echo "   Material: $MATERIAL_VERSION"
```

### 1. **Material Design System Audit**

#### 1.1 Theming Architecture Check

**Look for these files:**
- `styles.scss` or `styles.css` - Global theme definition
- `**/theme*.scss` - Theme configuration files
- `**/material*.scss` - Material customizations

**Check for:**

| Pattern | Status | Severity |
|---------|--------|----------|
| Using M3 theming API (`mat.define-theme`) | Required for Material 18+ | High |
| Using legacy M2 API (`m2-define-palette`) | Deprecated, should migrate | Medium |
| CSS custom properties for theme colors | Best practice | Medium |
| Hardcoded Material colors in components | Anti-pattern | High |

**M3 Migration Status:**
```scss
// OLD (M2) - Flag these
$theme: mat.m2-define-light-theme(...);
@include mat.all-component-themes($theme);

// NEW (M3) - This is the target
$theme: mat.define-theme((
  color: (
    theme-type: light,
    primary: mat.$azure-palette,
  )
));
@include mat.all-component-themes($theme);
```

#### 1.2 Color Token Usage

**Search for hardcoded colors in SCSS files:**
```bash
# Find hardcoded hex colors (excluding CSS custom properties definitions)
grep -rn '#[0-9a-fA-F]\{3,6\}' --include="*.scss" "$APP_PATH/src" | grep -v "^\s*--"

# Find hardcoded rgba values
grep -rn 'rgba\s*(' --include="*.scss" "$APP_PATH/src"

# Find direct color names
grep -rn '\bwhite\b\|\bblack\b' --include="*.scss" "$APP_PATH/src"
```

**Expected findings to flag:**
- `#1976d2` → Should be `var(--mat-primary)` or theme token
- `#757575` → Should be `var(--text-secondary)` or `mat.get-theme-color()`
- `rgba(0, 0, 0, 0.87)` → Should be `var(--mat-on-surface)` or theme token
- `white` / `black` → Should use semantic tokens

#### 1.3 Component Style Isolation

**Check for leaky styles:**
```bash
# Find styles targeting Material internal classes
grep -rn '\.mat-mdc-\|\.mdc-' --include="*.scss" "$APP_PATH/src/app"

# Find !important usage (often a sign of fighting the framework)
grep -rn '!important' --include="*.scss" "$APP_PATH/src"

# Find deep combinator (deprecated, breaks encapsulation)
grep -rn '::ng-deep\|/deep/\|>>>' --include="*.scss" "$APP_PATH/src"
```

### 2. **Dark Theme Implementation Audit**

#### 2.1 Theme Switching Strategy

**Check implementation pattern:**

| Pattern | Assessment |
|---------|------------|
| CSS class toggle (`.dark-theme`) | Good |
| Media query only (`prefers-color-scheme`) | Incomplete - users can't override |
| Duplicate SCSS in every component | Anti-pattern |
| CSS custom properties that update | Best practice |

**Analyze dark theme coverage:**
```bash
# Count components with dark theme overrides
grep -rln ':host-context(.dark-theme)' --include="*.scss" "$APP_PATH/src" | wc -l

# Components should NOT need this if theming is done properly
# Flag any file that has :host-context(.dark-theme) with hardcoded colors
```

#### 2.2 CSS Custom Properties Audit

**Check `:root` and `.dark-theme` variable definitions:**

**Required semantic tokens:**
```scss
// These should exist and be used consistently
--bg-color / --mat-sys-surface
--text-primary / --mat-sys-on-surface
--text-secondary / --mat-sys-on-surface-variant
--primary-color / --mat-sys-primary
--border-color / --mat-sys-outline
```

**Anti-pattern detection:**
```bash
# Find components defining their own color values instead of using vars
grep -rn 'color:\s*#\|background:\s*#\|background-color:\s*#' --include="*.scss" "$APP_PATH/src/app"
```

### 3. **Angular Best Practices Audit**

#### 3.1 Component Architecture

**Check for modern patterns:**
```bash
# Standalone components (should be default in Angular 17+)
grep -rln "standalone: true" --include="*.ts" "$APP_PATH/src/app" | wc -l
grep -rln "standalone: false\|@NgModule" --include="*.ts" "$APP_PATH/src/app" | wc -l

# Signal usage (preferred over BehaviorSubject for local state)
grep -rn "signal<\|computed<\|input<\|output<" --include="*.ts" "$APP_PATH/src/app" | wc -l

# Legacy patterns to flag
grep -rn "@Input()\|@Output()" --include="*.ts" "$APP_PATH/src/app" | wc -l
```

#### 3.2 Change Detection

**Look for:**
```bash
# OnPush strategy (should be used in most components)
grep -rn "changeDetection: ChangeDetectionStrategy.OnPush" --include="*.ts" "$APP_PATH/src/app" | wc -l

# Manual change detection (often a code smell)
grep -rn "ChangeDetectorRef\|detectChanges()\|markForCheck()" --include="*.ts" "$APP_PATH/src/app"
```

#### 3.3 Template Patterns

**Check for:**
```bash
# Control flow syntax (new in Angular 17)
grep -rn "@if\|@for\|@switch" --include="*.html" "$APP_PATH/src/app" | wc -l

# Legacy structural directives (should migrate)
grep -rn "\*ngIf\|\*ngFor\|\*ngSwitch" --include="*.html" "$APP_PATH/src/app" | wc -l

# Async pipe (good for observables in templates)
grep -rn "| async" --include="*.html" "$APP_PATH/src/app" | wc -l
```

### 4. **Material Component Usage Audit**

#### 4.1 Import Strategy

**Check for proper imports:**
```bash
# Individual module imports (correct)
grep -rn "MatButtonModule\|MatIconModule\|MatFormFieldModule" --include="*.ts" "$APP_PATH/src/app" | head -20

# Importing entire Material library (anti-pattern)
grep -rn "MaterialModule\|import.*@angular/material'" --include="*.ts" "$APP_PATH/src"
```

#### 4.2 Form Field Patterns

**Check for:**
- Using `<mat-form-field>` with proper `appearance` attribute
- Error state matching with `<mat-error>`
- Hint usage with `<mat-hint>`
- Floating label configuration

#### 4.3 Accessibility

```bash
# ARIA attributes on custom components
grep -rn "aria-label\|aria-describedby\|role=" --include="*.html" "$APP_PATH/src/app" | wc -l

# CDK a11y usage
grep -rn "cdkTrapFocus\|cdkAriaLive\|FocusMonitor" --include="*.ts" "$APP_PATH/src/app"
```

### 5. **Production Readiness Checks**

#### 5.1 Build Configuration

```bash
# Check angular.json for production optimizations
grep -A 20 '"production"' "$APP_PATH/angular.json" | head -30
```

**Verify:**
- `optimization: true`
- `outputHashing: "all"`
- `sourceMap: false` (or external only)
- `budgets` configured

#### 5.2 Bundle Analysis

```bash
# Check for obvious bundle bloat
grep -rn "import \* as" --include="*.ts" "$APP_PATH/src" | head -10

# Lodash full import (should use lodash-es with tree shaking)
grep -rn "from 'lodash'" --include="*.ts" "$APP_PATH/src"

# Moment.js (should use date-fns or native)
grep -rn "from 'moment'" --include="*.ts" "$APP_PATH/src"
```

#### 5.3 Error Handling

```bash
# Global error handler
grep -rn "ErrorHandler" --include="*.ts" "$APP_PATH/src"

# HTTP interceptors for error handling
grep -rn "HttpInterceptor\|intercept(" --include="*.ts" "$APP_PATH/src"
```

### 6. **Generate Audit Report**

```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
AUDIT_DIR="${REPORT_BASE}/audits/angular-$(basename $APP_PATH)-$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"
```

#### Report Structure:

```markdown
# Angular Production Audit Report

**Application:** [App Name]
**Date:** [Audit Date]
**Angular Version:** [Version]
**Material Version:** [Version]

## Executive Summary

### Overall Score: [A-F]

| Category | Score | Critical Issues |
|----------|-------|-----------------|
| Material Theming | | |
| Dark Mode | | |
| Angular Patterns | | |
| Production Config | | |

### Top 3 Issues to Address

1. **[Issue]** - [Impact] - [Effort to fix]
2. **[Issue]** - [Impact] - [Effort to fix]
3. **[Issue]** - [Impact] - [Effort to fix]

## Detailed Findings

### Material Design System

#### Theming Architecture
**Status:** [Good/Needs Work/Critical]

**Current State:**
- Theme API: [M2/M3]
- CSS Custom Properties: [Yes/Partial/No]
- Color Tokens: [Semantic/Hardcoded/Mixed]

**Issues Found:**
| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| | | | |

**Recommended Changes:**
```scss
// Before
.component {
  color: #1976d2;
  background: white;
}

// After
.component {
  color: var(--mat-sys-primary);
  background: var(--mat-sys-surface);
}
```

#### Dark Theme Implementation
**Status:** [Good/Needs Work/Critical]

**Pattern Analysis:**
- Switching mechanism: [Class toggle/Media query/Both]
- Component overrides: [X] files with `:host-context(.dark-theme)`
- CSS variable coverage: [Complete/Partial/Missing]

**Files needing refactor:**
1. [file:line] - [issue]
2. [file:line] - [issue]

### Angular Patterns

#### Component Architecture
**Status:** [Good/Needs Work/Critical]

| Pattern | Count | Target |
|---------|-------|--------|
| Standalone components | | 100% |
| Signal-based inputs | | Preferred |
| OnPush change detection | | 80%+ |
| New control flow | | 100% |

#### Migration Tasks:
- [ ] Convert [X] components to standalone
- [ ] Replace @Input/@Output with signal equivalents
- [ ] Migrate *ngIf/*ngFor to @if/@for
- [ ] Add OnPush to [X] components

### Production Configuration

#### Build Optimization
**Status:** [Good/Needs Work/Critical]

- [ ] Optimization enabled
- [ ] Output hashing configured
- [ ] Source maps disabled for prod
- [ ] Bundle budgets set
- [ ] Tree shaking effective

#### Security
- [ ] No secrets in code
- [ ] CSP headers configured
- [ ] HTTPS enforced

## Action Items

### Immediate (P0)
1. [ ] [Action]
2. [ ] [Action]

### Short-term (P1)
1. [ ] [Action]
2. [ ] [Action]

### Long-term (P2)
1. [ ] [Action]
2. [ ] [Action]

## Appendix

### Files Audited
[List of all files checked]

### Tools Used
- Angular CLI
- grep/ripgrep for pattern matching
- Manual code review

---
**Audit Complete:** [Date/Time]
**Auditor:** Claude
```

## Severity Definitions

| Level | Definition | Action |
|-------|------------|--------|
| **Critical** | Blocks production or causes runtime failures | Fix before deploy |
| **High** | Significant tech debt or maintenance burden | Fix this sprint |
| **Medium** | Best practice violation, sustainable but not ideal | Plan for refactor |
| **Low** | Cosmetic or minor optimization | Nice to have |

## Notes

- This audit focuses on **patterns**, not perfection
- Some legacy code is acceptable if isolated and documented
- The goal is a clear migration path, not immediate rewrites
- Always verify findings in context - grep can miss nuance
