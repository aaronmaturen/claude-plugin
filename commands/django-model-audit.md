---
description: "Audit a Django application's model layer for N+1 queries, missing indexes, data integrity issues, and query optimization opportunities."
argument-hint: "[app-path]"
---
# Django Model & Query Audit

Audit a Django application's model layer for N+1 queries, missing indexes, data integrity issues, and query optimization opportunities.

**Related audits:**
- `/django-api-audit` - Serializers, permissions, pagination
- `/django-security-audit` - SQL injection, auth, permissions

**Usage:**
- `/django-model-audit` - Full audit of current directory
- `/django-model-audit /path/to/app` - Full audit of specified path
- `/django-model-audit --branch` or `-b` - Audit only Python files changed in current branch
- `/django-model-audit --branch /path/to/app` - Branch audit in specified path

## Audit Philosophy

This audit focuses on **database performance and data integrity**. The goal is identifying:
- N+1 query patterns that kill performance at scale
- Missing indexes that cause full table scans
- Missing constraints that allow bad data
- Inefficient query patterns that can be optimized

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

# Verify Django project
if [[ ! -f "$APP_PATH/manage.py" ]]; then
    echo "❌ No Django project found at: $APP_PATH"
    exit 1
fi

# Branch mode setup
if [[ "$BRANCH_MODE" == true ]]; then
    CURRENT_BRANCH=$(git branch --show-current)
    BASE_BRANCH="main"

    # Get changed Python files (excluding tests, migrations, venv)
    CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null | grep -E '\.py$' | grep -v "test" | grep -v ".venv" | grep -v "venv/")

    if [[ -z "$CHANGED_FILES" ]]; then
        echo "⚠️  No relevant Python files changed compared to $BASE_BRANCH"
        echo "   (Excluding: tests, venv)"
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

    # Check for model changes specifically
    MODEL_FILES=$(echo "$CHANGED_FILES" | grep -E "models\.py|models/")
    if [[ -n "$MODEL_FILES" ]]; then
        echo "   📊 Model files changed:"
        echo "$MODEL_FILES" | sed 's/^/      - /'
        echo ""
    fi

    # Helper function for branch-aware searching
    search_files() {
        local pattern="$1"
        local file_filter="${2:-}"

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

# Get Django version
DJANGO_VERSION=$(grep -E "Django==|django==" "$APP_PATH/requirements.txt" | head -1)
echo "📦 $DJANGO_VERSION"

# Count models
if [[ "$BRANCH_MODE" == true ]]; then
    MODEL_COUNT=$(echo "$CHANGED_FILES" | grep -E "models\.py|models/" | wc -l | tr -d ' ')
    echo "📊 Model files changed: $MODEL_COUNT"
else
    MODEL_COUNT=$(find "$APP_PATH" -name "models.py" -not -path "*/.venv/*" -not -path "*/venv/*" | xargs grep -l "class.*Model" | wc -l)
    echo "📊 Found approximately $MODEL_COUNT apps with models"
fi
```

**Note on Branch Mode:** When using `--branch`, use `search_files "pattern" "file_filter"` instead of raw grep commands. The file_filter is optional and matches filenames (e.g., "model", "serializer").

### 1. **N+1 Query Pattern Detection**

#### 1.1 Loop-Based Queries

```bash
# Find loops that might cause N+1 queries
# Pattern: for x in queryset: x.related_field
grep -rn "for .* in .*\.objects\|for .* in .*_set\|for .* in .*\.all()" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test"
```

**Red flags to check manually:**
- `for item in queryset:` followed by `item.foreign_key.field`
- Nested loops with ORM calls
- List comprehensions with ORM access

#### 1.2 Serializer Method Fields

```bash
# SerializerMethodField often hides N+1 queries
grep -rn "SerializerMethodField" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Find the methods - check if they query the database
grep -rn "def get_" --include="serializers.py" --include="**/serializers/*.py" "$APP_PATH" | grep -v ".venv"
```

**Check each `get_*` method for:**
- `.objects.filter()` or `.objects.get()`
- `.related_field` access without prefetch
- `.count()` calls

#### 1.3 Missing select_related/prefetch_related

```bash
# Find querysets that might need optimization
grep -rn "\.objects\.all()\|\.objects\.filter(" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test" | grep -v "select_related\|prefetch_related"

# Find existing optimizations (baseline)
grep -rn "select_related\|prefetch_related" --include="*.py" "$APP_PATH" | grep -v ".venv" | wc -l
```

### 2. **Index Analysis**

#### 2.1 Fields Used in Filters

```bash
# Find filter patterns to compare against indexed fields
grep -rn "\.filter(\|\.exclude(\|\.get(\|order_by(" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test" | head -50
```

#### 2.2 Missing db_index

```bash
# Find ForeignKey without db_index (Django indexes FK by default, but check related_name queries)
grep -rn "ForeignKey\|CharField\|DateTimeField\|DateField\|IntegerField" --include="models.py" --include="**/models/*.py" "$APP_PATH" | grep -v ".venv"

# Find fields with db_index=True (baseline)
grep -rn "db_index=True" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

#### 2.3 Composite Indexes

```bash
# Check for Meta.indexes
grep -rn "class Meta:" -A 10 --include="models.py" --include="**/models/*.py" "$APP_PATH" | grep -E "indexes|index_together|unique_together" | grep -v ".venv"
```

**Common missing composite indexes:**
- `(created_by, created_at)` for user activity queries
- `(organization, status)` for filtered lists
- `(user, is_active)` for permission checks

### 3. **Data Integrity Audit**

#### 3.1 Missing Constraints

```bash
# Check for CheckConstraint usage
grep -rn "CheckConstraint\|UniqueConstraint" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Find fields that might need constraints
grep -rn "PositiveIntegerField\|DecimalField\|status.*=\|state.*=" --include="models.py" "$APP_PATH" | grep -v ".venv"
```

**Common missing constraints:**
- Status/state fields without valid choice enforcement
- Numeric fields without range constraints
- Unique together without UniqueConstraint

#### 3.2 Choice Fields

```bash
# Find TextChoices/IntegerChoices (good pattern)
grep -rn "TextChoices\|IntegerChoices" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Find old-style choices (should migrate)
grep -rn "choices=\[" --include="models.py" "$APP_PATH" | grep -v ".venv"
grep -rn "CHOICES\s*=" --include="models.py" "$APP_PATH" | grep -v ".venv"
```

#### 3.3 Nullable Fields

```bash
# Find nullable fields - verify they should be nullable
grep -rn "null=True" --include="models.py" "$APP_PATH" | grep -v ".venv" | head -30

# CharField with null=True (usually wrong - use blank=True, default='')
grep -rn "CharField.*null=True\|TextField.*null=True" --include="models.py" "$APP_PATH" | grep -v ".venv"
```

### 4. **Model Design Audit**

#### 4.1 God Models

```bash
# Find large model files
find "$APP_PATH" -name "models.py" -not -path "*/.venv/*" -exec wc -l {} + | sort -n | tail -10

# Find models with many fields
grep -rn "class.*models.Model" --include="models.py" "$APP_PATH" | grep -v ".venv"
```

**Flag models with:**
- More than 30 fields
- More than 10 foreign keys
- Mixed concerns (e.g., User with billing fields)

#### 4.2 Missing Model Methods

```bash
# Find models without __str__
for f in $(find "$APP_PATH" -name "models.py" -not -path "*/.venv/*"); do
    grep -L "__str__" "$f" 2>/dev/null
done

# Find models without Meta class
grep -rn "class.*models.Model" -A 20 --include="models.py" "$APP_PATH" | grep -v "class Meta" | grep -v ".venv" | head -20
```

#### 4.3 Abstract Base Classes

```bash
# Check for abstract model usage
grep -rn "abstract = True\|class Meta:.*abstract" --include="models.py" "$APP_PATH" | grep -v ".venv"

# Check for model inheritance
grep -rn "class.*([A-Z][a-zA-Z]*Model)" --include="models.py" "$APP_PATH" | grep -v ".venv" | head -20
```

### 5. **Migration Health**

```bash
# Count migrations per app
find "$APP_PATH" -path "*/migrations/*.py" -not -name "__init__.py" -not -path "*/.venv/*" | cut -d'/' -f1-3 | sort | uniq -c | sort -rn | head -20

# Find squash candidates (apps with many migrations)
# Apps with > 50 migrations should consider squashing
```

### 6. **Generate Report**

```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
AUDIT_DIR="${REPORT_BASE}/audits/django-model-$(basename $APP_PATH)-$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"
```

#### Report Structure:

```markdown
# Django Model Audit Report

**Application:** [App Name]
**Date:** [Audit Date]
**Django Version:** [Version]

## Executive Summary

### Model Health Score: [A-F]

| Category | Score | Critical Issues |
|----------|-------|-----------------|
| N+1 Queries | | |
| Index Coverage | | |
| Data Integrity | | |
| Model Design | | |

### Top 3 Performance Risks

1. **[Risk]** - [Impact] - [Location]
2. **[Risk]** - [Impact] - [Location]
3. **[Risk]** - [Impact] - [Location]

## Detailed Findings

### N+1 Query Patterns

#### High-Risk Patterns Found
| File | Line | Pattern | Fix |
|------|------|---------|-----|
| | | | |

#### SerializerMethodField Audit
| Serializer | Method | Has Query | Fix |
|------------|--------|-----------|-----|
| | | | |

### Index Analysis

#### Recommended Indexes
| Model | Field(s) | Reason |
|-------|----------|--------|
| | | Filter in [view] |
| | | Order by in [view] |

#### Existing Indexes
[Count] fields with db_index=True
[Count] composite indexes

### Data Integrity

#### Missing Constraints
| Model | Field | Suggested Constraint |
|-------|-------|---------------------|
| | status | CheckConstraint for valid values |

#### Nullable Field Review
| Model | Field | Should Be Nullable? |
|-------|-------|---------------------|
| | | |

### Model Design Issues

#### Large Models
| Model | Fields | Recommendation |
|-------|--------|----------------|
| | | Consider splitting |

#### Missing Patterns
- [ ] Models without __str__: [list]
- [ ] Models without Meta.ordering: [list]

## Action Items

### Immediate (P0)
1. [ ] Add select_related to [queryset]
2. [ ] Add index to [field]

### Short-term (P1)
1. [ ] Add CheckConstraint to [model.field]
2. [ ] Migrate choices to TextChoices

### Long-term (P2)
1. [ ] Squash migrations for [app]
2. [ ] Split [god model]

---
**Audit Complete:** [Date/Time]
```

## Query Analysis Helpers

Run these in Django shell for deeper analysis:

```python
# Find slow queries
from django.db import connection
connection.queries  # After enabling DEBUG=True

# Analyze a specific queryset
from django.db import connection
from django.test.utils import CaptureQueriesContext

with CaptureQueriesContext(connection) as context:
    list(MyModel.objects.filter(...))  # Force evaluation
print(f"Queries: {len(context)}")
for q in context:
    print(q['sql'][:200])
```
