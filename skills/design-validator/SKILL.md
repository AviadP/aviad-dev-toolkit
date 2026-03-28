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

## Entry Gates

Before validation can begin, verify:

1. **Plan exists** — the user must provide a plan to validate (document, conversation,
   or description). If missing, ask for it.
2. **Plan has enough detail** — the plan must describe specific files, functions,
   or components to change. If too vague, ask clarifying questions first.
3. **Project context available** — read CLAUDE.md / project config to understand
   project-specific conventions. If no project config exists, proceed with
   generic best practices only.

## Validation Workflow

Follow these steps to validate a plan:

1. **Detect Project Context**: Read CLAUDE.md and scan the codebase to identify
   the framework, language conventions, and project-specific patterns. Load any
   matching reference files from `references/` (e.g., `ocs_ci_patterns.md` for
   OCS-CI projects).
2. **Review the Plan**: Read the complete plan to understand the proposed approach
3. **Apply Validation Criteria**: Systematically check against each validation category below
4. **Identify Issues**: Document weaknesses, assumptions, and inefficiencies found
5. **Suggest Improvements**: Provide specific, actionable recommendations
6. **Categorize by Severity**: Classify issues as Critical, Important, or Minor
7. **Present Findings**: Deliver structured feedback with checklist format

## Validation Criteria

### 1. Code Reusability

**Check for:**
- Whether proposed new functions/classes already exist in the codebase
- Opportunities to extend existing utilities instead of creating duplicates
- Whether helper functions should be in shared modules vs test-specific locations

**Questions to ask:**
- Can existing factory functions, helpers, or utilities be used?
- Is this functionality already available in shared/helper modules?
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

### 3. Framework & Project Conventions

Auto-detect the project's framework and conventions by reading CLAUDE.md,
config files, and existing code patterns. Then check the plan against them.

**Check for:**
- Adherence to the project's established patterns (test structure, base classes,
  resource management, naming conventions)
- Correct use of framework-specific features (fixtures, middleware, hooks,
  decorators, lifecycle methods)
- Cleanup and teardown strategy matching the project's convention
- Proper use of project markers, annotations, or metadata

**How to detect conventions:**
- Read CLAUDE.md / project config for explicit rules
- Grep existing code for base classes, common imports, and patterns
- Check `references/` for project-specific pattern files (e.g.,
  `ocs_ci_patterns.md` for OCS-CI projects)
- Look at existing tests/code for the dominant style

**Questions to ask:**
- Does the plan follow the patterns established in existing code?
- Are framework features used correctly (not fighting the framework)?
- Will resource cleanup happen reliably on failure?
- Are all required metadata/markers/annotations present?

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

### 8. UI & Integration Considerations

For plans involving UI, API, or integration work, additionally check:
- Unnecessary interactions that could cause state or timing issues
- Assumptions about navigation paths, API response order, or external state
- Timing-based fixes (sleeps, arbitrary waits) masking architectural problems
- Missing verification steps between actions
- Environment-specific behavior differences (dev vs staging vs prod)

**Questions to ask:**
- Could architectural changes eliminate timing dependencies?
- Are navigation/request paths verified, not assumed?
- Are wait conditions explicit (wait for element/response) rather than arbitrary sleeps?
- Is the plan making the minimal necessary interactions to achieve its goal?

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
- [ ] Framework & project conventions followed
- [ ] Project guidelines (CLAUDE.md) adhered to
- [ ] Performance considerations addressed
- [ ] Assumptions documented and validated
- [ ] Edge cases handled
- [ ] Testing strategy sound

### Summary
- Total issues found: [count by severity]
- Recommendation: [Approve / Revise / Reject]
- Key changes needed: [top 2-3 most important changes]

## Exit Gates

Before presenting the final report, verify:

1. **All 8 categories evaluated** — every validation category has been checked,
   even if no issues were found (mark as "No issues")
2. **Issues are actionable** — each finding has a specific recommendation, not
   just "this could be better"
3. **Severity is justified** — Critical issues have clear failure/bug risk,
   not just style preferences

## Usage Example

**User provides plan:**
"I plan to add a caching layer for API responses. I'll create a `CacheManager`
class with `get()`, `set()`, and `invalidate()` methods, store cache in Redis,
and add a middleware that checks cache before hitting the database."

**Design validator checks:**
1. **Reusability**: Search for existing cache utilities in the codebase
2. **Architecture**: Does CacheManager have single responsibility? Is middleware
   the right pattern here?
3. **Framework conventions**: Read CLAUDE.md, check how middleware is used in
   existing code
4. **Performance**: TTL strategy? Cache invalidation approach? Memory limits?
5. **Edge cases**: What happens when Redis is down? Cache stampede?
6. **Output**: Present findings with severity categories and recommendations

## References

Project-specific pattern files can be placed in `references/` to extend
validation with domain knowledge:
- `references/ocs_ci_patterns.md` — OCS-CI fixture, factory, and test patterns

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
