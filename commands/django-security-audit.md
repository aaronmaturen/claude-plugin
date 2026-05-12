---
description: "Audit a Django application for security vulnerabilities including SQL injection, authentication weaknesses, permission bypasses, and OWASP Top 10 issues."
argument-hint: "[app-path]"
---
# Django Security Audit

Audit a Django application for security vulnerabilities including SQL injection, authentication weaknesses, permission bypasses, and OWASP Top 10 issues.

**Related audits:**
- `/django-model-audit` - Query optimization, indexes, constraints
- `/django-api-audit` - Serializers, permissions, pagination

**Usage:**
- `/django-security-audit` - Full audit of current directory
- `/django-security-audit /path/to/app` - Full audit of specified path
- `/django-security-audit --branch` or `-b` - Audit only Python files changed in current branch
- `/django-security-audit --branch /path/to/app` - Branch audit in specified path

## Audit Philosophy

This audit focuses on **security vulnerabilities that could lead to data breaches or unauthorized access**. The goal is identifying:
- SQL injection vectors
- Authentication and session weaknesses
- Authorization bypasses
- Sensitive data exposure
- Security misconfigurations

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

    # Get ALL changed Python files for security audit (including tests - might expose secrets)
    CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null | grep -E '\.py$' | grep -v ".venv" | grep -v "venv/")

    if [[ -z "$CHANGED_FILES" ]]; then
        echo "⚠️  No Python files changed compared to $BASE_BRANCH"
        echo ""
        echo "   Run without --branch for full audit"
        exit 0
    fi

    echo "🌿 BRANCH MODE: Security audit of files changed in current branch"
    echo "   Branch: $CURRENT_BRANCH"
    echo "   Comparing to: $BASE_BRANCH"
    echo "   Files to audit: $(echo "$CHANGED_FILES" | wc -l | tr -d ' ')"
    echo ""
    echo "   ⚠️  Security audits should periodically run full scans"
    echo ""
    echo "   Changed files:"
    echo "$CHANGED_FILES" | sed 's/^/   - /'
    echo ""

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

        grep -rn "$pattern" --include="$file_filter" "$APP_PATH" 2>/dev/null | grep -v ".venv"
    }

    count_matches() {
        search_files "$1" "$2" | wc -l | tr -d ' '
    }
fi

# Get Django version (check for known vulnerabilities)
DJANGO_VERSION=$(grep -E "Django==|django==" "$APP_PATH/requirements.txt" | head -1)
echo "📦 $DJANGO_VERSION"

# Check for security-related packages
grep -q "django-guardian" "$APP_PATH/requirements.txt" && echo "🔐 Object permissions: django-guardian"
grep -q "djangorestframework-simplejwt" "$APP_PATH/requirements.txt" && echo "🔑 JWT auth detected"
grep -q "django-axes" "$APP_PATH/requirements.txt" && echo "🛡️ Brute force protection: django-axes"
grep -q "django-csp" "$APP_PATH/requirements.txt" && echo "🛡️ CSP headers: django-csp"
```

**Note on Branch Mode:** Security audits in branch mode check only changed files. Run periodic full audits to catch issues in unchanged code. Use `search_files "pattern"` instead of raw grep commands.

### 1. **SQL Injection Audit**

#### 1.1 Raw SQL Usage

```bash
# Find raw SQL - highest risk
grep -rn "\.raw(\|\.extra(\|cursor\.execute\|RawSQL" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test"

# Find string formatting in queries (SQL injection risk)
grep -rn "\.filter(.*%s\|\.filter(.*\.format\|\.filter(.*f\"" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Find QuerySet.extra() usage (deprecated, risky)
grep -rn "\.extra(" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

**Critical check:** Any user input flowing into `.raw()`, `.extra()`, or `cursor.execute()`

#### 1.2 Safe Query Patterns

```bash
# Verify parameterized queries
grep -rn "cursor\.execute.*%s\|cursor\.execute.*\?" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Check for ORM usage (safe by default)
grep -rn "\.filter(\|\.exclude(\|\.get(" --include="*.py" "$APP_PATH" | grep -v ".venv" | wc -l
```

### 2. **Authentication Audit**

#### 2.1 Password Handling

```bash
# Find password-related code
grep -rn "password\|PASSWORD" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test" | grep -v "migration"

# Check for password in logs (critical vulnerability)
grep -rn "logger.*password\|print.*password\|log.*password" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Check for hardcoded passwords/secrets
grep -rn "password\s*=\s*[\"']\|secret\s*=\s*[\"']\|api_key\s*=\s*[\"']" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test"
```

#### 2.2 Session Security

```bash
# Check session settings
grep -rn "SESSION_\|CSRF_\|SECURE_" --include="settings*.py" "$APP_PATH" | grep -v ".venv"
```

**Required settings:**
```python
SESSION_COOKIE_SECURE = True  # HTTPS only
SESSION_COOKIE_HTTPONLY = True  # No JS access
CSRF_COOKIE_SECURE = True  # HTTPS only
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
```

#### 2.3 JWT Security (if applicable)

```bash
# Check JWT settings
grep -rn "SIMPLE_JWT\|JWT_" --include="settings*.py" "$APP_PATH" | grep -v ".venv"

# Check token lifetime
grep -rn "ACCESS_TOKEN_LIFETIME\|REFRESH_TOKEN_LIFETIME" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

### 3. **Authorization Audit**

#### 3.1 Missing Permission Checks

```bash
# Find views without authentication
grep -rn "authentication_classes\s*=\s*\[\]" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Find views with AllowAny
grep -rn "AllowAny" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test"

# Find views without permission_classes
for f in $(grep -rln "class.*ViewSet\|class.*APIView" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test"); do
    if ! grep -q "permission_classes" "$f"; then
        echo "NO PERMISSIONS: $f"
    fi
done
```

#### 3.2 IDOR Vulnerabilities (Insecure Direct Object Reference)

```bash
# Find direct ID usage in URLs without permission check
grep -rn "pk=\|id=\|<int:pk>\|<int:id>" --include="*url*.py" --include="*view*.py" "$APP_PATH" | grep -v ".venv"

# Check get_object implementations
grep -rn "def get_object" -A 10 --include="*.py" "$APP_PATH" | grep -v ".venv" | head -50
```

**Check each `get_object()` for:**
- Filter by user/organization
- Permission check before returning

#### 3.3 Object-Level Permission Gaps

```bash
# Find queryset filters (should include user/org)
grep -rn "def get_queryset" -A 15 --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test" | head -60

# Check for request.user filtering
grep -rn "request\.user\|self\.request\.user" --include="*view*.py" "$APP_PATH" | grep -v ".venv" | wc -l
```

### 4. **Sensitive Data Exposure**

#### 4.1 Serializer Field Exposure

```bash
# Find fields='__all__' (exposes all fields)
grep -rn "fields.*=.*'__all__'" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Check for sensitive field names in serializers
grep -rn "password\|ssn\|social_security\|credit_card\|secret\|token" --include="*serializer*.py" "$APP_PATH" | grep -v ".venv"
```

#### 4.2 Logging Sensitive Data

```bash
# Find logging statements with sensitive data
grep -rn "logger\.\|logging\.\|print(" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "test" | grep -Ei "password|token|secret|key|ssn|credit" | head -20
```

#### 4.3 Error Message Exposure

```bash
# Check DEBUG setting
grep -rn "DEBUG\s*=" --include="settings*.py" "$APP_PATH" | grep -v ".venv"

# Check for detailed error responses
grep -rn "traceback\|exc_info\|exception\|str(e)" --include="*view*.py" "$APP_PATH" | grep -v ".venv"
```

### 5. **Input Validation Audit**

#### 5.1 File Upload Security

```bash
# Find file upload handling
grep -rn "FileField\|ImageField\|request\.FILES\|InMemoryUploadedFile" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Check for file type validation
grep -rn "content_type\|file\.name\|\.extension" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

**Check for:**
- File type validation (not just extension)
- File size limits
- Storage outside webroot
- Filename sanitization

#### 5.2 Serializer Validation

```bash
# Find custom validators
grep -rn "def validate\|validators=" --include="*serializer*.py" "$APP_PATH" | grep -v ".venv"

# Find serializers without validation
grep -rn "class Meta:" -A 5 --include="*serializer*.py" "$APP_PATH" | grep -v "validators\|validate" | grep -v ".venv" | head -30
```

### 6. **CSRF Protection**

```bash
# Check for CSRF exemptions
grep -rn "csrf_exempt\|@csrf_exempt" --include="*.py" "$APP_PATH" | grep -v ".venv"

# Check CSRF middleware
grep -rn "CsrfViewMiddleware" --include="settings*.py" "$APP_PATH" | grep -v ".venv"
```

### 7. **Security Headers**

```bash
# Check security middleware
grep -rn "SecurityMiddleware\|XFrameOptionsMiddleware" --include="settings*.py" "$APP_PATH" | grep -v ".venv"

# Check for custom security headers
grep -rn "X-Frame-Options\|X-Content-Type-Options\|Content-Security-Policy" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

### 8. **Dependency Vulnerabilities**

```bash
# Check for known vulnerable packages (manual check needed)
cat "$APP_PATH/requirements.txt" | grep -v "^#" | grep -v "^$"

# Suggest running safety check
echo "Run: pip install safety && safety check -r requirements.txt"
```

### 9. **Environment & Secrets**

```bash
# Check for secrets in code
grep -rn "SECRET_KEY\|AWS_SECRET\|API_KEY\|PRIVATE_KEY" --include="*.py" "$APP_PATH" | grep -v ".venv" | grep -v "environ\|getenv\|os\.environ"

# Check for .env in gitignore
grep -q "\.env" "$APP_PATH/.gitignore" && echo "✓ .env in .gitignore" || echo "⚠️ .env NOT in .gitignore"

# Check for hardcoded URLs (might contain secrets)
grep -rn "https://.*@\|://.*:.*@" --include="*.py" "$APP_PATH" | grep -v ".venv"
```

### 10. **Generate Report**

```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
AUDIT_DIR="${REPORT_BASE}/audits/django-security-$(basename $APP_PATH)-$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"
```

#### Report Structure:

```markdown
# Django Security Audit Report

**Application:** [App Name]
**Date:** [Audit Date]
**Django Version:** [Version]
**Auditor:** Claude

## Executive Summary

### Security Score: [A-F]

| Category | Score | Critical Issues |
|----------|-------|-----------------|
| SQL Injection | | |
| Authentication | | |
| Authorization | | |
| Data Exposure | | |
| Input Validation | | |

### Critical Vulnerabilities (Fix Immediately)

1. **[Vuln]** - [Location] - [Impact]
2. **[Vuln]** - [Location] - [Impact]

## Detailed Findings

### SQL Injection

#### Raw SQL Usage
| File | Line | Pattern | Risk |
|------|------|---------|------|
| | | .raw() | High if user input |

#### Recommendation
- Replace `.raw()` with ORM queries
- Use parameterized queries for necessary raw SQL

### Authentication

#### Session Security
| Setting | Value | Recommended |
|---------|-------|-------------|
| SESSION_COOKIE_SECURE | | True |
| SESSION_COOKIE_HTTPONLY | | True |
| CSRF_COOKIE_SECURE | | True |

#### Password Security
- [ ] Passwords logged anywhere: [Yes/No]
- [ ] Hardcoded credentials: [Yes/No]

### Authorization

#### Views Without Permissions
| ViewSet/View | File | Risk |
|--------------|------|------|
| | | Unauthorized access |

#### IDOR Vulnerabilities
| Endpoint | Filters by User? | Object Permission? |
|----------|------------------|-------------------|
| /api/v1/items/{id} | | |

### Sensitive Data Exposure

#### Serializers Exposing Sensitive Fields
| Serializer | Field | Risk |
|------------|-------|------|
| | password | Critical |

#### fields='__all__' Usage
| Serializer | Should Restrict |
|------------|-----------------|
| | |

### Input Validation

#### File Upload Security
| Location | Type Check | Size Limit | Sanitize Name |
|----------|------------|------------|---------------|
| | | | |

### Security Headers

| Header | Status |
|--------|--------|
| X-Frame-Options | |
| X-Content-Type-Options | |
| Content-Security-Policy | |
| Strict-Transport-Security | |

### Dependencies

Run `safety check -r requirements.txt` for vulnerability scan.

Known issues in current dependencies:
- [List any known CVEs]

## Action Items

### Critical (Fix Today)
1. [ ] [Action]

### High (Fix This Week)
1. [ ] [Action]

### Medium (Fix This Sprint)
1. [ ] [Action]

### Low (Backlog)
1. [ ] [Action]

## Security Checklist

- [ ] All ViewSets have permission_classes
- [ ] No raw SQL with user input
- [ ] Session cookies are secure
- [ ] No sensitive data in logs
- [ ] File uploads validated
- [ ] CSRF protection enabled
- [ ] DEBUG=False in production
- [ ] Secrets in environment variables

---
**Audit Complete:** [Date/Time]
**Classification:** Internal Use Only
```

## OWASP Top 10 Reference

| Risk | Django Relevance |
|------|------------------|
| A01 Broken Access Control | permission_classes, get_queryset filters |
| A02 Cryptographic Failures | SESSION_COOKIE_SECURE, HTTPS |
| A03 Injection | .raw(), .extra(), cursor.execute() |
| A04 Insecure Design | Business logic in facades |
| A05 Security Misconfiguration | DEBUG, ALLOWED_HOSTS, CORS |
| A06 Vulnerable Components | requirements.txt, safety check |
| A07 Auth Failures | JWT config, session settings |
| A08 Data Integrity | CSRF, signed cookies |
| A09 Logging Failures | Sensitive data in logs |
| A10 SSRF | URL validation on user input |
