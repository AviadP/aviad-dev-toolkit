---
name: refactor
description: >
  Analyze code for issues and design refactoring solutions with two-phase
  workflow: comprehensive analysis across 8 categories, then backward-compatible
  fix design. Use when user says "refactor this", "analyze this code",
  "find issues in this function", or points to code that needs improvement.
  Do NOT use for simple renames or formatting changes.
metadata:
  author: Aviad Polak
  version: 1.1.0
---

# Refactor Skill

This skill performs comprehensive code analysis and refactoring planning in two phases:
1. **Analysis Phase**: Deep dive into code issues, weaknesses, and edge cases
2. **Solution Phase**: Design detailed fixes with backward compatibility

## When to Use This Skill

Use this skill when you need to:
- Analyze a specific function, class, or code module for problems
- Identify architectural issues, edge cases, and anti-patterns
- Plan refactoring that maintains API compatibility
- Get actionable recommendations with priority and conflict analysis

## How It Works

**Phase 1** analyzes the code across 8 categories (detailed in Instructions),
presents findings by severity, then **STOPS for user confirmation**.
**Phase 2** researches best practices, designs backward-compatible fixes for
Critical/High issues with overlap/conflict analysis, and presents an
implementation plan with user decision points.

## Instructions

### PHASE 1: ANALYSIS

When the user invokes this skill or asks to refactor code:

1. **Identify the code to analyze:**

   If user hasn't specified code yet, ask:
   > "Please point me to the code you'd like to refactor. You can:
   > - Provide a file path and line range
   > - Paste the code snippet
   > - Describe the function/class name and location"

2. **Read and understand the code:**
   - Use Read tool to get the code
   - Understand its purpose, API, and usage
   - Use Grep to find all usage patterns in the codebase
   - Search for test files that test this code

3. **Perform comprehensive analysis using this framework:**

   Create a detailed report covering ALL of these categories:

   #### 1. ARCHITECTURAL ISSUES
   - Design flaws and anti-patterns
   - Thread-safety problems
   - Reusability limitations
   - State management design
   - Coupling and cohesion issues

   **For each issue:**
   - Location (file:line)
   - Severity (Critical/High/Medium/Low)
   - Code example showing the problem
   - Impact on users/system
   - Evidence from real usage (if found via Grep)

   #### 2. EDGE CASES & BOUNDARY CONDITIONS
   - Timeout vs interval interactions
   - Boundary value behaviors (e.g., timeout == sleep)
   - Long-running function behaviors
   - Empty/null/zero inputs
   - Race conditions

   **Include:**
   - Test evidence (search for test files)
   - Expected vs actual behavior
   - Documentation gaps

   #### 3. USAGE PATTERN PROBLEMS
   - Search codebase for how it's actually used (Grep)
   - Identify misuse patterns
   - Find workarounds users have created
   - Count usage frequency
   - Inconsistent expectations

   **Quantify:**
   - "Found 399 usages of pattern X"
   - "3 different usage patterns found"
   - Show examples from real code

   **YAGNI check:**
   - If a method/class/parameter has zero usages, flag it for removal
     instead of refactoring — don't improve dead code
   - If a method has 1-2 usages, consider inlining instead of refactoring
   - Only invest in refactoring code that is actively used

   **Stdlib replacement check:**
   - For each function being refactored, check if stdlib already ships the
     same functionality — if so, flag for replacement, not refactoring
   - Check if a native platform feature covers it (DB constraint, CSS feature,
     built-in browser API) before improving the hand-rolled version
   - Don't improve what you should delete

   #### 4. STATE MANAGEMENT ISSUES
   - Mutable instance variables
   - State initialization problems
   - Unused or dead state
   - State synchronization

   #### 5. EXCEPTION HANDLING WEAKNESSES
   - What exceptions are caught/swallowed
   - Missing exception types
   - Exception logging (too much/too little)
   - System exception handling (KeyboardInterrupt, etc.)

   #### 6. API DESIGN PROBLEMS
   - Confusing method names
   - Inconsistent return types
   - Unclear semantics
   - Missing parameters
   - Duplicate functionality

   #### 7. PERFORMANCE ISSUES
   - Inefficient algorithms
   - Resource leaks
   - Redundant operations
   - Blocking calls

   #### 8. DOCUMENTATION & USABILITY ISSUES
   - Missing type hints (per CLAUDE.md guidelines)
   - Misleading docstrings
   - Undocumented behavior
   - Missing examples

4. **Calibrate findings:**
   Before assigning final severities, consult `references/thinking-models.md`
   to verify each finding's severity reflects actual impact and scope.

5. **Create summary table:**
   ```
   | Category | Critical | High | Medium | Low | Total |
   |----------|----------|------|--------|-----|-------|
   | Architectural | X | X | X | X | XX |
   ...
   | TOTAL | X | X | X | X | XX |
   ```

6. **Present findings to user:**
   - Use clear markdown formatting
   - Include line numbers for all issues
   - Show code examples
   - Use emojis for severity: 🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low
   - End with: "I've identified XX issues. Would you like me to proceed with designing solutions for Critical and High severity issues, or would you like to discuss these findings first?"

7. **STOP and wait for user response**
   - Do NOT proceed to Phase 2 until user confirms
   - Listen to user comments/concerns
   - Adjust analysis if user provides additional context

### PHASE 2: SOLUTION DESIGN

Only proceed after user confirms they want solutions.

8. **Research modern best practices:**

   Use the Agent tool with subagent_type=Plan to research:
   - Modern libraries solving similar problems (search web for 2023-2025)
   - Industry best practices for each issue type
   - Type hint patterns (Python 3.9+)
   - Backward compatibility strategies
   - Testing approaches

   **Important:** DO NOT copy code from other libraries, only learn patterns

9. **Design fixes following these rules:**

   **RULE 1: DO NOT BREAK API**
   - All existing calls must continue working
   - New features via optional parameters only
   - Default values maintain current behavior

   **RULE 2: Identify overlaps and conflicts**
   - Which fixes work together (synergy)?
   - Which fixes conflict?
   - Can some issues be fixed together?

   **RULE 3: Backward compatibility**
   - Calculate compatibility % for each fix
   - Mark any breaking changes clearly
   - Suggest deprecation path if needed

   **RULE 4: Architectural catch**
   - If 3+ Critical/High issues share a root cause (e.g., shared mutable
     state, tight coupling, wrong abstraction level), STOP designing
     individual fixes
   - Flag it: "These issues are symptoms of an architectural problem:
     [description]. Individual fixes will create new problems. Consider
     redesigning [component] instead."
   - Present the architectural alternative alongside individual fixes
   - Let the user decide: patch symptoms or fix architecture

10. **Create detailed fix plan for each Critical/High issue:**

   For each fix, provide:
   ```markdown
   ### ✅ FIX #: [Issue Name] ([SEVERITY])
   **Lines:** [specific lines]
   **Current Problem:** [brief description]

   **Solution:**
   [Detailed description with code examples]

   **Backward Compatibility:** ✅ XX%
   [Explanation of compatibility]

   **OVERLAPS with:**
   - ✅ Fix #X (describe synergy)

   **CONFLICTS with:**
   - ⚠️ Fix #Y (describe conflict)

   **User Priority Decision Needed:**
   - **Q#:** [Specific question for user]
   ```

11. **Create Overlaps & Conflicts Matrix:**
    ```markdown
    | Fix | Overlaps With | Conflicts With | Priority |
    |-----|--------------|----------------|----------|
    | ... | ... | ... | ... |
    ```

12. **Identify synergy groups:**
    - Group fixes that should be implemented together
    - Note implementation order
    - Estimate LOC changes

13. **Present user decision points:**
    - List all questions that need user input
    - Provide recommendations
    - Explain trade-offs

14. **Show implementation plan:**
    - Phase 1: [No conflicts]
    - Phase 2: [Synergistic changes]
    - Phase 3: [Documentation]
    - Estimated effort

15. **Provide code example:**
    ```python
    # Show "before and after" usage
    # Demonstrate backward compatibility
    # Show new features in action
    ```

16. **Create final checklist** (per CLAUDE.md):
    ```
    ## Checklist of Changes
    - [ ] File: path/to/file.py, Function: function_name, Line: 123
    - [ ] File: path/to/file.py, Function: other_function, Line: 456
    ...
    ```

## Critical Guidelines

### From CLAUDE.md (User's Instructions)
- Ask clarifying questions to ensure alignment
- Do NOT change code without approval
- Do NOT suggest unrelated changes
- If solution requires bypassing rules, mention it
- Create checklist at end with file:function:line

### Analysis Quality Standards
- Be thorough - check all 8 categories
- Use evidence from codebase (Grep for usage)
- Quantify issues ("found 50 usages")
- Show real examples from code
- Include test file evidence

### Solution Quality Standards
- Research modern patterns (web search)
- Explain pros/cons for approaches
- Show 2-3 alternatives when applicable
- Consider both short-term and long-term impacts
- Type hints required (per CLAUDE.md)

### Communication Style
- Ultra-clear markdown formatting
- Code examples for everything
- Severity emojis: 🔴🟠🟡🟢
- Tables for summaries
- Section dividers (---)
- No unnecessary superlatives

## Red Flags

These thoughts mean you're shortcutting the process:

| Thought | Reality |
|---------|---------|
| "I can see the fix without analyzing" | You'll miss related issues. Analyze first. |
| "Just this one function, no need to grep" | Usage patterns reveal the real problems. Grep. |
| "3 fixes failed but the 4th will work" | Stop. 3+ failures = wrong architecture. |
| "This code is unused but let's improve it anyway" | YAGNI. Remove it instead. |
| "The fix is small, no need for compatibility check" | Small fixes break callers too. Check. |
| "Let's skip Phase 1 and go straight to fixing" | Fixing without analysis creates new bugs. |

## Example Interaction

```
User: I want to refactor the TimeoutSampler class

Agent (Phase 1): [Reads code, greps for usage patterns, analyzes all 8 categories]
       "I've identified 20 issues: 🔴 3 Critical (exception swallowing,
       non-reusable iterator, no failure diagnostics), 🟠 6 High, ...
       Proceed with designing solutions for Critical + High, or discuss first?"

User: Proceed

Agent (Phase 2): [Researches modern retry patterns via Plan agent]
       "FIX 1: Exception Swallowing — add optional `reraise` and
       `on_exception` callback params. Backward compatible: 100%.
       OVERLAPS: Fixes 1, 3, 8 → implement together (unified callbacks).
       Decision needed — Q1: callbacks instead of logging? Q2: simple
       reset() or full reusable iterator?"

User: Implement Fix 1, 3, and 8 together with the callback system
```
