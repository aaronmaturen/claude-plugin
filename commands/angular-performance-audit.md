# Angular Performance Audit

Audit an Angular application's runtime performance, bundle size, change detection strategy, and optimization patterns. Focuses on fast initial load and smooth runtime.

**Related audits:**
- `/angular-style-audit` - Material Design, theming, CSS patterns
- `/angular-architecture-audit` - Services, DI, state management, component structure

**Usage:**
- `/angular-performance-audit` - Full audit of current directory
- `/angular-performance-audit /path/to/app` - Full audit of specified path
- `/angular-performance-audit --branch` or `-b` - Audit only files changed in current branch
- `/angular-performance-audit --branch /path/to/app` - Branch audit in specified path

## Audit Philosophy

This audit focuses on **perceived and actual performance**. The goal is identifying:
- Bundle bloat that slows initial load
- Change detection thrashing that kills runtime FPS
- Memory leaks that degrade over time
- Missing optimizations that are easy wins
- Over-engineering that adds complexity without benefit

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

# Verify Angular app
if [[ ! -f "$APP_PATH/angular.json" ]] && [[ ! -f "$APP_PATH/package.json" ]]; then
    echo "❌ No Angular app found at: $APP_PATH"
    exit 1
fi

# Branch mode setup
if [[ "$BRANCH_MODE" == true ]]; then
    CURRENT_BRANCH=$(git branch --show-current)
    BASE_BRANCH="main"

    # Get changed files (performance: .ts, .html, .scss for component analysis)
    CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null | grep -E '\.(ts|html|scss)$' | grep -v "\.spec\.ts$" | grep -v "node_modules")

    if [[ -z "$CHANGED_FILES" ]]; then
        echo "⚠️  No relevant files changed compared to $BASE_BRANCH"
        echo "   (Looking for: .ts, .html, .scss)"
        echo ""
        echo "   Run without --branch for full audit"
        exit 0
    fi

    echo "🌿 BRANCH MODE: Performance audit of files changed in current branch"
    echo "   Branch: $CURRENT_BRANCH"
    echo "   Comparing to: $BASE_BRANCH"
    echo "   Files to audit: $(echo "$CHANGED_FILES" | wc -l | tr -d ' ')"
    echo ""

    # Categorize changed files
    COMPONENT_FILES=$(echo "$CHANGED_FILES" | grep -E "\.component\.ts$")
    TEMPLATE_FILES=$(echo "$CHANGED_FILES" | grep -E "\.html$")
    [[ -n "$COMPONENT_FILES" ]] && echo "   🧩 Component files: $(echo "$COMPONENT_FILES" | wc -l | tr -d ' ')"
    [[ -n "$TEMPLATE_FILES" ]] && echo "   📄 Template files: $(echo "$TEMPLATE_FILES" | wc -l | tr -d ' ')"
    echo ""

    # Helper function for branch-aware searching
    search_files() {
        local pattern="$1"
        local file_filter="${2:-}"

        if [[ -n "$file_filter" ]]; then
            echo "$CHANGED_FILES" | grep -E "$file_filter" | xargs grep -n "$pattern" 2>/dev/null
        else
            echo "$CHANGED_FILES" | xargs grep -n "$pattern" 2>/dev/null
        fi
    }

    count_matches() {
        search_files "$1" "$2" | wc -l | tr -d ' '
    }
else
    echo "📂 Full audit mode: $APP_PATH"

    # Full mode search helper
    search_files() {
        local pattern="$1"
        local file_filter="${2:-*.ts}"

        grep -rn "$pattern" --include="$file_filter" "$APP_PATH/src/app" 2>/dev/null
    }

    count_matches() {
        search_files "$1" "$2" | wc -l | tr -d ' '
    }
fi

# Get versions
ANGULAR_VERSION=$(grep '"@angular/core"' "$APP_PATH/package.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
echo "📦 Angular: $ANGULAR_VERSION"

# Check for performance-related packages
grep -q "compression" "$APP_PATH/package.json" && echo "   ✓ Compression available"
grep -q "@angular/service-worker" "$APP_PATH/package.json" && echo "   ✓ Service Worker available"
grep -q "ngx-virtual-scroll\|cdk/scrolling" "$APP_PATH/package.json" && echo "   ✓ Virtual scrolling available"
```

**Note on Branch Mode:** When using `--branch`, use `search_files "pattern" "file_filter"` to search only changed files. For performance audits, branch mode helps focus on new code that might introduce regressions.

### 1. **Bundle Size Audit**

#### 1.1 Build Configuration

```bash
# Check angular.json for production optimizations
grep -A 30 '"production"' "$APP_PATH/angular.json"
```

**Verify these are set for production:**
| Setting | Expected | Impact |
|---------|----------|--------|
| `optimization` | true (default) | Tree shaking, minification |
| `outputHashing` | "all" | Cache busting |
| `sourceMap` | false | Smaller bundles |
| `budgets` | Configured | Prevent bloat |
| `namedChunks` | false | Smaller chunk names |

#### 1.2 Bundle Budgets

```bash
# Extract current budgets
grep -A 10 "budgets" "$APP_PATH/angular.json"
```

**Recommended budgets:**
| Type | Warning | Error |
|------|---------|-------|
| initial | 500KB | 1MB |
| anyComponentStyle | 6KB | 10KB |

Flag if budgets are:
- Missing entirely
- Set too high (> 2MB initial)
- Only warning, no error threshold

#### 1.3 Import Analysis

**Heavy imports to flag:**
```bash
# Lodash (should use lodash-es or individual imports)
grep -rn "from 'lodash'" --include="*.ts" "$APP_PATH/src"
grep -rn "import \* as _ from" --include="*.ts" "$APP_PATH/src"

# Moment.js (should use date-fns, dayjs, or native)
grep -rn "from 'moment'" --include="*.ts" "$APP_PATH/src"

# RxJS full import (should import operators individually)
grep -rn "from 'rxjs'" --include="*.ts" "$APP_PATH/src" | grep -v "from 'rxjs/operators'"

# Barrel imports that might break tree shaking
grep -rn "from '\.\./\.\./.*'" --include="*.ts" "$APP_PATH/src" | head -20

# Material importing entire modules vs individual components
grep -rn "MatModule" --include="*.ts" "$APP_PATH/src"
```

#### 1.4 CommonJS Dependencies

```bash
# Check allowedCommonJsDependencies
grep -A 5 "allowedCommonJsDependencies" "$APP_PATH/angular.json"

# These cause warnings and can't be tree-shaken
```

### 2. **Change Detection Audit**

#### 2.1 OnPush Strategy

```bash
# Components using OnPush (preferred)
grep -rn "changeDetection: ChangeDetectionStrategy.OnPush" --include="*.ts" "$APP_PATH/src/app"

# Total components
TOTAL_COMPONENTS=$(find "$APP_PATH/src/app" -name "*.component.ts" | wc -l)
ONPUSH_COUNT=$(grep -rln "ChangeDetectionStrategy.OnPush" --include="*.ts" "$APP_PATH/src/app" | wc -l)
echo "OnPush: $ONPUSH_COUNT / $TOTAL_COMPONENTS components"
```

**Target:** 80%+ components should use OnPush (exceptions: forms with complex state)

#### 2.2 Change Detection Triggers

```bash
# Manual change detection (often a smell)
grep -rn "ChangeDetectorRef" --include="*.ts" "$APP_PATH/src/app"
grep -rn "detectChanges()" --include="*.ts" "$APP_PATH/src/app"
grep -rn "markForCheck()" --include="*.ts" "$APP_PATH/src/app"

# ApplicationRef.tick() (almost always wrong)
grep -rn "ApplicationRef" --include="*.ts" "$APP_PATH/src/app"
```

**Red flags:**
- `detectChanges()` called in loops
- `markForCheck()` on every async operation
- Multiple manual CD calls in one component

#### 2.3 Zone.js Escapes

```bash
# Running outside zone (performance optimization, but risky)
grep -rn "NgZone" --include="*.ts" "$APP_PATH/src/app"
grep -rn "runOutsideAngular" --include="*.ts" "$APP_PATH/src/app"
```

### 3. **Template Performance Audit**

#### 3.1 TrackBy Functions

```bash
# @for without track (bad - full re-render on change)
grep -rn "@for" --include="*.html" "$APP_PATH/src/app" | grep -v "track"

# *ngFor without trackBy (legacy, same issue)
grep -rn "\*ngFor" --include="*.html" "$APP_PATH/src/app" | grep -v "trackBy"

# Good: trackBy or track usage
grep -rn "trackBy\|track " --include="*.html" "$APP_PATH/src/app"
```

**Impact:** Missing trackBy on lists > 20 items causes noticeable jank

#### 3.2 Template Expressions

```bash
# Function calls in templates (re-evaluated every CD cycle)
grep -rn "{{.*()}}" --include="*.html" "$APP_PATH/src/app"

# Method bindings in templates
grep -rn "\[.*\]=\"[a-zA-Z]*()\"" --include="*.html" "$APP_PATH/src/app"

# Complex expressions (should be computed/memoized)
grep -rn "{{\s*[^}]*\s*\?\s*[^}]*\s*:\s*[^}]*}}" --include="*.html" "$APP_PATH/src/app"
```

**Fix:** Move to computed signals or memoized getters

#### 3.3 Async Operations in Templates

```bash
# Multiple async pipes on same observable (creates multiple subscriptions)
grep -rn "| async.*| async" --include="*.html" "$APP_PATH/src/app"

# Good: single async with @if/@let
grep -rn "@if.*; as \|@let" --include="*.html" "$APP_PATH/src/app"
```

### 4. **Lazy Loading Audit**

#### 4.1 Route Configuration

```bash
# Lazy loaded routes (good)
grep -rn "loadComponent\|loadChildren" --include="*.ts" "$APP_PATH/src/app"

# Eagerly loaded routes (check if should be lazy)
grep -rn "component:" --include="*.ts" "$APP_PATH/src/app" | grep -v ".spec.ts"
```

#### 4.2 Preloading Strategy

```bash
# Check for preloading configuration
grep -rn "PreloadAllModules\|preloadingStrategy" --include="*.ts" "$APP_PATH/src/app"
```

| Strategy | Use Case |
|----------|----------|
| No preloading | Minimal initial load, pay on navigation |
| PreloadAllModules | Fast subsequent navigation, larger initial |
| Custom strategy | Preload likely routes based on analytics |

#### 4.3 Defer Blocks (Angular 17+)

```bash
# @defer usage (progressive rendering)
grep -rn "@defer" --include="*.html" "$APP_PATH/src/app"

# Check for defer triggers
grep -rn "@defer.*on\|@placeholder\|@loading" --include="*.html" "$APP_PATH/src/app"
```

### 5. **List & Scroll Performance**

#### 5.1 Virtual Scrolling

```bash
# CDK virtual scroll usage
grep -rn "cdk-virtual-scroll\|CdkVirtualScrollViewport" --include="*.ts" --include="*.html" "$APP_PATH/src/app"

# Large lists without virtualization (potential issue)
grep -rn "@for.*let.*of" --include="*.html" "$APP_PATH/src/app"
```

**Rule of thumb:** Lists > 50 items should consider virtualization

#### 5.2 Infinite Scroll

```bash
# Infinite scroll implementations
grep -rn "IntersectionObserver\|infinite.*scroll" --include="*.ts" "$APP_PATH/src/app"
```

### 6. **Memory Management Audit**

#### 6.1 Event Listener Cleanup

```bash
# addEventListener without removeEventListener
grep -rn "addEventListener" --include="*.ts" "$APP_PATH/src/app" | grep -v ".spec.ts"
grep -rn "removeEventListener" --include="*.ts" "$APP_PATH/src/app" | grep -v ".spec.ts"

# fromEvent without cleanup
grep -rn "fromEvent" --include="*.ts" "$APP_PATH/src/app"
```

#### 6.2 DOM References

```bash
# ElementRef usage (can hold DOM references)
grep -rn "ElementRef" --include="*.ts" "$APP_PATH/src/app"

# Renderer2 (safer but still needs care)
grep -rn "Renderer2" --include="*.ts" "$APP_PATH/src/app"

# Direct document/window access
grep -rn "document\.\|window\." --include="*.ts" "$APP_PATH/src/app" | grep -v ".spec.ts"
```

#### 6.3 Third-Party Library Cleanup

```bash
# Chart libraries (often need manual destroy)
grep -rn "Chart\|chart\.js\|ngx-charts\|d3\." --include="*.ts" "$APP_PATH/src/app"

# Map libraries
grep -rn "google\.maps\|mapbox\|leaflet" --include="*.ts" "$APP_PATH/src/app"
```

### 7. **Image & Asset Performance**

#### 7.1 NgOptimizedImage

```bash
# Using NgOptimizedImage (Angular 15+)
grep -rn "NgOptimizedImage\|ngSrc" --include="*.ts" --include="*.html" "$APP_PATH/src/app"

# Regular img tags (should migrate)
grep -rn "<img" --include="*.html" "$APP_PATH/src/app" | grep -v "ngSrc"
```

#### 7.2 Image Loading

```bash
# Lazy loading attribute
grep -rn 'loading="lazy"' --include="*.html" "$APP_PATH/src/app"

# Priority hints for LCP images
grep -rn 'fetchpriority\|priority' --include="*.html" "$APP_PATH/src/app"
```

### 8. **Animation Performance**

```bash
# Angular animations
grep -rn "@angular/animations" --include="*.ts" "$APP_PATH/src/app"

# CSS transitions (often better performance)
grep -rn "transition:" --include="*.scss" --include="*.css" "$APP_PATH/src"

# Transform-based animations (GPU accelerated - good)
grep -rn "transform:" --include="*.scss" --include="*.css" "$APP_PATH/src"

# Layout-triggering animations (bad - avoid animating width/height/top/left)
grep -rn "animate.*width\|animate.*height\|animate.*top\|animate.*left" --include="*.ts" "$APP_PATH/src/app"
```

### 9. **SSR/Hydration Audit** (if applicable)

```bash
# Check for SSR
grep -q "@angular/platform-server\|@angular/ssr" "$APP_PATH/package.json" && echo "SSR enabled"

# Hydration
grep -rn "provideClientHydration" --include="*.ts" "$APP_PATH/src"

# isPlatformBrowser checks (SSR compatibility)
grep -rn "isPlatformBrowser\|isPlatformServer\|PLATFORM_ID" --include="*.ts" "$APP_PATH/src/app"
```

### 10. **Generate Report**

```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
AUDIT_DIR="${REPORT_BASE}/audits/angular-perf-$(basename $APP_PATH)-$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"
```

#### Report Structure:

```markdown
# Angular Performance Audit Report

**Application:** [App Name]
**Date:** [Audit Date]
**Angular Version:** [Version]

## Executive Summary

### Performance Score: [A-F]

| Category | Score | Impact |
|----------|-------|--------|
| Bundle Size | | Initial load |
| Change Detection | | Runtime FPS |
| Template Efficiency | | Runtime FPS |
| Lazy Loading | | Initial load |
| Memory Management | | Long sessions |

### Key Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Initial bundle | [X] KB | < 500 KB |
| OnPush adoption | [X]% | > 80% |
| trackBy coverage | [X]% | 100% |
| Lazy routes | [X]/[Y] | Max possible |

### Top 3 Performance Wins

1. **[Win]** - [Expected improvement] - [Effort]
2. **[Win]** - [Expected improvement] - [Effort]
3. **[Win]** - [Expected improvement] - [Effort]

## Detailed Findings

### Bundle Size

#### Current Budgets
```json
[current budget config]
```

#### Heavy Dependencies
| Package | Size | Recommendation |
|---------|------|----------------|
| | | |

#### Import Issues
| File | Issue | Fix |
|------|-------|-----|
| | | |

### Change Detection

#### OnPush Coverage
- Total components: [X]
- Using OnPush: [Y]
- Coverage: [Z]%

**Components to migrate:**
1. [component] - [reason it's not OnPush]

#### Manual CD Usage
| File | Method | Issue |
|------|--------|-------|
| | detectChanges() | |
| | markForCheck() | |

### Template Performance

#### Missing trackBy
| File | List | Fix |
|------|------|-----|
| | | |

#### Function Calls in Templates
| File | Expression | Fix |
|------|------------|-----|
| | | |

### Lazy Loading

#### Route Analysis
| Route | Type | Size | Recommendation |
|-------|------|------|----------------|
| / | Eager | | |
| /feature | Lazy | | |

#### Defer Block Opportunities
- [component] could use @defer for [reason]

### Memory Management

#### Potential Leaks
| File | Issue | Severity |
|------|-------|----------|
| | | |

### Image Optimization

| Issue | Count | Fix |
|-------|-------|-----|
| img without ngSrc | | Migrate to NgOptimizedImage |
| Missing lazy loading | | Add loading="lazy" |
| Missing priority | | Add priority to LCP images |

## Action Items

### Quick Wins (< 1 hour each)
1. [ ] Add trackBy to [X] @for loops
2. [ ] Enable OnPush on [Y] components
3. [ ] Add loading="lazy" to below-fold images

### Medium Effort (1 day)
1. [ ] Replace [heavy package] with [lighter alternative]
2. [ ] Add @defer to [heavy component]
3. [ ] Implement virtual scrolling for [long list]

### Larger Refactors
1. [ ] Migrate remaining *ngFor to @for with track
2. [ ] Add route preloading strategy
3. [ ] Extract template functions to computed signals

## Measurement Plan

After implementing fixes, measure:
1. **Bundle size** - `ng build --stats-json` + webpack-bundle-analyzer
2. **Initial load** - Lighthouse Performance score
3. **Runtime** - Chrome DevTools Performance panel
4. **Memory** - Chrome DevTools Memory panel over time

---
**Audit Complete:** [Date/Time]
```

## Severity Definitions

| Level | Definition | Examples |
|-------|------------|----------|
| **Critical** | Visible user impact now | > 3MB initial bundle, missing trackBy on 100+ item lists |
| **High** | Will cause problems at scale | Default change detection everywhere, memory leaks |
| **Medium** | Noticeable but manageable | Function calls in templates, missing lazy loading |
| **Low** | Optimization opportunities | Not using NgOptimizedImage, minor CD improvements |

## Performance Budget Recommendations

### Small App (< 10 routes)
- Initial: 300KB warning, 500KB error
- Per-route chunk: 50KB warning, 100KB error

### Medium App (10-50 routes)
- Initial: 500KB warning, 1MB error
- Per-route chunk: 100KB warning, 200KB error

### Large App (50+ routes)
- Initial: 750KB warning, 1.5MB error
- Per-route chunk: 150KB warning, 300KB error
- Consider micro-frontends if exceeding these consistently
