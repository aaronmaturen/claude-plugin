# PR Review for Junior Engineers

Review a GitHub PR and provide a comprehensive summary with documentation links.

**PR URL:** $ARGUMENTS

## Steps:

1. **Parse PR Information**
   - Extract owner, repo, and PR number from the provided URL
   - Format: `https://github.com/{owner}/{repo}/pull/{number}`

2. **Setup PR for Review**
   - Save current work: `git stash push -m "PR review backup"`
   - Note current branch: `git branch --show-current > .pr-review-original-branch`
   - Checkout PR: `gh pr checkout {number} --repo {owner}/{repo}`
   - Check for new dependencies:
     - `git diff {original-branch}...HEAD -- package.json requirements.txt Gemfile go.mod`
     - Only install if dependency files changed

3. **Fetch PR Overview**
   - `gh pr view {number} --repo {owner}/{repo} --json title,body,state,author,createdAt,files,additions,deletions`
   - `gh pr diff {number} --repo {owner}/{repo}` - Get the full diff

4. **Analyze Changed Files**
   - Group changes by file type and purpose
   - Identify patterns and architectural changes
   - Note any new dependencies or libraries added

5. **Pattern Consistency Check**
   - **Search Existing Codebase** for similar implementations:
     - Authentication patterns already in use
     - Error handling conventions
     - API response formats
     - Database query patterns
     - State management approaches
   
   - **Compare PR Patterns** with established ones:
     - ✅ Uses existing patterns (list which ones)
     - ⚠️  Modifies existing patterns (explain why)
     - ❌ Introduces new patterns (justify necessity)
   
   - **Examples to Look For**:
     - If adding auth: How do other endpoints handle auth?
     - If adding API: What's the existing response format?
     - If adding validation: What validation library is used?
     - If adding tests: What testing patterns exist?

6. **Create Junior-Friendly Summary**
   
   ### PR Overview
   - **Purpose**: What problem does this PR solve?
   - **Scope**: How many files changed and why?
   - **Impact**: What parts of the system are affected?
   
   ### Technical Changes Explained
   For each significant change:
   - **What changed**: Plain English explanation
   - **Why it changed**: The reasoning behind the change
   - **How it works**: Step-by-step breakdown
   
   ### Code Patterns Used
   - Design patterns implemented
   - Best practices followed
   - Anti-patterns avoided

7. **Search Documentation (context7)**
   - Search for official docs on:
     - New libraries or frameworks used
     - Design patterns implemented
     - Language features utilized
     - Best practices referenced
   - Include relevant documentation links

8. **Learning Points**
   - Key concepts to understand
   - Skills demonstrated in the PR
   - Common patterns to remember

9. **Testing Strategy**
   - **Manual Testing Steps**:
     - Identify user flows affected by the changes
     - Create step-by-step testing instructions
     - Include expected outcomes for each step
   
   - **Data Setup Requirements**:
     - Database state needed (users, records, etc.)
     - Required environment variables
     - External service dependencies
     - Sample data or fixtures needed
   
   - **Edge Cases to Test**:
     - Boundary conditions (empty, null, max values)
     - Error scenarios and error handling
     - Concurrent operations
     - Permission/authorization edge cases
     - Network failure scenarios
   
   - **Test Data Examples**:
     ```json
     // Example user for testing auth
     {
       "email": "test@example.com",
       "password": "TestPass123!",
       "role": "admin"
     }
     ```

10. **Questions to Ask**
   - Suggest thoughtful questions for code review
   - Areas that might need clarification
   - Edge cases not covered in tests

## Example Output:
```
# PR Review: Add User Authentication (#123)

## Overview
This PR adds JWT-based authentication to our API. It affects 15 files
and introduces middleware for protecting routes.

## Key Changes Explained

### 1. Authentication Middleware (auth.middleware.ts)
**What**: New file that checks if requests have valid JWT tokens
**Why**: We need to protect sensitive API endpoints
**How**: 
- Extracts token from Authorization header
- Verifies token signature
- Attaches user info to request

📚 JWT Documentation: https://jwt.io/introduction

### 2. User Model Updates (user.model.ts)
**What**: Added password hashing methods
**Why**: Never store plain text passwords
**How**: Uses bcrypt to hash passwords before saving

📚 Password Hashing Best Practices: https://auth0.com/blog/hashing-passwords-one-way-road-to-security/

## Pattern Consistency Analysis

### ✅ Follows Existing Patterns:
- **Error Handling**: Uses established `AppError` class from `src/utils/errors.ts`
- **Response Format**: Matches existing API response structure `{ data, status, message }`
- **Middleware Pattern**: Consistent with existing middleware in `src/middleware/`

### ⚠️ Modified Patterns:
- **JWT Storage**: Changed from localStorage to httpOnly cookies (Security improvement)
  - Justification: Prevents XSS attacks

### ❌ New Patterns Introduced:
- **Token Refresh**: Added refresh token rotation
  - Justification: No existing refresh mechanism found
  - Consider: Should align with planned OAuth implementation

## Testing Instructions

### Data Setup
1. Create test database with:
   ```sql
   INSERT INTO users (email, password_hash, role) VALUES 
   ('admin@test.com', '$2b$10$...', 'admin'),
   ('user@test.com', '$2b$10$...', 'user');
   ```

2. Set environment variables:
   ```bash
   JWT_SECRET=test-secret-key
   JWT_EXPIRY=1h
   ```

### Environment Setup
```bash
# If using Docker:
docker-compose up -d
docker-compose exec app npm install  # Install any new dependencies

# If not using Docker:
npm install  # or yarn install
npm run db:migrate  # Run any new migrations
```

### Manual Testing Steps
1. **Test Login Flow**:
   - POST /api/auth/login with valid credentials
   - Verify JWT token returned
   - Check token expiry time

2. **Test Protected Routes**:
   - Access /api/users without token (expect 401)
   - Access with valid token (expect 200)
   - Access with expired token (expect 401)

### Edge Cases to Test
- Login with non-existent user
- Login with wrong password
- Malformed JWT token
- Token with invalid signature
- Concurrent login attempts

## Learning Points
- Middleware pattern for cross-cutting concerns
- Importance of password security
- Token-based vs session-based auth

## Review Questions
- How are refresh tokens handled?
- What happens when a token expires mid-request?
- Should we add rate limiting to login endpoint?
- Are there tests for all edge cases?
```

## Cleanup (After Review Complete):
```bash
# When ready to return to original work:
git checkout $(cat .pr-review-original-branch)

# Restore stashed work
git stash pop

# Clean up
rm .pr-review-original-branch

# Optionally delete PR branch locally
git branch -D pr-branch-name
```

Note: Stay on the PR branch while reviewing and testing. Only run cleanup when completely done.

## Notes:
- Requires GitHub CLI (`gh`) to be installed and authenticated
- Uses current directory to leverage existing Docker/dependency setup
- Automatically stashes current work and saves original branch
- Works with all project types (Docker, Node, Python, etc.)
- Uses context7 for documentation searches
- Focuses on education and understanding
- Avoids jargon where possible