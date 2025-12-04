# Django API Audit

Audit a Django REST Framework / GraphQL API for serializer efficiency, permissions, pagination, throttling, and API design patterns.

**Related audits:**
- `/django-model-audit` - Query optimization, indexes, constraints
- `/django-security-audit` - SQL injection, auth, permissions

**Usage:**
- `/django-api-audit` - Full audit of current directory
- `/django-api-audit /path/to/app` - Full audit of specified path
- `/django-api-audit --branch` or `-b` - Audit only Python files changed in current branch
- `/django-api-audit --branch /path/to/app` - Branch audit in specified path

## Audit Philosophy

This audit focuses on **API quality and scalability**. The goal is identifying:
- Serializer inefficiencies that cause N+1 queries
- Missing or weak permission checks
- Endpoints without pagination (time bombs)
- Missing rate limiting on sensitive endpoints
- Inconsistent API patterns across versions

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

# Verify Django project with DRF
if [[ ! -f "$APP_PATH/manage.py" ]]; then
    echo "❌ No Django project found at: $APP_PATH"
    exit 1
fi
```

### 0.1 Eligibility Check (Quick - use haiku)

Before running a full audit, verify this audit is appropriate:

**Skip audit if:**
- No manage.py file found (not a Django project)
- No settings.py file found in common locations
- No Django or DRF dependencies detected

If skipping, output: "⏭️ Skipping Django API audit - [reason]. This project doesn't appear to need this audit."

```bash
# Quick check for Django project
SETTINGS_FOUND=0
find "$APP_PATH" -name "settings.py" -not -path "*/.venv/*" -not -path "*/venv/*" -not -path "*/node_modules/*" 2>/dev/null | grep -q . && SETTINGS_FOUND=1

DJANGO_DEPS=0
if [[ -f "$APP_PATH/requirements.txt" ]]; then
    grep -qE "^django==|^djangorestframework==|^Django==|^djangorestframework" "$APP_PATH/requirements.txt" 2>/dev/null && DJANGO_DEPS=1
fi

if [[ ! -f "$APP_PATH/manage.py" ]] && [[ "$SETTINGS_FOUND" -eq 0 ]]; then
    echo "⏭️ Skipping Django API audit - no Django project detected. No manage.py or settings.py found."
    exit 0
fi

if [[ "$DJANGO_DEPS" -eq 0 ]] && [[ -f "$APP_PATH/requirements.txt" ]]; then
    echo "⏭️ Skipping Django API audit - no Django/DRF dependencies found in requirements.txt."
    exit 0
fi

echo "✓ Django project detected - proceeding with audit"
```

```bash
# Branch mode setup
if [[ "$BRANCH_MODE" == true ]]; then
    CURRENT_BRANCH=$(git branch --show-current)
    BASE_BRANCH="main"

    # Get changed Python files (excluding tests, migrations, venv)
    CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null | grep -E '\.py$' | grep -v "test" | grep -v "migration" | grep -v ".venv" | grep -v "venv/")

    if [[ -z "$CHANGED_FILES" ]]; then
        echo "⚠️  No relevant Python files changed compared to $BASE_BRANCH"
        echo "   (Excluding: tests, migrations, venv)"
        echo ""
        echo "   Run without --branch for full audit"
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

    # Helper function for branch-aware searching
    search_files() {
        local pattern="$1"
        local file_filter="${2:-}"  # Optional: serializer, view, model, etc.

        if [[ -n "$file_filter" ]]; then
            echo "$CHANGED_FILES" | grep -i "$file_filter" | xargs grep -n "$pattern" 2>/dev/null
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
        local file_filter="${2:-*.py}"

        grep -rn "$pattern" --include="$file_filter" "$APP_PATH" 2>/dev/null | grep -v ".venv" | grep -v "test"
    }

    count_matches() {
        search_files "$1" "$2" | wc -l | tr -d ' '
    }
fi

# Get DRF version
DRF_VERSION=$(grep -E "djangorestframework" "$APP_PATH/requirements.txt" | head -1)
echo "📦 $DRF_VERSION"

# Check for GraphQL
grep -q "graphene" "$APP_PATH/requirements.txt" && echo "📊 GraphQL (graphene) detected"

# Count API files
if [[ "$BRANCH_MODE" == true ]]; then
    VIEWSET_COUNT=$(echo "$CHANGED_FILES" | xargs grep -l "ViewSet\|APIView" 2>/dev/null | wc -l | tr -d ' ')
    SERIALIZER_COUNT=$(echo "$CHANGED_FILES" | xargs grep -l "Serializer" 2>/dev/null | wc -l | tr -d ' ')
else
    VIEWSET_COUNT=$(grep -rln "ViewSet\|APIView" --include="*.py" "$APP_PATH" | grep -v ".venv" | wc -l)
    SERIALIZER_COUNT=$(grep -rln "Serializer" --include="*.py" "$APP_PATH" | grep -v ".venv" | wc -l)
fi
echo "🔌 ViewSets/Views: $VIEWSET_COUNT files"
echo "📝 Serializers: $SERIALIZER_COUNT files"
```

**Note on Branch Mode:** When using `--branch`, use `search_files "pattern" "file_filter"` instead of raw grep commands. The file_filter is optional and matches filenames (e.g., "serializer", "view").

### 1. **Serializer Efficiency Audit**

#### 1.1 SerializerMethodField Analysis

```bash
# Find all SerializerMethodField - each is a potential N+1
grep -rn "SerializerMethodField" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Find the corresponding methods
grep -rn "def get_" --include="*serializer*.py" "$APP_PATH" | grep -v ".venv"
```

**Check each method for:**
- Database queries (`.objects.`, `.filter()`, `.get()`)
- Related object access without prefetch
- Aggregations (`.count()`, `.sum()`)

#### 1.2 Nested Serializer Analysis

```bash
# Find nested serializers (can cause N+1 without prefetch)
grep -rn "Serializer(many=True\|Serializer()" --include="*serializer*.py" "$APP_PATH" | grep -v ".venv"

# Check if corresponding ViewSets prefetch
grep -rn "prefetch_related\|select_related" --include="*view*.py" "$APP_PATH" | grep -v ".venv"
```

#### 1.3 Serializer Field Efficiency

```bash
# Find serializers with many fields (might be over-fetching)
grep -rn "class Meta:" -A 5 --include="*serializer*.py" "$APP_PATH" | grep "fields\s*=" | grep -v ".venv"

# Find serializers using fields = '__all__' (security risk + over-fetching)
grep -rn "fields.*=.*'__all__'\|fields.*=.*\"__all__\"" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

### 2. **ViewSet/View Audit**

#### 2.1 QuerySet Optimization

```bash
# Find ViewSets without optimized querysets
grep -rn "class.*ViewSet\|class.*APIView" -A 30 --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -E "queryset\s*=|def get_queryset" | head -30

# Find get_queryset methods
grep -rn "def get_queryset" -A 10 --include="*.py" "$APP_PATH" | grep -v ".venv" | head -40
```

**Check each ViewSet for:**
- `queryset = Model.objects.all()` (should use `get_queryset()`)
- `get_queryset()` without `select_related`/`prefetch_related`
- Missing filtering by user/organization

#### 2.2 Action Methods

```bash
# Find custom actions
grep -rn "@action" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Find actions without explicit permission_classes
grep -rn "@action" -A 3 --include="*.py" "$APP_PATH" | grep -v "permission_classes" | grep -v ".venv" | head -20
```

#### 2.3 View Complexity

```bash
# Find large view files (potential fat views)
find "$APP_PATH" -name "*view*.py" -not -path "*/.venv/*" -exec wc -l {} + | sort -n | tail -10

# Find views with too much logic (should use facades)
grep -rn "def create\|def update\|def perform_create\|def perform_update" -A 20 --include="*view*.py" "$APP_PATH" | grep -v ".venv" | head -50
```

### 3. **Permission Audit**

#### 3.1 Permission Classes

```bash
# Find ViewSets with permission_classes
grep -rn "permission_classes" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test"

# Find ViewSets WITHOUT permission_classes (dangerous)
for f in $(grep -rln "class.*ViewSet\|class.*APIView" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test"); do
    grep -L "permission_classes" "$f" 2>/dev/null
done
```

#### 3.2 Object-Level Permissions

```bash
# Check for object permission checks
grep -rn "has_object_permission\|check_object_permissions\|get_object" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Check for Django Guardian usage
grep -rn "guardian\|ObjectPermissionChecker\|assign_perm\|remove_perm" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

#### 3.3 Permission in Facades

```bash
# Check if facades validate permissions (your pattern)
grep -rn "class.*Facade" -A 30 --include="*.py" "$APP_PATH" | grep -E "permission|has_perm|can_" | grep -v ".venv"
```

### 4. **Pagination Audit**

#### 4.1 Global Pagination Settings

```bash
# Check settings for default pagination
grep -rn "DEFAULT_PAGINATION_CLASS\|PAGE_SIZE" --include="settings*.py" "$APP_PATH" | grep -v ".venv"
```

#### 4.2 Per-View Pagination

```bash
# Find views with custom pagination
grep -rn "pagination_class" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Find list actions without pagination (dangerous for large datasets)
grep -rn "def list\|action.*detail=False" --include="*view*.py" "$APP_PATH" | grep -v ".venv"
```

### 5. **Rate Limiting Audit**

#### 5.1 Throttling Configuration

```bash
# Check for throttle settings
grep -rn "DEFAULT_THROTTLE\|throttle_classes\|THROTTLE_RATES" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

#### 5.2 Sensitive Endpoints

```bash
# Find auth-related endpoints (should be throttled)
grep -rn "login\|password\|token\|auth" --include="*view*.py" --include="*url*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test"
```

### 6. **GraphQL Audit** (if applicable)

#### 6.1 N+1 in Resolvers

```bash
# Find resolver methods
grep -rn "def resolve_" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Check for DataLoader usage
grep -rn "DataLoader\|dataloader" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

#### 6.2 Query Depth

```bash
# Check for query depth limiting
grep -rn "depth\|max_depth\|DepthLimitValidation" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

### 7. **API Versioning Audit**

```bash
# Find version indicators in URLs
grep -rn "v1/\|v2/\|v3/" --include="*url*.py" "$APP_PATH" | grep -v ".venv"

# Check for versioning configuration
grep -rn "DEFAULT_VERSIONING_CLASS\|ALLOWED_VERSIONS" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

### 8. **Error Handling Audit**

```bash
# Custom exception handlers
grep -rn "EXCEPTION_HANDLER\|exception_handler" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Check for bare except or generic exception handling
grep -rn "except:\|except Exception:" --include="*view*.py" "$APP_PATH" | grep -v ".venv"
```

### 9. **Generate Report**

```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
AUDIT_DIR="${REPORT_BASE}/audits/django-api-$(basename $APP_PATH)-$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"
```

#### Report Structure:

```markdown
# Django API Audit Report

**Application:** [App Name]
**Date:** [Audit Date]
**DRF Version:** [Version]

## Executive Summary

### API Health Score: [A-F]

| Category | Score | Critical Issues |
|----------|-------|-----------------|
| Serializer Efficiency | | |
| Permissions | | |
| Pagination | | |
| Rate Limiting | | |

### Top 3 API Risks

1. **[Risk]** - [Impact] - [Location]
2. **[Risk]** - [Impact] - [Location]
3. **[Risk]** - [Impact] - [Location]

## Detailed Findings

### Serializer Efficiency

#### SerializerMethodField Audit
| Serializer | Method | Has DB Query | Fix |
|------------|--------|--------------|-----|
| | get_foo | Yes - .filter() | Add to prefetch |

#### fields = '__all__' Usage
| Serializer | Risk | Fix |
|------------|------|-----|
| | Exposes all fields | Explicit field list |

#### Nested Serializer N+1
| Parent Serializer | Nested | ViewSet Prefetches? |
|-------------------|--------|---------------------|
| | | |

### Permission Analysis

#### ViewSets Without Permissions
| ViewSet | File | Risk |
|---------|------|------|
| | | Public access |

#### Missing Object Permissions
| ViewSet | get_object() | has_object_permission |
|---------|--------------|----------------------|
| | | |

### Pagination Coverage

| Endpoint Type | Has Pagination | Risk |
|---------------|----------------|------|
| List views | | |
| Custom actions | | |

### Rate Limiting

| Endpoint | Throttled | Recommended |
|----------|-----------|-------------|
| /auth/login | No | 5/min |
| /password/reset | No | 3/min |

### GraphQL (if applicable)

#### DataLoader Usage
- Resolvers with queries: [count]
- Using DataLoader: [count]
- N+1 risk: [High/Medium/Low]

## Action Items

### Immediate (P0)
1. [ ] Add permission_classes to [ViewSet]
2. [ ] Add throttling to auth endpoints

### Short-term (P1)
1. [ ] Add prefetch_related for [nested serializer]
2. [ ] Remove fields='__all__' from [serializer]
3. [ ] Add pagination to [endpoint]

### Long-term (P2)
1. [ ] Implement DataLoaders for GraphQL
2. [ ] Consolidate API versions

---
**Audit Complete:** [Date/Time]
```

## Performance Testing

```python
# Test serializer query count
from django.test.utils import CaptureQueriesContext
from django.db import connection

with CaptureQueriesContext(connection) as context:
    serializer = MySerializer(instance=my_queryset, many=True)
    data = serializer.data  # Force evaluation
print(f"Queries for {len(my_queryset)} items: {len(context)}")
# Should be O(1) or O(prefetch_count), not O(n)
```
