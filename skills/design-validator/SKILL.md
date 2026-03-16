---
name: design-validator
description: >
  Validates plans for new features, bug fixes, or code changes by identifying
  weak spots, wrong assumptions, inefficient ideas, missing considerations, and
  opportunities to reuse existing code. Use when user says "validate my plan",
  "review my design", "check my approach", "is this plan solid", or after
  completing any planning phase before implementation. Do NOT use during active
  implementation or for reviewing existing code.
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Design Validator

## Overview

Validate design plans for code changes by systematically reviewing architectural decisions, identifying assumptions, checking for inefficiencies, and ensuring alignment with project conventions. This skill helps catch issues early in the planning phase before implementation begins.

## When to Use

Invoke this skill after completing a plan for:
- New feature implementation
- Bug fix approach
- Refactoring strategy
- Architecture changes
- Test design

Do NOT use this skill during active implementation or for reviewing existing code.

## Validation Workflow

Follow these steps to validate a plan:

1. **Review the Plan**: Read the complete plan to understand the proposed approach
2. **Apply Validation Criteria**: Systematically check against each validation category below
3. **Identify Issues**: Document weaknesses, assumptions, and inefficiencies found
4. **Suggest Improvements**: Provide specific, actionable recommendations
5. **Categorize by Severity**: Classify issues as Critical, Important, or Minor
6. **Present Findings**: Deliver structured feedback with checklist format

## Validation Criteria

### 1. Code Reusability

**Check for:**
- Whether proposed new functions/classes already exist in the codebase
- Opportunities to extend existing utilities instead of creating duplicates
- Whether helper functions should be in shared modules vs test-specific locations

**Questions to ask:**
- Can existing factory functions, helpers, or utilities be used?
- Is this functionality already available in `ocs_ci.helpers` or other modules?
- Would this create code duplication?

**Search strategy:**
- Grep for similar function names and patterns
- Check relevant helper modules for existing implementations
- Review related test files for reusable patterns

### 2. Architecture and Design Patterns

**Check for:**
- Proper separation of concerns (single responsibility)
- Coupling and cohesion issues
- Appropriate abstraction levels
- Violation of DRY (Don't Repeat Yourself)
- Over-engineering or over-complication

**Questions to ask:**
- Does each component have a single, clear responsibility?
- Are dependencies minimized (low coupling)?
- Is related functionality grouped together (high cohesion)?
- Is the solution minimal yet maintainable?
- Does it follow existing patterns in the codebase?

### 3. OCS-CI Framework Conventions

**Check for:**
- Proper fixture usage for resource management
- Correct test class inheritance (ManageTest, E2ETest, etc.)
- Appropriate use of factories vs direct resource creation
- Cleanup strategy using finalizers vs try/finally
- Proper marker usage (tier, squad, polarion_id)

**Anti-patterns to watch for:**
- Using `request.node.cls` for class attributes
- Using globals for sharing data
- Using `@pytest.mark.usefixtures`
- Multiple asserts in teardown with actions between them
- Using `yield` in fixtures
- Using broad exception handling (`except Exception`)

**Questions to ask:**
- Are resources created via factories for automatic cleanup?
- Is the test class using the correct base class?
- Will cleanup happen reliably if tests fail?
- Are markers complete and correct?

### 4. Project-Specific Guidelines

**Check for:**
- Following CLAUDE.md guidelines (user's custom instructions)
- Type hints for new function arguments
- Early return pattern instead of nested if/else
- Specific exceptions instead of general Exception
- Error handling at function beginning
- Happy path placed last in functions

**Questions to ask:**
- Do functions use type hints?
- Is error handling using specific exceptions?
- Are early returns used for error conditions?
- Does the plan avoid unnecessary else statements?

### 5. Performance and Scalability

**Check for:**
- Unnecessary API calls or resource creation
- Missing pagination for large datasets
- Inefficient loops or repeated operations
- Resource cleanup to prevent leaks
- Timing assumptions that could cause race conditions

**Questions to ask:**
- Could operations be batched or cached?
- Will this scale with larger datasets?
- Are there N+1 query patterns?
- Could this create resource leaks?

### 6. Assumptions and Edge Cases

**Check for:**
- Implicit assumptions about environment state
- Missing error handling for edge cases
- Assumptions about resource availability
- Hard-coded values that should be configurable
- Missing validation of inputs

**Questions to ask:**
- What happens if resources don't exist?
- What if operations fail partway through?
- Are there edge cases not considered?
- What assumptions are being made?

### 7. Testing Strategy

**Check for:**
- Whether the approach is testable
- Missing test scenarios
- Difficulty in setting up test fixtures
- Whether tests will be reliable or flaky

**Questions to ask:**
- Can this be tested in isolation?
- Are all code paths testable?
- Will tests be deterministic?
- Are test fixtures manageable?

### 8. UI Test Specific Considerations

For UI test plans, additionally check:
- Unnecessary UI interactions that could cause state issues
- Navigation path assumptions
- Timing-based fixes masking architectural problems
- Missing visual verification steps
- Environment-specific behavior differences

**Questions to ask:**
- Could architectural changes eliminate timing dependencies?
- Are navigation paths verified, not assumed?
- Would screenshots help debug failures?
- Is the test making minimal necessary UI interactions?

## Output Format

Present validation findings in this structure:

### Critical Issues
Issues that would cause failures, major bugs, or violate core principles.
- **[Issue description]**
  - Current approach: [what the plan proposes]
  - Problem: [why this is critical]
  - Recommendation: [specific fix]
  - Reference: [file:line if applicable]

### Important Issues
Issues that reduce code quality, maintainability, or efficiency.
- **[Issue description]**
  - Current approach: [what the plan proposes]
  - Problem: [why this matters]
  - Recommendation: [specific improvement]
  - Reference: [file:line if applicable]

### Minor Issues
Improvements that would enhance the solution but aren't blocking.
- **[Issue description]**
  - Suggestion: [improvement idea]
  - Reference: [file:line if applicable]

### Validation Checklist
- [ ] Code reusability verified (no duplicate functions)
- [ ] Architecture follows SOLID principles
- [ ] OCS-CI conventions followed
- [ ] Project guidelines adhered to
- [ ] Performance considerations addressed
- [ ] Assumptions documented and validated
- [ ] Edge cases handled
- [ ] Testing strategy sound

### Summary
- Total issues found: [count by severity]
- Recommendation: [Approve / Revise / Reject]
- Key changes needed: [top 2-3 most important changes]

## Usage Example

**User provides plan:**
"I plan to add a UI test for bucket versioning. I'll create a new test class `TestBucketVersioning` in a new file, add helper functions `enable_versioning()` and `check_version_status()` in the test class, and use existing bucket fixtures."

**Design validator checks:**
1. **Reusability**: Search for existing versioning functions
2. **Architecture**: Helper functions should be in shared module if reusable
3. **OCS-CI conventions**: Verify fixture usage, test class structure
4. **UI considerations**: Check for minimal interactions, proper navigation
5. **Output**: Present findings with severity categories and recommendations

## References

This skill includes a reference file with common OCS-CI patterns and anti-patterns:
- `references/ocs_ci_patterns.md` - Detailed examples of correct and incorrect patterns

## Troubleshooting

Error: No plan provided
Cause: User invoked the skill without sharing a plan first
Solution: Ask the user to provide or describe their plan before running validation

Error: Plan is too vague to validate
Cause: Plan lacks specifics about files, functions, or approach
Solution: Ask clarifying questions about the intended implementation details before proceeding

Error: Cannot verify code reusability
Cause: Codebase not accessible or too large to search
Solution: Skip reusability checks, note them as unverified in the validation output
