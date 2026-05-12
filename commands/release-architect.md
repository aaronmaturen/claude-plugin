---
description: "Audit and troubleshoot CI/CD pipelines with expertise in CircleCI, GitHub Actions, Docker, Amazon ECS, and Cloudflare Wrangler."
argument-hint: "[pipeline-url-or-path]"
---
# Release Architect - CI/CD Pipeline Expert

Expert-level CI/CD pipeline auditing, optimization, and troubleshooting. Specializes in CircleCI, GitHub Actions, Docker, Amazon ECS, Cloudflare Wrangler, and release engineering best practices.

**Input:** $ARGUMENTS (pipeline file path, error description, or "audit")

## Expertise Areas

| Domain | Technologies | Capabilities |
|--------|--------------|--------------|
| **CI Platforms** | CircleCI, GitHub Actions | Config audit, optimization, debugging |
| **Containerization** | Docker, ECR, ECS | Multi-stage builds, caching, deployment |
| **Edge Deployment** | Cloudflare Wrangler, Workers | Edge functions, KV, R2, Pages |
| **Package Management** | GitHub Packages, npm, PyPI | Versioning, publishing, artifacts |
| **Code Quality** | ESLint, Prettier, Black, Ruff | Linting, formatting, pre-commit |
| **Testing** | Jest, Pytest, Playwright, Cypress | Unit, integration, E2E, coverage |
| **Version Control** | Git, GitHub | Branching, tagging, releases |

## When to Use This Command

| Scenario | Use Release Architect |
|----------|----------------------|
| Pipeline failing with cryptic errors | Yes - debug and fix |
| Builds taking too long | Yes - optimization audit |
| Setting up new CI/CD | Yes - architecture guidance |
| Security concerns in pipeline | Yes - security audit |
| Deploying to new environment | Yes - deployment strategy |
| Release process improvements | Yes - workflow optimization |

## Investigation Process

### 0. **Context Gathering**

```bash
# Detect CI/CD platform and configuration
echo "=== CI/CD Platform Detection ==="

# CircleCI
if [[ -f ".circleci/config.yml" ]]; then
    echo "✓ CircleCI detected"
    PLATFORM="circleci"
    CONFIG_FILE=".circleci/config.yml"
fi

# GitHub Actions
if [[ -d ".github/workflows" ]]; then
    echo "✓ GitHub Actions detected"
    PLATFORM="github-actions"
    WORKFLOW_COUNT=$(ls -1 .github/workflows/*.yml 2>/dev/null | wc -l)
    echo "  Workflows found: $WORKFLOW_COUNT"
fi

# Docker
if [[ -f "Dockerfile" ]] || [[ -f "docker-compose.yml" ]]; then
    echo "✓ Docker detected"
    DOCKERFILE_COUNT=$(find . -name "Dockerfile*" -not -path "*/node_modules/*" | wc -l)
    echo "  Dockerfiles found: $DOCKERFILE_COUNT"
fi

# Wrangler (Cloudflare)
if [[ -f "wrangler.toml" ]] || [[ -f "wrangler.jsonc" ]]; then
    echo "✓ Cloudflare Wrangler detected"
fi

# Package management
[[ -f "package.json" ]] && echo "✓ npm/Node.js project"
[[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] && echo "✓ Python project"

# Testing frameworks
grep -q "jest\|vitest" package.json 2>/dev/null && echo "✓ Jest/Vitest testing"
grep -q "pytest" requirements.txt 2>/dev/null && echo "✓ Pytest testing"
grep -q "playwright\|cypress" package.json 2>/dev/null && echo "✓ E2E testing detected"

# Linting/Formatting
[[ -f ".eslintrc*" ]] || [[ -f "eslint.config.*" ]] && echo "✓ ESLint configured"
[[ -f ".prettierrc*" ]] && echo "✓ Prettier configured"
[[ -f "ruff.toml" ]] || [[ -f ".ruff.toml" ]] && echo "✓ Ruff configured"
```

### 1. **Fetch Latest Documentation** (Use Context7)

Before auditing, fetch current best practices:

```markdown
## Documentation Lookup

Use Context7 to fetch latest documentation for detected technologies:

### Required Lookups
- [ ] CircleCI: `/circleci/circleci-docs` - orbs, caching, parallelism
- [ ] GitHub Actions: `/github/docs` - workflows, actions, secrets
- [ ] Docker: `/docker/docs` - multi-stage builds, BuildKit
- [ ] ECS: `/aws/aws-cdk` or web search for ECS best practices
- [ ] Wrangler: `/cloudflare/cloudflare-docs` - workers, pages, wrangler CLI
```

**Context7 Queries:**
```
# For CircleCI issues
mcp__context7__get-library-docs("/circleci/circleci-docs", topic="[specific topic]")

# For GitHub Actions
mcp__context7__get-library-docs("/github/docs", topic="actions workflows")

# For Docker
mcp__context7__get-library-docs("/docker/docs", topic="dockerfile best practices")

# For Cloudflare
mcp__context7__get-library-docs("/cloudflare/cloudflare-docs", topic="wrangler")
```

### 2. **Pipeline Audit Framework**

#### 2.1 CircleCI Config Audit

```yaml
# Key areas to audit in .circleci/config.yml

## Version Check
version: 2.1  # Should be 2.1 for orbs support

## Orbs Usage
orbs:
  # Check for official orbs vs inline commands
  node: circleci/node@5.x
  docker: circleci/docker@2.x
  aws-ecr: circleci/aws-ecr@9.x
  aws-ecs: circleci/aws-ecs@4.x

## Caching Strategy
# Look for proper cache keys with checksums
- restore_cache:
    keys:
      - v1-deps-{{ checksum "package-lock.json" }}
      - v1-deps-

## Parallelism
# Check if tests use parallelism
parallelism: 4
- run: circleci tests glob "**/*.test.js" | circleci tests split

## Resource Classes
# Verify appropriate resource allocation
resource_class: medium  # small, medium, large, xlarge

## Workflows
# Check for proper job dependencies and filters
workflows:
  version: 2
  build-deploy:
    jobs:
      - build
      - test:
          requires: [build]
      - deploy:
          requires: [test]
          filters:
            branches:
              only: main
```

**CircleCI Audit Checklist:**

| Category | Check | Status | Impact |
|----------|-------|--------|--------|
| **Caching** | Uses checksum-based cache keys | ⬜ | High |
| **Caching** | Caches node_modules/pip packages | ⬜ | High |
| **Caching** | Docker layer caching enabled | ⬜ | High |
| **Parallelism** | Tests split across containers | ⬜ | Medium |
| **Orbs** | Uses official orbs vs scripts | ⬜ | Medium |
| **Resources** | Appropriate resource_class | ⬜ | Medium |
| **Workflows** | Proper job dependencies | ⬜ | High |
| **Filters** | Branch/tag filters correct | ⬜ | Critical |
| **Secrets** | Uses contexts for secrets | ⬜ | Critical |
| **Docker** | Multi-stage builds used | ⬜ | Medium |

#### 2.2 GitHub Actions Audit

```yaml
# Key areas to audit in .github/workflows/*.yml

## Trigger Configuration
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

## Caching
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-

## Concurrency (prevent duplicate runs)
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

## Matrix Builds
strategy:
  matrix:
    node-version: [18, 20, 22]
    os: [ubuntu-latest, windows-latest]

## Reusable Workflows
jobs:
  call-workflow:
    uses: ./.github/workflows/reusable.yml
    with:
      environment: production
    secrets: inherit

## OIDC for AWS (no long-lived credentials)
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-actions
    aws-region: us-east-1
```

**GitHub Actions Audit Checklist:**

| Category | Check | Status | Impact |
|----------|-------|--------|--------|
| **Caching** | actions/cache with hash keys | ⬜ | High |
| **Concurrency** | Prevents duplicate workflow runs | ⬜ | Medium |
| **Triggers** | Appropriate event triggers | ⬜ | High |
| **Permissions** | Minimal GITHUB_TOKEN permissions | ⬜ | Critical |
| **Secrets** | Uses OIDC vs long-lived keys | ⬜ | Critical |
| **Actions** | Pinned to SHA vs tag | ⬜ | Critical |
| **Matrix** | Efficient matrix strategy | ⬜ | Medium |
| **Artifacts** | Proper artifact retention | ⬜ | Low |
| **Timeouts** | Job timeouts configured | ⬜ | Medium |
| **Reusability** | DRY with reusable workflows | ⬜ | Medium |

#### 2.3 Docker Audit

```dockerfile
# Key areas to audit in Dockerfile

## Base Image
# Check for specific tags vs :latest
FROM node:20-alpine AS builder  # Good: specific version, slim base
FROM node:latest                 # Bad: unpinned, large image

## Multi-stage Builds
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine AS runtime
COPY --from=builder /app/node_modules ./node_modules
COPY . .

## Layer Optimization
# Commands that change frequently should be last
COPY package*.json ./    # Changes less often
RUN npm ci               # Cached if package.json unchanged
COPY . .                 # Changes most often - last

## Security
USER node                # Don't run as root
RUN npm ci --only=production --ignore-scripts  # Minimize attack surface

## .dockerignore
# Should exclude: node_modules, .git, tests, docs
```

**Docker Audit Checklist:**

| Category | Check | Status | Impact |
|----------|-------|--------|--------|
| **Base Image** | Pinned version (not :latest) | ⬜ | Critical |
| **Base Image** | Slim/Alpine variant used | ⬜ | High |
| **Multi-stage** | Separate build/runtime stages | ⬜ | High |
| **Layers** | Optimized layer ordering | ⬜ | Medium |
| **Caching** | Package files copied first | ⬜ | High |
| **Security** | Non-root USER specified | ⬜ | Critical |
| **Security** | No secrets in image | ⬜ | Critical |
| **.dockerignore** | Excludes unnecessary files | ⬜ | Medium |
| **Health** | HEALTHCHECK defined | ⬜ | Medium |
| **Size** | Final image < 500MB | ⬜ | Medium |

#### 2.4 Amazon ECS Audit

```markdown
## ECS Deployment Checklist

### Task Definition
| Check | Status | Impact |
|-------|--------|--------|
| CPU/Memory appropriate for workload | ⬜ | High |
| Container health check configured | ⬜ | High |
| Logging to CloudWatch configured | ⬜ | High |
| Secrets via Secrets Manager (not env vars) | ⬜ | Critical |
| Task role with minimal permissions | ⬜ | Critical |

### Service Configuration
| Check | Status | Impact |
|-------|--------|--------|
| Desired count matches capacity needs | ⬜ | High |
| Auto-scaling configured | ⬜ | Medium |
| Circuit breaker enabled | ⬜ | High |
| Deployment configuration (min/max %) | ⬜ | High |
| Load balancer health checks | ⬜ | Critical |

### CI/CD Integration
| Check | Status | Impact |
|-------|--------|--------|
| Blue/green or rolling deployment | ⬜ | High |
| Rollback strategy defined | ⬜ | Critical |
| ECR image scanning enabled | ⬜ | High |
| Image tagged with commit SHA | ⬜ | High |
```

#### 2.5 Cloudflare Wrangler Audit

```toml
# Key areas to audit in wrangler.toml

name = "my-worker"
main = "src/index.ts"
compatibility_date = "2024-01-01"  # Should be recent

# Environment configuration
[env.production]
vars = { ENVIRONMENT = "production" }
routes = [
  { pattern = "api.example.com/*", zone_name = "example.com" }
]

# KV Namespaces
[[kv_namespaces]]
binding = "MY_KV"
id = "xxx"
preview_id = "yyy"  # Important for local dev

# Durable Objects
[[durable_objects.bindings]]
name = "MY_DO"
class_name = "MyDurableObject"

# R2 Buckets
[[r2_buckets]]
binding = "MY_BUCKET"
bucket_name = "my-bucket"
```

**Wrangler Audit Checklist:**

| Category | Check | Status | Impact |
|----------|-------|--------|--------|
| **Compatibility** | Recent compatibility_date | ⬜ | High |
| **Environments** | Separate staging/production | ⬜ | High |
| **Secrets** | Using wrangler secret (not vars) | ⬜ | Critical |
| **Routes** | Correct route patterns | ⬜ | Critical |
| **KV** | Preview IDs for local dev | ⬜ | Medium |
| **Build** | Minification enabled | ⬜ | Low |
| **Limits** | Within Worker limits (CPU, memory) | ⬜ | High |

### 3. **Common Issues Database**

#### CircleCI Common Issues

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| "No such file or directory" | Working directory wrong | Add `working_directory: ~/project` |
| Cache not restoring | Key mismatch | Check `checksum` file path |
| "Permission denied" | Docker socket access | Use `setup_remote_docker` |
| Slow npm install | No caching | Add npm cache with checksum key |
| Tests flaky | No parallelism isolation | Use `circleci tests split` |
| "Out of memory" | Resource class too small | Upgrade to `large` or `xlarge` |
| Deploy not triggering | Filter mismatch | Check branch/tag filters |

#### GitHub Actions Common Issues

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| "Resource not accessible" | Permission missing | Add `permissions:` block |
| Workflow not triggering | Event config wrong | Check `on:` triggers |
| "Bad credentials" | Secret not set | Check repository secrets |
| Cache miss every time | Key changes constantly | Use `hashFiles()` properly |
| Concurrent runs conflict | No concurrency config | Add `concurrency:` group |
| "No space left on device" | Artifacts too large | Clean up before build |
| Matrix too slow | Too many combinations | Reduce matrix or use `fail-fast` |

#### Docker Common Issues

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| Build slow every time | Layer cache invalidated | Reorder COPY commands |
| Image very large | Not multi-stage | Add builder/runtime stages |
| "EACCES permission denied" | Running as root | Add `USER node` |
| "Module not found" | node_modules not copied | Check COPY paths |
| npm install fails | Network in build | Use `--network=host` or cache |

### 4. **Performance Optimization**

#### Build Time Reduction Strategies

```markdown
## Quick Wins (< 1 hour to implement)

### Caching
1. **Dependency caching** - Always cache node_modules, pip packages
2. **Docker layer caching** - Enable DLC (CircleCI) or BuildKit cache
3. **Build artifacts** - Cache compiled assets between jobs

### Parallelization
1. **Test splitting** - Split tests across containers
2. **Matrix builds** - Run different versions in parallel
3. **Job parallelism** - Independent jobs run concurrently

### Resource Optimization
1. **Right-size resources** - Don't over-allocate (costs money)
2. **Slim images** - Alpine/slim base images
3. **Selective testing** - Only test changed packages

## Measurement
Before optimizing, measure:
- Total pipeline duration
- Each job/step duration
- Cache hit rates
- Resource utilization
```

### 5. **Security Audit**

```markdown
## CI/CD Security Checklist

### Secrets Management
- [ ] No secrets in code (use .env.example)
- [ ] Secrets in CI platform's secret store
- [ ] OIDC for cloud credentials (no long-lived keys)
- [ ] Secrets not logged (mask in output)
- [ ] Rotate secrets regularly

### Pipeline Security
- [ ] Actions/orbs pinned to SHA (not tags)
- [ ] Pull requests from forks don't access secrets
- [ ] Branch protection rules enforced
- [ ] Required reviews before deploy
- [ ] Audit logs enabled

### Container Security
- [ ] Base images from trusted sources
- [ ] Images scanned for vulnerabilities
- [ ] Non-root user in containers
- [ ] No secrets baked into images
- [ ] Minimal packages installed

### Dependency Security
- [ ] Dependabot/Renovate enabled
- [ ] License compliance checked
- [ ] npm audit / pip audit in CI
- [ ] Lock files committed
```

### 6. **Generate Audit Report**

```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
AUDIT_DIR="${REPORT_BASE}/release-architecture/$(basename $(pwd))-$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"
```

#### Report Template:

```markdown
# CI/CD Pipeline Audit Report

**Project:** [Project Name]
**Date:** [Audit Date]
**Platform:** [CircleCI/GitHub Actions/Both]

---
## 🎯 AUDIT FINDINGS SUMMARY

### Critical Issues (Fix Immediately)
| # | Issue | Location | Risk | Fix |
|---|-------|----------|------|-----|
| 1 | [Issue] | [File:Line] | [Risk] | [Fix] |

### High Priority (Fix This Sprint)
| # | Issue | Location | Impact | Fix |
|---|-------|----------|--------|-----|

### Optimization Opportunities
| # | Opportunity | Current | Potential | Effort |
|---|-------------|---------|-----------|--------|
| 1 | Enable caching | 10min build | 3min build | Low |

---

## Pipeline Health Score

| Category | Score | Issues |
|----------|-------|--------|
| Security | [A-F] | |
| Performance | [A-F] | |
| Reliability | [A-F] | |
| Maintainability | [A-F] | |
| **Overall** | **[A-F]** | |

---

## Detailed Findings

### Security Findings
[Detailed security audit results]

### Performance Analysis
- **Current Build Time:** [X minutes]
- **Potential Build Time:** [Y minutes]
- **Bottlenecks Identified:** [List]

### Configuration Issues
[Detailed config issues with code snippets]

### Best Practices Gaps
[What's missing vs best practices]

---

## Recommended Changes

### Immediate Actions (P0)
```yaml
# Before
[problematic config]

# After
[fixed config]
```

### Short-term Improvements (P1)
[Changes for next sprint]

### Long-term Architecture (P2)
[Strategic improvements]

---

## Implementation Checklist

- [ ] Fix critical security issues
- [ ] Implement caching strategy
- [ ] Add parallelization
- [ ] Update documentation
- [ ] Test in staging environment
- [ ] Monitor after changes

---
**Audit Complete:** [Date/Time]
```

---

## Specific Troubleshooting Guides

### CircleCI Debugging

```bash
# SSH into failed job
circleci ssh --job-id <job-id>

# Validate config locally
circleci config validate

# Process config (see expanded orbs)
circleci config process .circleci/config.yml

# Run job locally
circleci local execute --job build
```

### GitHub Actions Debugging

```bash
# Enable debug logging
# Set secret: ACTIONS_STEP_DEBUG = true
# Set secret: ACTIONS_RUNNER_DEBUG = true

# Use tmate for SSH debugging
- uses: mxschmitt/action-tmate@v3
  if: ${{ failure() }}

# View workflow run
gh run view <run-id> --log
gh run watch <run-id>
```

### Docker Debugging

```bash
# Build with progress output
docker build --progress=plain .

# Inspect build cache
docker builder prune --all --verbose

# Analyze image layers
docker history <image>

# Dive into image
dive <image>

# Check image size
docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}"
```

---

## Usage Examples

### Audit Current Project
```
/release-architect audit

Output:
Detecting CI/CD platform...
✓ CircleCI detected at .circleci/config.yml
✓ Docker detected (2 Dockerfiles)
✓ GitHub Actions detected (3 workflows)

Fetching latest documentation...
✓ CircleCI orbs v2.x docs loaded
✓ Docker BuildKit best practices loaded

Running audit...

CRITICAL ISSUES FOUND:
1. [SECURITY] Secrets exposed in workflow logs
   File: .github/workflows/deploy.yml:45
   Fix: Add `mask: true` to secret output

2. [PERFORMANCE] No dependency caching
   File: .circleci/config.yml
   Impact: +5 minutes per build
   Fix: Add npm cache with checksum key

Generating report...
✓ Report saved to: ~/Documents/technical-analysis/release-architecture/...
```

### Debug Specific Error
```
/release-architect "Error: EACCES permission denied /app/node_modules"

Output:
Analyzing error pattern...
✓ Docker permission error detected

Root Cause:
Container running as root during build, but node_modules
created with different ownership than runtime user.

Solution:
```dockerfile
# Add to Dockerfile
FROM node:20-alpine
USER node
WORKDIR /home/node/app
COPY --chown=node:node package*.json ./
RUN npm ci
COPY --chown=node:node . .
```

### Optimize Build Time
```
/release-architect optimize

Output:
Current pipeline analysis:
- Total duration: 12 minutes
- Bottlenecks:
  1. npm install: 4 minutes (no cache)
  2. Docker build: 5 minutes (no layer cache)
  3. Tests: 3 minutes (no parallelism)

Recommended optimizations:
1. Add npm caching → Save 3 minutes
2. Enable Docker layer caching → Save 3 minutes
3. Split tests across 4 containers → Save 2 minutes

Potential duration: 4 minutes (67% reduction)
```

---

## Notes

- **Documentation-First**: Uses Context7 for up-to-date best practices
- **Platform-Aware**: Detects and audits CircleCI, GitHub Actions, Docker
- **Security-Focused**: Prioritizes security issues in findings
- **Actionable**: Provides specific code fixes, not just recommendations
- **Measurable**: Includes performance metrics and improvement estimates
