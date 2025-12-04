# Angular Architecture Audit

Audit an Angular application's service layer, dependency injection, state management, and component architecture. Focuses on maintainable, testable code patterns.

**Related audits:**
- `/angular-style-audit` - Material Design, theming, CSS patterns
- `/angular-performance-audit` - Change detection, lazy loading, memory, bundles

**Usage:**
- `/angular-architecture-audit` - Full audit of current directory
- `/angular-architecture-audit /path/to/app` - Full audit of specified path
- `/angular-architecture-audit --branch` or `-b` - Audit only files changed in current branch
- `/angular-architecture-audit --branch /path/to/app` - Branch audit in specified path

## Audit Philosophy

This audit focuses on **code that scales**. The goal is identifying patterns that:
- Create tight coupling between components
- Make testing difficult or impossible
- Lead to memory leaks and zombie subscriptions
- Fight Angular's dependency injection system
- Create maintenance nightmares as the app grows

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
```

### 0.1 Eligibility Check (Quick - use haiku)

Before running a full audit, verify this audit is appropriate:

**Skip audit if:**
- No angular.json file found
- No @angular/core in package.json dependencies

If skipping, output: "⏭️ Skipping Angular architecture audit - [reason]. This project doesn't appear to need this audit."

```bash
# Quick check for Angular project
if [[ ! -f "$APP_PATH/angular.json" ]]; then
    if [[ -f "$APP_PATH/package.json" ]]; then
        if ! grep -q "@angular/core" "$APP_PATH/package.json" 2>/dev/null; then
            echo "⏭️ Skipping Angular architecture audit - no Angular project detected. No angular.json or @angular/core dependency found."
            exit 0
        fi
    else
        echo "⏭️ Skipping Angular architecture audit - no Angular project detected. No angular.json or package.json found."
        exit 0
    fi
fi

echo "✓ Angular project detected - proceeding with audit"
```

```bash
# Branch mode setup
if [[ "$BRANCH_MODE" == true ]]; then
    CURRENT_BRANCH=$(git branch --show-current)
    BASE_BRANCH="main"

    # Get changed files (relevant to architecture: .ts files excluding tests)
    CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null | grep -E '\.(ts|html|scss)$' | grep -v "\.spec\.ts$" | grep -v "node_modules")

    if [[ -z "$CHANGED_FILES" ]]; then
        echo "⚠️  No relevant files changed compared to $BASE_BRANCH"
        echo "   (Looking for: .ts, .html, .scss excluding .spec.ts)"
        echo ""
        echo "   Run without --branch for full audit"
        exit 0
    fi

    echo "🌿 BRANCH MODE: Auditing only files changed in current branch"
    echo "   Branch: $CURRENT_BRANCH"
    echo "   Comparing to: $BASE_BRANCH"
    echo "   Files to audit: $(echo "$CHANGED_FILES" | wc -l | tr -d ' ')"
    echo ""

    # Categorize changed files
    SERVICE_FILES=$(echo "$CHANGED_FILES" | grep -E "\.service\.ts$")
    COMPONENT_FILES=$(echo "$CHANGED_FILES" | grep -E "\.component\.ts$")
    [[ -n "$SERVICE_FILES" ]] && echo "   📦 Service files: $(echo "$SERVICE_FILES" | wc -l | tr -d ' ')"
    [[ -n "$COMPONENT_FILES" ]] && echo "   🧩 Component files: $(echo "$COMPONENT_FILES" | wc -l | tr -d ' ')"
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

# Get versions and dependencies
echo "📦 Analyzing dependencies..."
ANGULAR_VERSION=$(grep '"@angular/core"' "$APP_PATH/package.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
echo "   Angular: $ANGULAR_VERSION"

# Check for state management libraries
grep -q "ngrx" "$APP_PATH/package.json" && echo "   State: NgRx detected"
grep -q "ngxs" "$APP_PATH/package.json" && echo "   State: NGXS detected"
grep -q "akita" "$APP_PATH/package.json" && echo "   State: Akita detected"
grep -q "elf" "$APP_PATH/package.json" && echo "   State: Elf detected"
```

**Note on Branch Mode:** When using `--branch`, use `search_files "pattern" "file_filter"` instead of raw grep commands. The file_filter is optional regex (e.g., `\.service\.ts$`).

### 1. **Service Architecture Audit**

#### 1.1 Dependency Injection Patterns

**Check providedIn usage:**
```bash
# Services with providedIn: 'root' (singleton - usually correct)
grep -rn "providedIn: 'root'" --include="*.ts" "$APP_PATH/src/app"

# Services with providedIn: 'any' (lazy module singleton - rare, verify intent)
grep -rn "providedIn: 'any'" --include="*.ts" "$APP_PATH/src/app"

# Services without providedIn (must be in providers array - legacy pattern)
grep -rn "@Injectable()" --include="*.ts" "$APP_PATH/src/app" | grep -v "providedIn"
```

**Expected findings:**
| Pattern | Assessment |
|---------|------------|
| `providedIn: 'root'` | Preferred for app-wide services |
| `providedIn: 'any'` | Verify intent - creates per-lazy-module instances |
| No providedIn | Legacy - should migrate unless component-scoped |
| In component providers | OK for component-scoped services |

#### 1.2 Service Responsibilities

**Check for god services:**
```bash
# Find large service files (potential god services)
find "$APP_PATH/src/app" -name "*.service.ts" -exec wc -l {} + | sort -n | tail -20

# Services with too many dependencies (constructor injection smell)
grep -A 20 "constructor(" --include="*.service.ts" -r "$APP_PATH/src/app" | grep -E "private|public|readonly" | head -30
```

**Red flags:**
- Service > 500 lines (probably doing too much)
- Constructor with > 5 injected dependencies
- Service importing other services that import it back (circular)

#### 1.3 Injection Token Usage

```bash
# Custom injection tokens (good for configuration, interfaces)
grep -rn "InjectionToken" --include="*.ts" "$APP_PATH/src/app"

# Factory providers
grep -rn "useFactory" --include="*.ts" "$APP_PATH/src/app"

# Value providers
grep -rn "useValue" --include="*.ts" "$APP_PATH/src/app"
```

### 2. **State Management Audit**

#### 2.1 Signal-Based State (Angular 16+)

```bash
# Signal usage in services (modern pattern)
grep -rn "signal<" --include="*.service.ts" "$APP_PATH/src/app"

# Computed signals
grep -rn "computed(" --include="*.service.ts" "$APP_PATH/src/app"

# Effect usage (side effects)
grep -rn "effect(" --include="*.ts" "$APP_PATH/src/app"
```

#### 2.2 RxJS State Patterns

```bash
# BehaviorSubject (stateful observable - common pattern)
grep -rn "BehaviorSubject" --include="*.ts" "$APP_PATH/src/app"

# ReplaySubject (careful - can cause memory issues)
grep -rn "ReplaySubject" --include="*.ts" "$APP_PATH/src/app"

# Subject (stateless - verify it shouldn't be BehaviorSubject)
grep -rn "new Subject<" --include="*.ts" "$APP_PATH/src/app"
```

**Assessment:**
| Pattern | Status |
|---------|--------|
| Signals for local state | Preferred (Angular 17+) |
| BehaviorSubject for shared state | Acceptable |
| ReplaySubject | Verify buffer size is bounded |
| Plain Subject | OK for events, not for state |

#### 2.3 State Mutation Patterns

```bash
# Direct array/object mutation (anti-pattern)
grep -rn "\.push(\|\.splice(\|\.pop(\|\.shift(" --include="*.ts" "$APP_PATH/src/app"

# Spread operator (immutable - good)
grep -rn "\.\.\." --include="*.ts" "$APP_PATH/src/app" | grep -E "=.*\[.*\.\.\.|=.*\{.*\.\.\." | head -20
```

### 3. **RxJS Patterns Audit**

#### 3.1 Subscription Management

**Critical - memory leak detection:**
```bash
# Manual subscriptions without cleanup
grep -rn "\.subscribe(" --include="*.ts" "$APP_PATH/src/app"

# takeUntilDestroyed (Angular 16+ - preferred)
grep -rn "takeUntilDestroyed" --include="*.ts" "$APP_PATH/src/app"

# takeUntil with destroy subject (legacy but OK)
grep -rn "takeUntil" --include="*.ts" "$APP_PATH/src/app"

# Unsubscribe in ngOnDestroy (manual - error prone)
grep -rn "unsubscribe()" --include="*.ts" "$APP_PATH/src/app"

# AsyncPipe usage (auto-manages subscription - preferred in templates)
grep -rn "| async" --include="*.html" "$APP_PATH/src/app"

# Subscription array pattern (legacy)
grep -rn "Subscription\[\]" --include="*.ts" "$APP_PATH/src/app"
```

**Severity assessment:**
| Pattern | Risk Level |
|---------|------------|
| `takeUntilDestroyed()` | Safe - auto cleanup |
| `| async` pipe | Safe - auto cleanup |
| `takeUntil(destroy$)` | Safe if implemented correctly |
| `.subscribe()` with manual unsubscribe | Risky - easy to forget |
| `.subscribe()` with no cleanup | Memory leak |

#### 3.2 RxJS Anti-Patterns

```bash
# Nested subscribes (anti-pattern - use switchMap/mergeMap)
grep -rn "subscribe.*subscribe" --include="*.ts" "$APP_PATH/src/app"
grep -B5 -A5 "\.subscribe(" --include="*.ts" "$APP_PATH/src/app" | grep -A5 "\.subscribe("

# toPromise (deprecated, use firstValueFrom/lastValueFrom)
grep -rn "\.toPromise()" --include="*.ts" "$APP_PATH/src/app"

# Subscribe with only next callback, no error handling
grep -rn "\.subscribe([^,)]*)" --include="*.ts" "$APP_PATH/src/app" | grep -v "subscribe({"
```

#### 3.3 HTTP Patterns

```bash
# HTTP calls without error handling
grep -rn "this.http\." --include="*.ts" "$APP_PATH/src/app" | grep -v catchError | grep -v "pipe("

# HTTP interceptors
grep -rn "HttpInterceptor\|intercept(" --include="*.ts" "$APP_PATH/src/app"

# Retry logic
grep -rn "retry(\|retryWhen(" --include="*.ts" "$APP_PATH/src/app"
```

### 4. **Component Architecture Audit**

#### 4.1 Smart vs Presentational Components

```bash
# Components injecting services (smart/container components)
grep -rln "constructor.*Service" --include="*.ts" "$APP_PATH/src/app/components"

# Components with only inputs/outputs (presentational - good)
grep -rln "input<\|output<\|@Input\|@Output" --include="*.ts" "$APP_PATH/src/app/components" | while read f; do
    grep -L "constructor.*Service" "$f" 2>/dev/null
done
```

**Healthy ratio:** Aim for more presentational components than smart components.

#### 4.2 Component Communication

```bash
# Input/Output usage (parent-child - good)
grep -rn "input<\|output<" --include="*.ts" "$APP_PATH/src/app"

# ViewChild/ContentChild (template queries - use sparingly)
grep -rn "@ViewChild\|@ContentChild\|viewChild\|contentChild" --include="*.ts" "$APP_PATH/src/app"

# Service-based communication (cross-tree - verify necessity)
grep -rn "Subject\|BehaviorSubject" --include="*.service.ts" "$APP_PATH/src/app" | grep -v "private"
```

#### 4.3 Lifecycle Hooks

```bash
# ngOnInit usage (should be preferred over constructor for init logic)
grep -rn "ngOnInit" --include="*.ts" "$APP_PATH/src/app"

# ngOnDestroy (cleanup - should match components with subscriptions)
grep -rn "ngOnDestroy" --include="*.ts" "$APP_PATH/src/app"

# ngOnChanges (input change handling)
grep -rn "ngOnChanges" --include="*.ts" "$APP_PATH/src/app"

# ngDoCheck (usually a smell - expensive)
grep -rn "ngDoCheck" --include="*.ts" "$APP_PATH/src/app"

# ngAfterViewInit/ngAfterContentInit
grep -rn "ngAfterViewInit\|ngAfterContentInit" --include="*.ts" "$APP_PATH/src/app"
```

### 5. **Error Handling Audit**

#### 5.1 Global Error Handling

```bash
# Custom ErrorHandler
grep -rn "ErrorHandler" --include="*.ts" "$APP_PATH/src/app"

# HTTP error interceptor
grep -rn "catchError\|HttpErrorResponse" --include="*.ts" "$APP_PATH/src/app"
```

#### 5.2 Component Error Handling

```bash
# Try-catch blocks
grep -rn "try {" --include="*.ts" "$APP_PATH/src/app"

# RxJS catchError
grep -rn "catchError(" --include="*.ts" "$APP_PATH/src/app"

# Error boundaries (if using any)
grep -rn "ErrorBoundary\|errorElement" --include="*.ts" "$APP_PATH/src/app"
```

### 6. **Testing Patterns Audit**

#### 6.1 Test Coverage Indicators

```bash
# Spec files count vs component/service count
SPEC_COUNT=$(find "$APP_PATH/src/app" -name "*.spec.ts" | wc -l)
COMPONENT_COUNT=$(find "$APP_PATH/src/app" -name "*.component.ts" -o -name "*.service.ts" | wc -l)
echo "Test files: $SPEC_COUNT / Components+Services: $COMPONENT_COUNT"

# TestBed usage (integration tests)
grep -rn "TestBed" --include="*.spec.ts" "$APP_PATH/src/app" | wc -l

# Mock patterns
grep -rn "jasmine.createSpy\|jest.fn\|createMock" --include="*.spec.ts" "$APP_PATH/src/app" | wc -l
```

#### 6.2 Testability Smells

```bash
# Direct DOM manipulation (hard to test)
grep -rn "document\.\|window\.\|localStorage\.\|sessionStorage\." --include="*.ts" "$APP_PATH/src/app" | grep -v ".spec.ts"

# Console statements left in code
grep -rn "console\." --include="*.ts" "$APP_PATH/src/app" | grep -v ".spec.ts"
```

### 7. **Module Organization Audit**

#### 7.1 Route Structure

```bash
# Lazy loaded routes
grep -rn "loadComponent\|loadChildren" --include="*.ts" "$APP_PATH/src/app"

# Route guards
grep -rn "canActivate\|canDeactivate\|canLoad\|canMatch" --include="*.ts" "$APP_PATH/src/app"

# Resolvers
grep -rn "resolve:" --include="*.ts" "$APP_PATH/src/app"
```

#### 7.2 Feature Organization

```bash
# Check folder structure
ls -la "$APP_PATH/src/app/"

# Barrel files (index.ts) - can hurt tree shaking
find "$APP_PATH/src/app" -name "index.ts" | wc -l
```

### 8. **Generate Report**

```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
AUDIT_DIR="${REPORT_BASE}/audits/angular-arch-$(basename $APP_PATH)-$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"
```

#### Report Structure:

```markdown
# Angular Architecture Audit Report

**Application:** [App Name]
**Date:** [Audit Date]
**Angular Version:** [Version]

## Executive Summary

### Overall Architecture Score: [A-F]

| Category | Score | Critical Issues |
|----------|-------|-----------------|
| Service Layer | | |
| State Management | | |
| RxJS Patterns | | |
| Component Architecture | | |
| Error Handling | | |

### Top 3 Architecture Risks

1. **[Risk]** - [Impact] - [Location]
2. **[Risk]** - [Impact] - [Location]
3. **[Risk]** - [Impact] - [Location]

## Detailed Findings

### Service Architecture

#### Dependency Injection
**Status:** [Good/Needs Work/Critical]

| Pattern | Count | Assessment |
|---------|-------|------------|
| providedIn: 'root' | | |
| No providedIn | | |
| Component providers | | |

**Issues Found:**
- [file:line] - [issue]

#### God Services (> 500 lines)
| Service | Lines | Recommendation |
|---------|-------|----------------|
| | | |

### State Management

**Pattern in use:** [Signals/RxJS/NgRx/Mixed]

#### Signal Usage
| Location | Pattern | Assessment |
|----------|---------|------------|
| | | |

#### RxJS State
| Subject Type | Count | Risk |
|--------------|-------|------|
| BehaviorSubject | | |
| ReplaySubject | | |
| Subject | | |

### Subscription Management

**Memory Leak Risk:** [Low/Medium/High/Critical]

| Pattern | Count |
|---------|-------|
| takeUntilDestroyed | |
| async pipe | |
| takeUntil(destroy$) | |
| Manual unsubscribe | |
| No cleanup visible | |

**Files with potential memory leaks:**
1. [file:line] - `.subscribe()` without cleanup

### RxJS Anti-Patterns

| Anti-Pattern | Occurrences | Fix |
|--------------|-------------|-----|
| Nested subscribes | | Use switchMap/mergeMap |
| toPromise() | | Use firstValueFrom() |
| Subscribe without error handling | | Add error callback |

### Component Architecture

#### Smart vs Presentational Ratio
- Smart components: [X]
- Presentational components: [Y]
- Ratio: [X:Y] (aim for 1:3 or better)

#### Lifecycle Hook Usage
| Hook | Count | Notes |
|------|-------|-------|
| ngOnInit | | |
| ngOnDestroy | | |
| ngOnChanges | | |
| ngDoCheck | | Flag if > 0 |

### Error Handling

| Pattern | Implemented |
|---------|-------------|
| Global ErrorHandler | Yes/No |
| HTTP Interceptor | Yes/No |
| Route error handling | Yes/No |
| RxJS catchError | X instances |

## Action Items

### Immediate (P0) - Memory Leaks
1. [ ] Add takeUntilDestroyed to [X] subscriptions
2. [ ] Review [files] for missing cleanup

### Short-term (P1) - Architecture
1. [ ] Split [god service] into focused services
2. [ ] Migrate [X] services to providedIn pattern
3. [ ] Add error handling to HTTP calls

### Long-term (P2) - Patterns
1. [ ] Consider signal-based state for [area]
2. [ ] Add route guards for [protected routes]
3. [ ] Improve test coverage

---
**Audit Complete:** [Date/Time]
```

## Severity Definitions

| Level | Definition | Examples |
|-------|------------|----------|
| **Critical** | Active memory leaks or crashes | Unmanaged subscriptions in frequently created components |
| **High** | Will cause problems at scale | God services, circular dependencies |
| **Medium** | Tech debt that accumulates | Missing error handling, legacy patterns |
| **Low** | Best practice violations | Minor DI improvements |

## Notes

- This audit focuses on **patterns**, not comprehensive code review
- Some legacy patterns are acceptable if isolated
- Signals are preferred but RxJS is not deprecated
- The goal is identifying risks, not enforcing dogma
