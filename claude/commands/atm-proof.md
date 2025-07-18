# Mathematical Proof Analysis for Code Module

Analyze a code module as a mathematician/logician to create a formal finite state machine representation and identify edge cases, invariant violations, and logical inconsistencies.

**Module/File Path:** $ARGUMENTS

## Steps:

1. **Parse Module Structure**
   - Read the specified file/module
   - Identify all functions, classes, and their relationships
   - Extract type definitions, interfaces, and contracts
   - Map input/output relationships

2. **Build Formal Model**
   - Create finite state machine representation:
     - **States**: All possible states the module can be in
     - **Transitions**: Function calls and state changes
     - **Inputs**: Parameters, external dependencies
     - **Outputs**: Return values, side effects
   - Define invariants that should always hold
   - Identify preconditions and postconditions

3. **Formal Analysis**
   - **State Space Analysis**:
     - Enumerate all reachable states
     - Identify unreachable code paths
     - Find absorbing states (no exit)
   - **Transition Analysis**:
     - Verify all transitions are well-defined
     - Check for non-deterministic behavior
     - Identify race conditions
   - **Invariant Checking**:
     - List all invariants that should hold
     - Prove or disprove each invariant
     - Find states where invariants break

4. **Edge Case Discovery**
   - **Boundary Analysis**:
     - Numeric overflows/underflows
     - Empty collections/null values
     - Maximum/minimum values
   - **State Explosion**:
     - Combinatorial state growth
     - Recursive depth issues
   - **Concurrency Issues**:
     - Race conditions
     - Deadlock scenarios
     - Atomicity violations
   - **Type Safety**:
     - Implicit conversions
     - Type coercion edge cases
     - Generic type constraints

5. **Proof Construction**
   - For each critical function:
     - State the theorem (what it should do)
     - List assumptions/preconditions
     - Provide proof sketch or counterexample
     - Identify where proofs fail
   - Use formal notation where helpful:
     ```
     ∀ x ∈ Input : Precondition(x) ⟹ Postcondition(f(x))
     ```

6. **Generate Report**
   ```markdown
   # Formal Analysis of [Module Name]
   
   ## Finite State Machine Model
   [Visual or textual representation]
   
   ## Invariants
   ✓ Invariant 1: [Description] - HOLDS
   ✗ Invariant 2: [Description] - VIOLATED in state X
   
   ## Edge Cases Discovered
   1. **[Edge Case Name]**
      - Condition: [When it occurs]
      - Impact: [What breaks]
      - Proof: [Mathematical reasoning]
   
   ## Formal Proofs
   ### Theorem 1: [Function correctness]
   - Hypothesis: [Preconditions]
   - Conclusion: [Postconditions]
   - Proof: [Sketch or counterexample]
   
   ## Recommendations
   - Add guards for [edge case]
   - Strengthen invariant [X]
   - Consider [architectural change]
   ```

## Example Usage:
```
Command: atm-proof src/utils/parser.ts

Output:
Analyzing module: src/utils/parser.ts

## Finite State Machine Model
States: {INIT, PARSING, ERROR, COMPLETE}
Transitions:
  INIT → PARSING (on: parse())
  PARSING → ERROR (on: invalid input)
  PARSING → COMPLETE (on: valid parse)
  ERROR → INIT (on: reset())

## Edge Cases Discovered
1. **Stack Overflow on Nested Input**
   - Condition: Input with depth > 1000
   - Proof: No recursion limit check
   - Fix: Add depth parameter with limit

2. **Integer Overflow in Buffer Size**
   - Condition: size * count > MAX_INT
   - Proof: size × count ∈ ℤ but implementation assumes ∈ ℕ
   - Fix: Add overflow check before allocation
```

## Analysis Techniques:

### Abstract Interpretation
- Approximate program behavior
- Track value ranges and constraints
- Identify impossible states

### Hoare Logic
- {P} S {Q} - If P before S, then Q after S
- Build proof obligations
- Verify with SMT solver reasoning

### Model Checking
- Enumerate state space
- Check temporal properties
- Find counterexamples

## Focus Areas:
- Memory safety (buffer overflows, use-after-free)
- Numeric safety (overflow, division by zero)
- Concurrency safety (data races, deadlocks)
- Logic errors (off-by-one, incorrect conditionals)
- API contracts (precondition violations)

## Notes:
- Uses mathematical notation where it adds clarity
- Focuses on provable properties and counterexamples
- Provides actionable fixes for discovered issues
- Think like a mathematician: "What can go wrong?"