# Self Review - Ultra-Think Code Quality Check

Perform a comprehensive self-review of changes compared to main branch, checking for code quality, conventions adherence, potential issues, and documenting complex decisions.

## Review Process:

### 1. **Change Analysis**
```bash
# Get current branch and compare with main
CURRENT_BRANCH=$(git branch --show-current)
echo "🔍 Reviewing changes on branch: $CURRENT_BRANCH"
echo ""

# Show comprehensive diff stats
echo "=== Change Summary ==="
git diff main --stat
echo ""

# Show file-by-file changes
echo "=== Files Modified ==="
git diff main --name-status | while read status file; do
    case "$status" in
        A) echo "➕ Added: $file" ;;
        M) echo "✏️  Modified: $file" ;;
        D) echo "❌ Deleted: $file" ;;
        R*) echo "🔄 Renamed: $file" ;;
    esac
done
echo ""

# Show commit history on this branch
echo "=== Commits on Branch ==="
git log main..HEAD --oneline --graph
echo ""
```

### 2. **Convention Adherence Check**
```bash
echo "=== Convention Compliance Analysis ==="

# Check for common convention violations
VIOLATIONS=()

# Check for unwanted files
if git diff main --name-only | grep -E "\.(log|tmp|cache|DS_Store)$"; then
    VIOLATIONS+=("⚠️  Temporary or system files detected")
fi

# Check for large files
git diff main --name-only | while read file; do
    if [[ -f "$file" ]] && [[ $(wc -c < "$file") -gt 100000 ]]; then
        VIOLATIONS+=("📦 Large file detected: $file (>100KB)")
    fi
done

# Check for potential secrets or keys
if git diff main | grep -i -E "(api[_-]?key|secret|password|token)" | grep -v "# " | grep -v "example"; then
    VIOLATIONS+=("🔐 Potential secrets/keys detected in diff")
fi

# Check for debug code
if git diff main | grep -E "(console\.log|debugger|TODO|FIXME|XXX)" | head -10; then
    VIOLATIONS+=("🐛 Debug code or TODOs detected")
fi

# Check for proper branch naming (if not on main)
if [[ "$CURRENT_BRANCH" != "main" ]] && [[ ! "$CURRENT_BRANCH" =~ ^(PRO|BUG)-[0-9]+ ]]; then
    VIOLATIONS+=("🌿 Branch name doesn't follow PRO-#### or BUG-#### pattern")
fi

# Display violations
if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
    echo "🚨 Convention Issues Found:"
    printf '%s\n' "${VIOLATIONS[@]}"
    echo ""
else
    echo "✅ No obvious convention violations detected"
    echo ""
fi
```

### 3. **Code Quality Analysis**
Ask Claude to analyze the changes with this detailed prompt:

**Claude, please perform an ultra-comprehensive analysis of the git diff against main. Focus on:**

**Technical Quality:**
- Code complexity and maintainability
- Performance implications of changes
- Security considerations
- Error handling patterns
- Resource management (memory, connections, etc.)

**Architecture & Design:**
- Adherence to existing patterns in the codebase
- Separation of concerns
- Code reusability and DRY principles
- API design consistency
- Database schema changes impact

**Testing & Reliability:**
- What tests are needed for these changes?
- Are there edge cases not covered?
- Could these changes break existing functionality?
- Are there race conditions or concurrency issues?

**Documentation & Maintainability:**
- Do complex algorithms need explanations?
- Are public APIs properly documented?
- Would a future developer understand this code?
- Are variable/function names self-documenting?

**Convention Compliance:**
- Does the code follow our established patterns?
- Consistent formatting and style?
- Proper error handling patterns?
- Following TypeScript/Angular conventions (if applicable)?

**Risk Assessment:**
- What could go wrong with these changes?
- Are there deployment considerations?
- Any breaking changes or migration needs?
- Database migration safety?

Please be brutally honest and flag anything that seems concerning, even if minor. Better to catch issues now than in production.

### 4. **Generate Review Report**
```bash
echo "=== Self Review Report ==="
echo "**Branch:** $CURRENT_BRANCH"
echo "**Date:** $(date '+%Y-%m-%d %H:%M')"
echo "**Files Changed:** $(git diff main --name-only | wc -l)"
echo "**Lines Changed:** +$(git diff main --shortstat | grep -o '[0-9]* insertion' | cut -d' ' -f1 || echo 0) -$(git diff main --shortstat | grep -o '[0-9]* deletion' | cut -d' ' -f1 || echo 0)"
echo ""

# Ask user if they want to save the review to a file
read -p "💾 Save detailed review to file? (y/N): " save_review
if [[ "$save_review" =~ ^[Yy] ]]; then
    REVIEW_FILE="self-review-$(date +%Y%m%d-%H%M).md"
    echo "# Self Review Report" > "$REVIEW_FILE"
    echo "" >> "$REVIEW_FILE"
    echo "**Branch:** $CURRENT_BRANCH" >> "$REVIEW_FILE"
    echo "**Date:** $(date '+%Y-%m-%d %H:%M')" >> "$REVIEW_FILE"
    echo "**Reviewer:** Claude + Self" >> "$REVIEW_FILE"
    echo "" >> "$REVIEW_FILE"
    
    echo "## Changes Summary" >> "$REVIEW_FILE"
    echo "\`\`\`" >> "$REVIEW_FILE"
    git diff main --stat >> "$REVIEW_FILE"
    echo "\`\`\`" >> "$REVIEW_FILE"
    echo "" >> "$REVIEW_FILE"
    
    echo "## Commits" >> "$REVIEW_FILE"
    git log main..HEAD --oneline >> "$REVIEW_FILE"
    echo "" >> "$REVIEW_FILE"
    
    echo "## Claude Analysis" >> "$REVIEW_FILE"
    echo "*Claude's detailed analysis will be added here*" >> "$REVIEW_FILE"
    echo "" >> "$REVIEW_FILE"
    
    echo "## Action Items" >> "$REVIEW_FILE"
    echo "- [ ] Address any flagged issues" >> "$REVIEW_FILE"
    echo "- [ ] Add missing tests" >> "$REVIEW_FILE"
    echo "- [ ] Update documentation" >> "$REVIEW_FILE"
    echo "" >> "$REVIEW_FILE"
    
    echo "📝 Review template saved to: $REVIEW_FILE"
    echo "   Add Claude's analysis and your own notes to complete the review."
fi
```

### 5. **Actionable Recommendations**
Based on Claude's analysis, provide:

**Immediate Actions (Must Fix):**
- Critical bugs or security issues
- Convention violations
- Breaking changes

**Recommended Improvements (Should Fix):**
- Code quality improvements
- Missing tests
- Documentation gaps
- Performance optimizations

**Optional Enhancements (Nice to Have):**
- Refactoring opportunities
- Additional safeguards
- Future-proofing suggestions

### 6. **Decision Documentation**
For complex or non-obvious changes, document:

**Why was this approach chosen?**
- Alternative approaches considered
- Trade-offs made
- Performance/complexity decisions

**What makes this tricky?**
- Complex algorithms explained
- Non-obvious business logic
- Integration challenges

**Future considerations:**
- Technical debt incurred
- Scalability implications
- Maintenance notes

## Example Usage:
```bash
/atm-self-review

🔍 Reviewing changes on branch: PRO-1234-user-auth-flow

=== Change Summary ===
 src/auth/AuthService.ts    | 45 ++++++++++++++++++++++++++++++
 src/auth/types.ts          | 12 +++++++++
 src/components/Login.tsx   | 67 ++++++++++++++++++++++++++++++++++++++++++
 tests/auth.test.ts         | 89 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 213 insertions(+)

=== Files Modified ===
➕ Added: src/auth/AuthService.ts
➕ Added: src/auth/types.ts  
➕ Added: src/components/Login.tsx
➕ Added: tests/auth.test.ts

=== Commits on Branch ===
* a1b2c3d Add authentication service with JWT support
* d4e5f6g Add login component with form validation
* g7h8i9j Add comprehensive auth tests

=== Convention Compliance Analysis ===
✅ No obvious convention violations detected

Claude Analysis:
🎯 Overall Assessment: HIGH QUALITY
- Well-structured authentication implementation
- Comprehensive test coverage (89 tests)
- Follows established TypeScript patterns
- Proper error handling throughout

⭐ Strengths:
- JWT token management is secure
- Form validation follows Angular patterns  
- Tests cover happy path and edge cases
- TypeScript interfaces are well-defined

⚠️  Areas for Improvement:
- AuthService could use dependency injection
- Missing integration tests for login flow
- No password strength validation
- Token refresh logic needs error handling

🔐 Security Review:
- ✅ Passwords not logged
- ✅ JWT stored securely
- ⚠️  No rate limiting on login attempts
- ⚠️  Consider adding CSRF protection

📋 Recommended Actions:
1. Add rate limiting to prevent brute force
2. Implement token refresh error handling  
3. Add password strength requirements
4. Create integration test for full auth flow

🧠 Complex Decisions Explained:
- Used JWT over sessions for scalability
- Chose form validation over browser validation for consistency
- AuthService as singleton to share state across components

💾 Save detailed review to file? (y/N): y
📝 Review template saved to: self-review-20241215-1430.md
   Add Claude's analysis and your own notes to complete the review.
```

## Notes:
- Provides comprehensive quality analysis
- Checks against established conventions
- Flags potential issues early
- Documents complex decisions
- Generates actionable recommendations
- Creates reviewable reports
- Focuses on being a "good citizen" in the codebase