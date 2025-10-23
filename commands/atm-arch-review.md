# Comprehensive Architecture Review

Perform a thorough architectural analysis of the codebase, evaluating security, performance, maintainability, scalability, and best practices. Generate a detailed report with scores, findings, and actionable recommendations.

**Project Path:** $ARGUMENTS (defaults to current directory)

## Analysis Framework:

### 1. **Project Structure Analysis**
   - Directory organization and file structure
   - Module boundaries and separation of concerns
   - Configuration management
   - Documentation presence and quality
   - Build and deployment structure

### 2. **Security Analysis**
   - Authentication and authorization patterns
   - Input validation and sanitization
   - Secrets management (hardcoded credentials, API keys)
   - Dependency vulnerabilities
   - Access control and permissions
   - Encryption and data protection
   - Security headers and configurations
   - OWASP Top 10 compliance

### 3. **Performance & Scalability**
   - Algorithm complexity analysis
   - Database query optimization
   - Caching strategies
   - Resource utilization patterns
   - Concurrency and parallelism
   - Memory management
   - I/O optimization
   - Scalability bottlenecks
   - Load testing readiness

### 4. **Code Quality & Maintainability**
   - Code organization and structure
   - Function/class complexity (cyclomatic complexity)
   - Code duplication detection
   - Naming conventions consistency
   - Documentation coverage
   - Test coverage and quality
   - Error handling patterns
   - Logging and monitoring
   - Technical debt assessment

### 5. **Architecture Patterns & Design**
   - Design pattern usage and consistency
   - SOLID principles adherence
   - Coupling and cohesion analysis
   - Microservices boundaries (if applicable)
   - API design and versioning
   - Event-driven architecture
   - Domain-driven design alignment
   - Dependency injection patterns

### 6. **DevOps & Infrastructure**
   - CI/CD pipeline configuration
   - Infrastructure as Code (IaC)
   - Container strategy (Docker, Kubernetes)
   - Monitoring and observability
   - Deployment strategies
   - Environment configuration
   - Backup and disaster recovery
   - Service mesh considerations

### 7. **Compliance & Standards**
   - Industry standards compliance (ISO, SOC2)
   - Regulatory compliance (GDPR, HIPAA)
   - Accessibility standards (WCAG)
   - Coding standards adherence
   - License compliance
   - Open source dependency management

## Output Format:

### Generate Architecture Report

1. **Create report**:
   ```bash
   REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
   PROJECT_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null) || echo "unknown")
   PARENT_DIR=$(basename $(dirname $(git rev-parse --show-toplevel 2>/dev/null)) || echo "projects")
   DATE=$(date +%Y-%m-%d-%H%M)

   REPORT_DIR="${REPORT_BASE}/architecture/${PARENT_DIR}/${PROJECT_NAME}"
   mkdir -p "$REPORT_DIR"

   REPORT_FILE="${REPORT_DIR}/architecture-review-${DATE}.md"
   ```

2. **Report structure**:
   ```markdown
   # Architecture Review: [Project Name]
   
   **Date:** [Current Date]
   **Reviewer:** Claude (AI Architecture Analyst)
   **Project Path:** [Path]
   
   ## Executive Summary
   
   ### Overall Score: [Score]/100
   **Grade:** [A-F] - [Description]
   
   ### Key Strengths
   - [Strength 1]
   - [Strength 2]
   - [Strength 3]
   
   ### Critical Issues
   - 🚨 [Security issue 1]
   - ⚡ [Performance issue 1]
   - 🐛 [Quality issue 1]
   
   ## Detailed Analysis
   
   ### 1. Project Structure (Score: X/15)
   [Detailed analysis with findings]
   
   ### 2. Security Assessment (Score: X/20)
   [Security findings and recommendations]
   
   ### 3. Performance & Scalability (Score: X/15)
   [Performance analysis results]
   
   ### 4. Code Quality (Score: X/15)
   [Maintainability metrics and findings]
   
   ### 5. Architecture Design (Score: X/15)
   [Design pattern analysis]
   
   ### 6. DevOps Maturity (Score: X/10)
   [Infrastructure and deployment analysis]
   
   ### 7. Testing & Reliability (Score: X/10)
   [Test coverage and quality metrics]
   
   ## Recommendations
   
   ### Immediate Actions (P0)
   1. [Critical security fix]
   2. [Critical performance fix]
   
   ### Short-term Improvements (P1)
   1. [Important enhancement]
   2. [Quality improvement]
   
   ### Long-term Strategic (P2)
   1. [Architecture evolution]
   2. [Technology migration]
   
   ## Architecture Diagrams
   
   ### Current Architecture
   ![[architecture-current.excalidraw]]
   
   ### Proposed Improvements
   ![[architecture-proposed.excalidraw]]
   
   ## Risk Matrix
   
   | Risk | Impact | Probability | Mitigation |
   |------|--------|-------------|------------|
   | [Risk 1] | High | Medium | [Action] |
   
   ## Metrics Dashboard
   
   - **Code Coverage:** X%
   - **Technical Debt:** X hours
   - **Cyclomatic Complexity:** Average X
   - **Dependencies:** X total (X outdated)
   
   ## Appendix
   
   ### File Statistics
   - Total Files: X
   - Lines of Code: X
   - Languages: [List]
   
   ### Tool Versions
   - [Tool 1]: vX.X
   - [Tool 2]: vX.X
   
   ---
   
   *Generated by Claude Architecture Review Tool*
   *Next Review Recommended: [Date + 3 months]*
   ```

## Implementation Notes:

- The analysis will scan the entire codebase systematically
- Generate architecture diagrams
- Create actionable recommendations with priority levels
- Include both quantitative metrics and qualitative insights
- Save all outputs to report directory for tracking over time
- Support comparison with previous reviews for trend analysis

## Example Usage:
```
Command: atm-arch-review
# or
Command: atm-arch-review /path/to/project

Output:
Performing comprehensive architecture review...
✓ Project structure analyzed
✓ Security assessment complete
✓ Performance analysis complete
✓ Code quality metrics calculated
✓ Architecture patterns identified
✓ DevOps maturity assessed
✓ Testing coverage analyzed

Generating architecture report...
✓ Report saved to: ~/Documents/technical-analysis/architecture/projects/project/architecture-review-2024-01-15.md
✓ Architecture diagrams created

Overall Score: 78/100 (B - Good)

Top 3 Recommendations:
1. 🚨 Remove hardcoded API keys in config.json
2. ⚡ Optimize database queries in user service
3. 🧪 Increase test coverage from 45% to 80%

View full report for detailed analysis and diagrams.
```