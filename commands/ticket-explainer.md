# Ticket Explainer

Explain what work is needed for a JIRA ticket in plain language, pulling context from JIRA, GitHub, and the latest code on `main`. Surfaces related PRs, affected files, and direct links to relevant GitHub resources.

**Ticket ID:** $ARGUMENTS (JIRA issue key, e.g., PROJ-1234)

## Process:

### 1. **Validate Input**
```bash
if [[ -z "$ARGUMENTS" ]]; then
    echo "❌ No JIRA ticket ID provided."
    echo ""
    echo "Usage: /ticket-explainer PROJ-1234"
    echo ""
    echo "Provide a JIRA issue key and I'll explain:"
    echo "  - What the ticket is asking for"
    echo "  - Where in the codebase the work lives"
    echo "  - Related PRs and GitHub history"
    echo "  - A plain-English breakdown of what needs to be done"
    exit 1
fi

TICKET_ID="$ARGUMENTS"
echo "🎫 Fetching details for: $TICKET_ID"
```

### 2. **Sync with Latest Main**
```bash
echo "🔄 Syncing with latest main..."

CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

# Fetch latest without switching branches
git fetch origin main --quiet

# Show how far behind we are (if on a feature branch)
BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
if [[ "$BEHIND" -gt 0 ]]; then
    echo "⚠️  Current branch is $BEHIND commit(s) behind origin/main"
fi

# Get the latest commit on main for context
MAIN_SHA=$(git rev-parse origin/main)
MAIN_DATE=$(git log -1 --format="%ci" origin/main)
echo "✅ Latest main: ${MAIN_SHA:0:8} (${MAIN_DATE})"
```

### 3. **Fetch Ticket Details from JIRA**
```bash
echo "📋 Fetching JIRA ticket details..."

# Get full ticket details
jira issue view "$TICKET_ID" --output json > /tmp/ticket_details.json 2>/dev/null

if [[ $? -ne 0 ]]; then
    echo "⚠️  Could not fetch JIRA ticket. Check that:"
    echo "   - '$TICKET_ID' is a valid JIRA issue key"
    echo "   - You are authenticated: run 'jira init'"
    exit 1
fi

# Extract key fields
SUMMARY=$(jq -r '.fields.summary // "No summary"' /tmp/ticket_details.json)
DESCRIPTION=$(jq -r '.fields.description // "No description provided"' /tmp/ticket_details.json)
STATUS=$(jq -r '.fields.status.name // "Unknown"' /tmp/ticket_details.json)
ISSUE_TYPE=$(jq -r '.fields.issuetype.name // "Issue"' /tmp/ticket_details.json)
PRIORITY=$(jq -r '.fields.priority.name // "None"' /tmp/ticket_details.json)
ASSIGNEE=$(jq -r '.fields.assignee.displayName // "Unassigned"' /tmp/ticket_details.json)
REPORTER=$(jq -r '.fields.reporter.displayName // "Unknown"' /tmp/ticket_details.json)
CREATED=$(jq -r '.fields.created // ""' /tmp/ticket_details.json)
UPDATED=$(jq -r '.fields.updated // ""' /tmp/ticket_details.json)
LABELS=$(jq -r '[.fields.labels[]? ] | join(", ")' /tmp/ticket_details.json 2>/dev/null || echo "None")
COMPONENTS=$(jq -r '[.fields.components[]?.name] | join(", ")' /tmp/ticket_details.json 2>/dev/null || echo "None")
ACCEPTANCE_CRITERIA=$(jq -r '.fields.customfield_10100 // ""' /tmp/ticket_details.json 2>/dev/null || echo "")
STORY_POINTS=$(jq -r '.fields.story_points // .fields.customfield_10016 // "Not estimated"' /tmp/ticket_details.json 2>/dev/null || echo "Not estimated")

# Fetch comments for additional context
jira issue comment list "$TICKET_ID" --output json > /tmp/ticket_comments.json 2>/dev/null || echo "[]" > /tmp/ticket_comments.json

echo "✅ Ticket: $SUMMARY"
echo "   Type: $ISSUE_TYPE | Status: $STATUS | Priority: $PRIORITY"
```

### 4. **Find Related GitHub Activity**
```bash
echo ""
echo "🔍 Searching GitHub for related activity..."

# Detect GitHub repo from git remote
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$REMOTE_URL" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
    GH_OWNER="${BASH_REMATCH[1]}"
    GH_REPO="${BASH_REMATCH[2]}"
    GH_REPO_FULL="$GH_OWNER/$GH_REPO"
    echo "📦 Repository: $GH_REPO_FULL"
else
    echo "⚠️  Could not detect GitHub repository from remote URL: $REMOTE_URL"
    GH_REPO_FULL=""
fi

# Search for PRs mentioning this ticket
if [[ -n "$GH_REPO_FULL" ]]; then
    echo "🔎 Searching for PRs referencing $TICKET_ID..."
    
    # Open PRs
    gh pr list \
        --repo "$GH_REPO_FULL" \
        --search "$TICKET_ID" \
        --json number,title,state,url,author,createdAt,headRefName \
        --limit 10 \
        > /tmp/ticket_prs_open.json 2>/dev/null || echo "[]" > /tmp/ticket_prs_open.json

    # Closed/merged PRs
    gh pr list \
        --repo "$GH_REPO_FULL" \
        --search "$TICKET_ID" \
        --state merged \
        --json number,title,state,url,author,createdAt,mergedAt,headRefName \
        --limit 10 \
        > /tmp/ticket_prs_merged.json 2>/dev/null || echo "[]" > /tmp/ticket_prs_merged.json

    OPEN_PR_COUNT=$(jq 'length' /tmp/ticket_prs_open.json)
    MERGED_PR_COUNT=$(jq 'length' /tmp/ticket_prs_merged.json)
    echo "   Found: $OPEN_PR_COUNT open PR(s), $MERGED_PR_COUNT merged PR(s)"

    # Also search commits on main for ticket references
    echo "🔎 Searching recent commits on main for $TICKET_ID..."
    git log origin/main --oneline --grep="$TICKET_ID" --since="6 months ago" \
        > /tmp/ticket_commits.txt 2>/dev/null || touch /tmp/ticket_commits.txt
    
    COMMIT_COUNT=$(wc -l < /tmp/ticket_commits.txt | tr -d ' ')
    echo "   Found: $COMMIT_COUNT related commit(s) on main"

    # Look for branches named after this ticket
    echo "🔎 Looking for branches referencing $TICKET_ID..."
    git branch -r --list "*${TICKET_ID}*" 2>/dev/null > /tmp/ticket_branches.txt || touch /tmp/ticket_branches.txt
    BRANCH_COUNT=$(grep -c . /tmp/ticket_branches.txt 2>/dev/null || echo "0")
    echo "   Found: $BRANCH_COUNT related branch(es)"
fi
```

### 5. **Identify Affected Code Areas**
```bash
echo ""
echo "🗂️  Identifying affected code areas..."

# If there are merged PRs, look at the files they touched
if [[ -n "$GH_REPO_FULL" ]] && [[ "$MERGED_PR_COUNT" -gt 0 ]]; then
    echo "📂 Files changed in merged PRs:"
    jq -r '.[].number' /tmp/ticket_prs_merged.json | while read PR_NUM; do
        echo "  PR #$PR_NUM:"
        gh pr view "$PR_NUM" \
            --repo "$GH_REPO_FULL" \
            --json files \
            --jq '.files[].path' 2>/dev/null | head -20 | sed 's/^/    - /'
    done
fi

# If there are open PRs, list their files too
if [[ -n "$GH_REPO_FULL" ]] && [[ "$OPEN_PR_COUNT" -gt 0 ]]; then
    echo "📂 Files changed in open PRs:"
    jq -r '.[].number' /tmp/ticket_prs_open.json | while read PR_NUM; do
        echo "  PR #$PR_NUM:"
        gh pr view "$PR_NUM" \
            --repo "$GH_REPO_FULL" \
            --json files \
            --jq '.files[].path' 2>/dev/null | head -20 | sed 's/^/    - /'
    done
fi

# Search the codebase on main for the ticket ID itself (in comments, TODOs, etc.)
echo "🔎 Scanning codebase for inline references to $TICKET_ID..."
git grep -n "$TICKET_ID" origin/main -- \
    '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.html' '*.css' '*.scss' \
    2>/dev/null | head -20 > /tmp/ticket_inline_refs.txt || touch /tmp/ticket_inline_refs.txt

INLINE_REF_COUNT=$(grep -c . /tmp/ticket_inline_refs.txt 2>/dev/null || echo "0")
if [[ "$INLINE_REF_COUNT" -gt 0 ]]; then
    echo "   Found $INLINE_REF_COUNT inline reference(s) in source files"
fi
```

### 6. **Generate Explanation**

Using all gathered data, produce a clear, plain-language explanation with the following structure:

---

## 🎫 Ticket: [TICKET_ID] — [SUMMARY]

> **[ISSUE_TYPE]** · **[STATUS]** · **[PRIORITY] Priority** · [STORY_POINTS] points  
> Reported by [REPORTER] · Assigned to [ASSIGNEE]  
> Created [CREATED] · Last updated [UPDATED]

---

### 📌 What This Ticket Is About

[Translate the JIRA description into plain language. Avoid jargon. Explain:
- The user-facing or system problem this addresses
- Why it matters (business or user impact)
- Any constraints or context from the description or comments]

---

### ✅ Acceptance Criteria

[If AC exist in JIRA, list them clearly formatted. If not, derive implied criteria from the description and flag them as inferred:]

**From JIRA:**
- AC 1: [criterion]
- AC 2: [criterion]

**Inferred (not explicitly stated — confirm with team):**
- [ ] [implied criterion based on description]

---

### 🧭 Where the Work Lives

Based on the ticket type, components, and any related GitHub activity, the work likely touches:

| Area | Files / Modules | Confidence |
|------|----------------|------------|
| [e.g., Frontend component] | `src/components/...` | High / Medium / Low |
| [e.g., API endpoint] | `api/endpoints/...` | High / Medium / Low |
| [e.g., Data model] | `models/...` | Medium |

> 💡 Confidence is based on: PR history, commit references, component labels, and description keywords.

---

### 🔗 Related GitHub Activity

#### Open PRs
[For each open PR found:]
- **[#NUMBER] [Title]** — by @[author] — [URL]  
  Branch: `[headRefName]` · Opened [createdAt]

#### Merged PRs
[For each merged PR found:]
- **[#NUMBER] [Title]** — by @[author] — [URL]  
  Merged [mergedAt] · Branch: `[headRefName]`

#### Related Commits on Main
[List commits from /tmp/ticket_commits.txt with short SHA, message, and date]

#### Branches
[List remote branches from /tmp/ticket_branches.txt]

> 🔗 View all activity on GitHub: `https://github.com/[GH_REPO_FULL]/search?q=[TICKET_ID]&type=commits`

---

### 🛠️ What Needs to Be Done

A plain-English breakdown of the work, organized by layer. Be specific about what to build, change, or fix — not just what to investigate.

#### Backend
- [ ] [Specific task, e.g., "Add a new `GET /api/widgets/:id` endpoint that returns..."]
- [ ] [e.g., "Update the `Widget` model to include a `status` field"]

#### Frontend
- [ ] [e.g., "Add a status badge to the `WidgetCard` component"]
- [ ] [e.g., "Wire up the new API endpoint in `widgetService.ts`"]

#### Tests
- [ ] [e.g., "Unit test the new endpoint with valid and invalid IDs"]
- [ ] [e.g., "E2E test the status display for each state"]

#### Other
- [ ] [e.g., "Update API documentation for the new endpoint"]
- [ ] [e.g., "Add feature flag `widget-status` before rollout"]

---

### ⚠️ Things to Watch Out For

[Surface risks, edge cases, or unknowns based on the ticket details, related PRs, and codebase scan. Examples:]
- Unclear AC: "[quote the ambiguous criterion]" — ask [REPORTER] to clarify
- Related open PRs may conflict — review [#NUMBER] before branching
- Inline `// TODO([TICKET_ID])` comments found at [files] — check if still relevant
- [Any other flags from comments, stale branches, etc.]

---

### 💬 Recent Comments

[Summarize the last 3–5 JIRA comments for additional context, noting any decisions made or blockers raised]

---

### 🚀 Suggested First Steps

1. Pull latest main: `git checkout main && git pull origin main`
2. Create a branch: `git checkout -b [ticket-id-lowercase]-[short-description]`
3. Review any open PRs for this ticket before starting
4. [First concrete code action based on analysis]

---

## Notes:
- Requires JIRA CLI (`jira`) to be authenticated: run `jira init`
- Requires GitHub CLI (`gh`) to be authenticated: run `gh auth login`
- Syncs `origin/main` via `git fetch` — does not switch branches or modify your working tree
- GitHub links use the detected remote from `git remote get-url origin`
- If the ticket has no GitHub activity yet, the "Where the Work Lives" section will be based on component labels and description analysis only
