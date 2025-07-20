# Code Simplification Analysis

Analyze codebase (or specific section) for complexity and consistency using 5 specialized sub-agents. Each agent performs 3 iterative passes to identify and suggest simplifications while maintaining alignment with existing patterns.

**Target Path:** $ARGUMENTS (defaults to current directory)

## Sub-Agent Framework:

### 1. **Pattern Consistency Agent**
Ensures code follows established patterns in the codebase.

**Pass 1 - Pattern Discovery:**
- Identify common patterns across the codebase:
  - Naming conventions (variables, functions, classes)
  - File organization patterns
  - Import/export structures
  - Error handling patterns
  - API response patterns
  - Component structure patterns

**Pass 2 - Deviation Detection:**
- Find code that deviates from established patterns
- Identify inconsistent implementations of similar functionality
- Detect mixed paradigms (e.g., callbacks vs promises vs async/await)
- Find naming convention violations

**Pass 3 - Standardization Proposals:**
- Suggest refactoring to match dominant patterns
- Provide specific code changes to align with conventions
- Prioritize changes by impact and effort

### 2. **Code Complexity Agent**
Identifies and reduces unnecessary complexity.

**Pass 1 - Complexity Metrics:**
- Calculate cyclomatic complexity for each function
- Identify deeply nested code blocks (>3 levels)
- Find functions with too many parameters (>4)
- Detect overly long functions (>50 lines)
- Identify complex conditional statements

**Pass 2 - Simplification Opportunities:**
- Functions that can be decomposed
- Complex conditionals that can use early returns
- Nested callbacks that can be flattened
- Switch statements that can use lookup tables
- Loops that can use functional approaches

**Pass 3 - Refactoring Recommendations:**
- Provide specific refactoring suggestions
- Show before/after code examples
- Estimate complexity reduction
- Ensure functionality preservation

### 3. **DRY Principle Agent**
Eliminates code duplication and promotes reusability.

**Pass 1 - Duplication Detection:**
- Find exact code duplicates
- Identify similar code patterns with minor variations
- Detect repeated logic across files
- Find duplicated type definitions
- Identify copy-pasted error handling

**Pass 2 - Abstraction Opportunities:**
- Common functions that can be extracted
- Shared utilities that should be centralized
- Repeated patterns that need templates
- Similar components that can be generalized
- Duplicate configs that can be merged

**Pass 3 - Consolidation Plan:**
- Create shared utility modules
- Suggest generic implementations
- Provide migration path for duplicates
- Estimate code reduction metrics

### 4. **Abstraction Level Agent**
Ensures appropriate levels of abstraction.

**Pass 1 - Abstraction Analysis:**
- Identify over-engineered solutions
- Find premature optimizations
- Detect unnecessary design patterns
- Locate overly generic implementations
- Find abstraction layer violations

**Pass 2 - Simplification Targets:**
- Abstractions used only once
- Interfaces with single implementations
- Factory patterns for simple objects
- Unnecessary inheritance hierarchies
- Over-configured systems

**Pass 3 - De-abstraction Proposals:**
- Suggest direct implementations
- Remove unnecessary layers
- Simplify configuration systems
- Inline single-use abstractions
- Balance flexibility vs complexity

### 5. **Dependency Simplification Agent**
Optimizes dependencies and coupling.

**Pass 1 - Dependency Analysis:**
- Map import/require statements
- Identify circular dependencies
- Find unused dependencies
- Detect over-coupling between modules
- Analyze external package usage

**Pass 2 - Optimization Opportunities:**
- Unused imports to remove
- Circular dependencies to break
- Tightly coupled modules to decouple
- External packages that can be replaced with native code
- Heavy dependencies used for simple features

**Pass 3 - Restructuring Plan:**
- Suggest dependency injection where needed
- Provide decoupling strategies
- Recommend native alternatives
- Show impact on bundle size
- Ensure no functionality loss

## Output Format:

### Generate Simplification Report in Obsidian

1. **Create report structure**:
   ```bash
   OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/Obsidian/Development}"
   PROJECT_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null) || echo "unknown")
   PARENT_DIR=$(basename $(dirname $(git rev-parse --show-toplevel 2>/dev/null)) || echo "projects")
   DATE=$(date +%Y-%m-%d-%H%M)
   
   REPORT_DIR="${OBSIDIAN_VAULT}/claude-sessions/${PARENT_DIR}/${PROJECT_NAME}"
   mkdir -p "$REPORT_DIR"
   
   REPORT_FILE="${REPORT_DIR}/simplification-analysis-${DATE}.md"
   ```

2. **Report template**:
   ```markdown
   # Code Simplification Analysis
   
   **Date:** [Current Date]
   **Analyzer:** Claude Simplification Framework
   **Target Path:** [Path]
   
   ## Executive Summary
   
   ### Complexity Score: [Score]/100
   **Current State:** [Complex|Moderate|Simple]
   
   ### Key Findings
   - 📊 **Patterns:** [X] inconsistencies found
   - 🔄 **Duplication:** [X]% code duplication
   - 📈 **Complexity:** Average cyclomatic complexity: [X]
   - 🔗 **Dependencies:** [X] circular dependencies
   - 🏗️ **Abstractions:** [X] over-engineered components
   
   ## Agent Analysis Results
   
   ### 1. Pattern Consistency Analysis
   
   #### Established Patterns
   - **Naming:** camelCase for functions, PascalCase for classes
   - **Structure:** [Pattern description]
   
   #### Inconsistencies Found
   | File | Pattern Violation | Severity | Fix |
   |------|------------------|----------|-----|
   | file.ts:42 | snake_case function | Medium | Rename to camelCase |
   
   ### 2. Code Complexity Analysis
   
   #### High Complexity Functions
   | Function | Complexity | Lines | Recommendation |
   |----------|------------|-------|----------------|
   | processData() | 15 | 120 | Split into 3 functions |
   
   #### Simplification Examples
   ```typescript
   // Before (Complexity: 8)
   function processUser(user) {
     if (user) {
       if (user.active) {
         if (user.role === 'admin') {
           // ...
         }
       }
     }
   }
   
   // After (Complexity: 3)
   function processUser(user) {
     if (!user?.active) return;
     if (user.role !== 'admin') return;
     // ...
   }
   ```
   
   ### 3. DRY Principle Analysis
   
   #### Duplication Summary
   - **Total Duplicates:** [X] blocks
   - **Lines Saved:** ~[X] lines
   - **Files Affected:** [X]
   
   #### Major Duplications
   ```typescript
   // Found in 5 locations
   const validateEmail = (email) => {
     const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
     return re.test(email);
   };
   
   // Recommendation: Extract to utils/validators.ts
   ```
   
   ### 4. Abstraction Level Analysis
   
   #### Over-Engineering Detected
   - **SingletonFactory** for simple config object
   - **AbstractBaseController** with one implementation
   - **IUserInterface** wrapping a simple type
   
   ### 5. Dependency Analysis
   
   #### Circular Dependencies
   ```mermaid
   graph LR
     A[moduleA] --> B[moduleB]
     B --> C[moduleC]
     C --> A
   ```
   
   ## Prioritized Action Items
   
   ### 🔴 High Priority (Immediate)
   1. **Break circular dependency** between auth and user modules
   2. **Extract duplicate validation** functions to shared utils
   3. **Simplify processData()** function (complexity: 15 → 5)
   
   ### 🟡 Medium Priority (This Sprint)
   1. **Standardize naming** across 12 files
   2. **Remove unused dependencies** (saves 2.3MB)
   3. **Flatten nested callbacks** in API handlers
   
   ### 🟢 Low Priority (Backlog)
   1. **Remove singleton pattern** from config
   2. **Inline single-use interfaces**
   3. **Update import organization**
   
   ## Implementation Roadmap
   
   ### Phase 1: Pattern Alignment (Week 1)
   - [ ] Run automated formatter with agreed rules
   - [ ] Update ESLint configuration
   - [ ] Fix naming inconsistencies
   
   ### Phase 2: Complexity Reduction (Week 2)
   - [ ] Refactor high-complexity functions
   - [ ] Implement early returns pattern
   - [ ] Extract nested logic to helpers
   
   ### Phase 3: DRY Implementation (Week 3)
   - [ ] Create shared utility modules
   - [ ] Consolidate validation logic
   - [ ] Remove code duplicates
   
   ## Metrics & Impact
   
   ### Before vs After
   | Metric | Current | Target | Improvement |
   |--------|---------|--------|-------------|
   | Avg Complexity | 8.2 | 4.0 | 51% |
   | Code Duplication | 18% | 5% | 72% |
   | Bundle Size | 4.2MB | 3.1MB | 26% |
   | Test Coverage | 67% | 85% | +18% |
   
   ## Code Examples
   
   ### Pattern Standardization
   [Specific examples with before/after]
   
   ### Complexity Reduction
   [Specific examples with before/after]
   
   ### Dependency Cleanup
   [Specific examples with before/after]
   
   ---
   
   *Generated by Claude Simplification Framework*
   *Next Analysis Recommended: [Date + 1 month]*
   ```

## Implementation Process:

1. **Initialize Analysis**:
   ```bash
   echo "Starting code simplification analysis..."
   TARGET="${ARGUMENTS:-.}"
   ```

2. **Run All Agents in Parallel**:
   ```
   Launch 5 concurrent sub-agents:
   - Pattern Consistency Agent
   - Code Complexity Agent  
   - DRY Principle Agent
   - Abstraction Level Agent
   - Dependency Simplification Agent
   
   Each agent independently performs:
     Pass 1: Analyze and collect data
     Pass 2: Identify opportunities
     Pass 3: Generate recommendations
   ```

3. **Aggregate Results**:
   - Wait for all agents to complete
   - Combine findings from all agents
   - Remove conflicting suggestions
   - Prioritize by impact and effort
   - Generate unified recommendations

4. **Save to Obsidian**:
   - Create comprehensive report
   - Include code examples
   - Add visual diagrams where helpful
   - Link to related documentation

## Example Usage:
```
Command: atm-simplify
# or
Command: atm-simplify src/components

Output:
Running simplification analysis...
Launching 5 agents in parallel...

[Parallel Execution]
├─ Pattern Consistency Agent: Analyzing...
├─ Code Complexity Agent: Analyzing...
├─ DRY Principle Agent: Analyzing...
├─ Abstraction Level Agent: Analyzing...
└─ Dependency Agent: Analyzing...

✓ All agents completed (elapsed: 12.3s)

Results Summary:
✓ Pattern Consistency Agent: Found 23 inconsistencies
✓ Code Complexity Agent: Identified 8 high-complexity functions
✓ DRY Principle Agent: Detected 18% code duplication
✓ Abstraction Level Agent: Found 5 over-engineered components
✓ Dependency Agent: Discovered 3 circular dependencies

Aggregating findings...
Generating simplification report...
✓ Report saved to: ~/Documents/Obsidian/Development/claude-sessions/project/simplification-analysis-2024-01-15.md

Summary:
- Complexity Score: 72/100 (Moderate)
- Potential code reduction: ~1,200 lines
- Bundle size reduction: 1.1MB
- 15 high-priority simplifications identified

View full report in Obsidian for detailed recommendations.
```

## Notes:
- All 5 agents run in parallel for faster analysis
- Each agent focuses on a specific aspect of simplification
- The 3-pass approach ensures thorough analysis
- Recommendations maintain functionality while reducing complexity
- All suggestions align with existing codebase patterns
- Report includes concrete examples and implementation steps