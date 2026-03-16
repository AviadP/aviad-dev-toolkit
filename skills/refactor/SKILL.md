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
  version: 1.0.0
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

### Phase 1: Issue Discovery
1. User selects/points to code to analyze
2. Skill performs comprehensive analysis across 8 categories:
   - Architectural Issues
   - Edge Cases & Boundary Conditions
   - Usage Pattern Problems
   - State Management Issues
   - Exception Handling Weaknesses
   - API Design Problems
   - Performance Issues
   - Documentation & Usability Issues
3. Presents findings with severity levels (Critical/High/Medium/Low)
4. **STOPS and waits for user confirmation/comments**

### Phase 2: Solution Design
5. After user confirmation, researches modern best practices
6. Designs fixes for Critical + High severity issues
7. Identifies overlaps, conflicts, and synergies between fixes
8. Presents implementation plan with:
   - Backward compatibility guarantees
   - User priority decision points
   - Implementation order
   - Code examples

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

4. **Create summary table:**
   ```
   | Category | Critical | High | Medium | Low | Total |
   |----------|----------|------|--------|-----|-------|
   | Architectural | X | X | X | X | XX |
   ...
   | TOTAL | X | X | X | X | XX |
   ```

5. **Present findings to user:**
   - Use clear markdown formatting
   - Include line numbers for all issues
   - Show code examples
   - Use emojis for severity: 🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low
   - End with: "I've identified XX issues. Would you like me to proceed with designing solutions for Critical and High severity issues, or would you like to discuss these findings first?"

6. **STOP and wait for user response**
   - Do NOT proceed to Phase 2 until user confirms
   - Listen to user comments/concerns
   - Adjust analysis if user provides additional context

### PHASE 2: SOLUTION DESIGN

Only proceed after user confirms they want solutions.

7. **Research modern best practices:**

   Use Task tool with subagent_type=Plan to research:
   - Modern libraries solving similar problems (search web for 2023-2025)
   - Industry best practices for each issue type
   - Type hint patterns (Python 3.9+)
   - Backward compatibility strategies
   - Testing approaches

   **Important:** DO NOT copy code from other libraries, only learn patterns

8. **Design fixes following these rules:**

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

9. **Create detailed fix plan for each Critical/High issue:**

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

10. **Create Overlaps & Conflicts Matrix:**
    ```markdown
    | Fix | Overlaps With | Conflicts With | Priority |
    |-----|--------------|----------------|----------|
    | ... | ... | ... | ... |
    ```

11. **Identify synergy groups:**
    - Group fixes that should be implemented together
    - Note implementation order
    - Estimate LOC changes

12. **Present user decision points:**
    - List all questions that need user input
    - Provide recommendations
    - Explain trade-offs

13. **Show implementation plan:**
    - Phase 1: [No conflicts]
    - Phase 2: [Synergistic changes]
    - Phase 3: [Documentation]
    - Estimated effort

14. **Provide code example:**
    ```python
    # Show "before and after" usage
    # Demonstrate backward compatibility
    # Show new features in action
    ```

15. **Create final checklist** (per CLAUDE.md):
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

## Example Interaction

```
User: I want to refactor the TimeoutSampler class

Assistant (Phase 1): I'll analyze the TimeoutSampler class for you. Let me read it and search for usage patterns.

[Reads code, greps for usage, analyzes thoroughly]
Assistant (Phase 1 Results):
## TimeoutSampler Analysis Complete

I've identified 20 issues across 8 categories:

🔴 **CRITICAL (3):**
1. Exception Swallowing - all exceptions caught and logged, never re-raised
2. Non-Reusable Iterator - cannot reuse instance after timeout
3. No Failure Diagnostics - no way to tell why timeout occurred

🟠 **HIGH (6):**
4. No Thread Safety
5. Confusing Timeout Semantics
6. Inconsistent API Methods
... (full analysis)

**I've identified 20 issues. Would you like me to proceed with designing solutions for Critical and High severity issues, or would you like to discuss these findings first?**

User: Yes, proceed with solutions

Assistant (Phase 2): I'll research modern best practices and design fixes.

[Researches retry patterns, modern libraries, best practices]

Assistant (Phase 2 Results):
## Refactoring Plan for TimeoutSampler

### Fixes for 3 Critical + 6 High Severity Issues

**FIX 1: Exception Swallowing (CRITICAL)**
Solution: Add optional `reraise` and `on_exception` callback parameters...

**OVERLAPS:** Fixes 1, 3, 8 should be implemented together (unified callback system)

**CONFLICTS:** None

**User Decisions Needed:**
Q1: Accept reduced logging (use callbacks instead)?
Q2: Simple reset() method OR full reusable iterator?

[Complete fix plan with backward compatibility analysis]

User: Looks good, implement Fix 1, 3, and 8 together with the callback system
```

## Testing the Skill

To test this skill, save it and invoke with:
```
/refactor
```

Or Claude will automatically use it when you say:
```
I want to refactor [code/class/function]
```

## Notes

- This skill embodies the methodology used for the TimeoutSampler analysis
- Two-phase approach ensures user involvement and buy-in
- Maintains API compatibility as core principle
- Evidence-based analysis using codebase search
- Modern research ensures solutions follow industry standards
- Explicit conflict/overlap analysis prevents implementation issues

---

**Skill Version:** 1.0  
**Created:** 2025-11-04  
**Compatible with:** Python codebases (adaptable to other languages)
