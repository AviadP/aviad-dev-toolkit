---
name: design-validator
description: >
  Validates plans for new features, bug fixes, or code changes by identifying
  weak spots, wrong assumptions, inefficient ideas, missing considerations, and
  opportunities to reuse existing code. Use when user says "validate my plan",
  "review my design", "check my approach", "is this plan solid", or after
  completing any planning phase before implementation. Supports --deep flag
  for parallel multi-agent validation on high-stakes plans. Do NOT use during
  active implementation or for reviewing existing code.
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

## Invocation

```
/design-validator                 # Single-pass validation (default)
/design-validator --deep          # Parallel multi-agent validation
```

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
2. **Extract the Goal**: Before checking categories, identify what the plan is
   supposed to achieve. Extract from the plan, architect blueprint, or user
   conversation:
   - The outcome (what should be true when implementation is done)
   - Key success criteria (2-5 observable behaviors or deliverables)
   - Keep these visible throughout validation — every category check should
     ask "does this serve the goal?" not just "is this well-designed?"
3. **Review the Plan**: Read the complete plan to understand the proposed approach
4. **Cross-Check Referenced Files**: Scan the plan for file paths, function names,
   API schemas, config references, or claims about existing code. For each reference:
   - Read the referenced file and verify the plan's claims match reality
   - Note contradictions (e.g., plan says "extend UserSchema" but the schema
     doesn't exist, or has a different structure than assumed)
   - Note stale references (file was moved, function was renamed)
   - Skip this step if the plan references no existing files
   Build a short list of contradictions found — feed these into the validation
   categories as Critical issues.
5. **Apply Validation Criteria**: Systematically check against each validation category below
6. **Identify Issues**: Document weaknesses, assumptions, and inefficiencies found
7. **Suggest Improvements**: Provide specific, actionable recommendations
8. **Categorize by Severity**: Classify issues as Critical, Important, or Minor
9. **Present Findings**: Deliver structured feedback with checklist format

## Deep Mode

When invoked with `--deep` or when the user asks for thorough/deep validation,
run steps 1-4 of the normal workflow first (context, goal, plan review,
cross-check), then replace steps 5-9 with parallel multi-agent validation.

### When to use

- Plans touching 5+ files or 3+ system components
- Architecture changes or new subsystem designs
- Plans where a missed issue is expensive (migrations, API contracts, auth flows)
- When the user explicitly asks for deeper review

### Agent split

Launch 3 agents in parallel using the Agent tool. Each gets the full plan text,
the context brief from step 4, and the goal from step 2. Each reviews
independently — they never see each other's output.

| Agent | Focus | Categories |
|-------|-------|------------|
| Structure & Reuse | Is this well-designed and does it fit the codebase? | 1 (Reusability), 2 (Architecture), 3 (Conventions) |
| Robustness & Risk | What will break when this hits reality? | 5 (Performance), 6 (Edge Cases), 7 (Testing), 8 (UI/Integration) |
| Intent & Scope | Does this deliver what was asked for? | 4 (Guidelines), 9 (Scope Reduction), + cross-check contradictions |

Each agent prompt must include:
- The plan text in full
- The context brief (contradictions found in step 4)
- The goal and success criteria (from step 2)
- The relevant validation category sections from this skill (paste them —
  the agent has no access to this document)
- Instructions to classify findings as Critical, Important, or Minor
- Instructions to be adversarial — find what's wrong, not what's right

### Consolidation

After all agents return:

1. **Deduplicate** — merge findings flagged by multiple agents, note agreement
2. **Resolve conflicts** — if agents disagree, note both positions
3. **Cross-cutting check** — after reading all reports, look for contradictions
   between agents that none of them could see individually:
   - Agent A says X is fine, but Agent B's finding implies X is broken
   - Two agents make incompatible assumptions about the same component
   - A finding from one agent invalidates a "no issues" from another
   Add any cross-cutting issues as new findings with severity justification.
4. **Prioritize** — Critical > Important > Minor
5. Present using the same Output Format as the normal workflow

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
- **Artifact wiring** — planned artifacts must connect to each other, not
  exist in isolation. If the plan creates a component AND an API route, some
  task must wire them together (fetch call, import, event handler)

**Wiring checks:**
- Component → API: does a task mention the fetch/request call?
- API → Database: does a task mention the query/ORM call?
- Form → Handler: does a task mention the onSubmit/action implementation?
- State → Render: does a task mention displaying the state?
- If two artifacts are planned but no task connects them, flag it:
  "Plan creates [X] and [Y] but no task wires them together"

**Dependency justification:**
- If the plan adds a new dependency, check: does stdlib or a native platform
  feature cover this? If yes, flag as Important.
- Every new dependency is a future maintenance burden — justify the cost.

**Abstraction justification:**
- Flag any planned interface with one implementation, factory with one product,
  or config layer for a value that never changes. These are YAGNI until a second
  user proves the abstraction.

**Questions to ask:**
- Does each component have a single, clear responsibility?
- Are dependencies minimized (low coupling)?
- Is related functionality grouped together (high cohesion)?
- Is the solution minimal yet maintainable?
- Does it follow existing patterns in the codebase?
- Are planned artifacts connected, or will they be created in isolation?
- Does the plan add dependencies that stdlib or the platform already covers?
- Does the plan introduce abstractions that have only one consumer?

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

### 9. Scope Reduction Detection

Plans sometimes silently downgrade requirements — the plan "looks complete"
because it mentions the requirement, but the proposed implementation delivers
less than what was specified.

**Scan plan text for reduction language:**
- "v1", "simplified version", "basic version", "minimal version"
- "static for now", "hardcoded", "placeholder", "stub"
- "will be wired later", "future enhancement", "dynamic in future"
- "skip for now", "out of scope for this iteration"
- "too complex", "non-trivial" (when used to justify omission)

**For each match, cross-reference with the original requirement:**
- Does the plan deliver what the requirement actually says, or a reduced version?
- Did the user explicitly approve a phased approach, or did the plan invent one?

**Severity:** Always Critical. Scope reduction means the user's requirement
will not be delivered as specified. If the plan can't fit the full requirement,
it should propose splitting — not silently simplifying.

**Example:**
- Requirement: "Dashboard shows calculated costs from pricing table"
- Plan says: "Display static cost labels (dynamic pricing is future enhancement)"
- Issue: Plan reduces the requirement from calculated/dynamic to static/hardcoded
  without user approval

**Questions to ask:**
- Does every planned feature match the depth of the original requirement?
- Are there "v1/v2" splits the user never asked for?
- Does the plan defer any part of a requirement to a later phase without flagging it?

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
- [ ] Architecture follows SOLID principles and artifacts are wired
- [ ] Framework & project conventions followed
- [ ] Project guidelines (CLAUDE.md) adhered to
- [ ] Performance considerations addressed
- [ ] Assumptions documented and validated
- [ ] Edge cases handled
- [ ] Testing strategy sound
- [ ] No silent scope reduction (plan delivers full requirements)

### Summary
- Total issues found: [count by severity]
- Recommendation: [Approve / Revise / Reject]
- Key changes needed: [top 2-3 most important changes]

## Exit Gates

Before presenting the final report, verify:

1. **All 9 categories evaluated** — every validation category has been checked,
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
