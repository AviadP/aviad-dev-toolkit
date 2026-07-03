# Validation Categories — Detailed Checklists

Used by the design-validator skill. Single-pass mode: the orchestrator reads
this file and checks the plan against every category. Deep mode: each agent
reads this file and applies its assigned categories.

Classify every finding as **Critical / Important / Minor**. Be adversarial —
the job is to find what's wrong, not to praise what's right.

## 1. Code Reusability

Check:
- Do proposed new functions/classes already exist in the codebase? Grep for
  similar function names and patterns before accepting new ones
- Can existing factories, helpers, or utilities be used or extended instead
  of creating duplicates? Check shared/helper modules and related test files
- Should proposed helpers live in shared modules rather than test-specific
  locations?
- Would the plan introduce code duplication anywhere?

## 2. Architecture and Design Patterns

Check:
- Single, clear responsibility per component; low coupling, high cohesion
- Appropriate abstraction level; no DRY violations; no over-engineering
- Solution is minimal yet maintainable and follows existing codebase patterns

**Artifact wiring** — planned artifacts must connect, not exist in isolation:
- Component → API: does a task mention the fetch/request call?
- API → Database: does a task mention the query/ORM call?
- Form → Handler: does a task mention the onSubmit/action implementation?
- State → Render: does a task mention displaying the state?
- Two artifacts planned but no task connects them → flag: "Plan creates [X]
  and [Y] but no task wires them together"

**Dependency justification** — the plan adds a dependency where stdlib or a
native platform feature covers it → Important. Every new dependency is a
future maintenance burden; justify the cost.

**Abstraction justification** — interface with one implementation, factory
with one product, config layer for a value that never changes → YAGNI until
a second user proves the abstraction.

## 3. Framework & Project Conventions

Detect conventions first: read CLAUDE.md/project config for explicit rules;
grep existing code for base classes, common imports, and the dominant style;
check `references/` for project-specific pattern files (e.g.,
`ocs_ci_patterns.md` for OCS-CI projects).

Check:
- Plan follows established patterns: test structure, base classes, naming,
  resource management
- Framework features used correctly (fixtures, middleware, hooks, decorators,
  lifecycle methods) — not fighting the framework
- Cleanup/teardown matches the project convention and happens reliably on
  failure
- Required markers, annotations, or metadata are present

## 4. Project-Specific Guidelines

Check the plan against CLAUDE.md (the user's custom instructions), including:
- Type hints on new function arguments
- Early returns for error conditions instead of nested if/else; no
  unnecessary else statements
- Specific exceptions instead of general Exception
- Error handling at the beginning of functions, happy path last

## 5. Performance and Scalability

Check:
- Unnecessary API calls or resource creation — could operations be batched
  or cached?
- Missing pagination for large datasets; will this scale? N+1 query patterns?
- Inefficient loops or repeated operations
- Resource cleanup — could this leak?
- Timing assumptions that could cause race conditions

## 6. Assumptions and Edge Cases

Check:
- Implicit assumptions about environment state or resource availability —
  what happens if resources don't exist?
- What happens if operations fail partway through?
- Missing validation of inputs
- Hard-coded values that should be configurable
- List any undocumented assumptions explicitly

## 7. Testing Strategy

Check:
- Can the approach be tested in isolation? Are all code paths testable?
- Missing test scenarios
- Will tests be deterministic, or flaky?
- Are test fixtures manageable to set up?

## 8. UI & Integration Considerations

For plans involving UI, API, or integration work:
- Unnecessary interactions that could cause state or timing issues — is the
  plan making the minimal interactions needed to achieve its goal?
- Assumptions about navigation paths, API response order, or external state —
  verified, not assumed?
- Timing-based fixes (sleeps, arbitrary waits) masking architectural
  problems — wait conditions must be explicit (wait for element/response),
  and architectural changes should eliminate timing dependencies
- Missing verification steps between actions
- Environment-specific behavior differences (dev vs staging vs prod)

## 9. Scope Reduction Detection

Plans sometimes silently downgrade requirements — the plan "looks complete"
because it mentions the requirement, but the proposed implementation
delivers less than what was specified.

Scan plan text for reduction language:
- "v1", "simplified version", "basic version", "minimal version"
- "static for now", "hardcoded", "placeholder", "stub"
- "will be wired later", "future enhancement", "dynamic in future"
- "skip for now", "out of scope for this iteration"
- "too complex", "non-trivial" (when used to justify omission)

For each match, cross-reference with the original requirement:
- Does the plan deliver what the requirement actually says, or a reduced
  version?
- Did the user explicitly approve a phased approach, or did the plan invent
  one?
- Are there "v1/v2" splits the user never asked for? Deferred parts of a
  requirement not flagged to the user?

**Severity: always Critical.** Scope reduction means the user's requirement
will not be delivered as specified. If the plan can't fit the full
requirement, it should propose splitting — not silently simplifying.

Example:
- Requirement: "Dashboard shows calculated costs from pricing table"
- Plan says: "Display static cost labels (dynamic pricing is future enhancement)"
- Issue: reduces the requirement from calculated/dynamic to static/hardcoded
  without user approval
