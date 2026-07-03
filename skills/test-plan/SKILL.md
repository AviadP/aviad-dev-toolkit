---
name: test-plan
description: >
  This skill should be used when the user asks to "write a test plan",
  "create test cases", "plan testing for a feature", "what should we test",
  "test plan for this feature", "design test scenarios", or provides a feature
  description and wants a structured test plan. Produces a comprehensive
  test plan table (test case | steps | expected result) with priority matrix.
  Does NOT write test code — only the plan.
metadata:
  author: Aviad Polak
  version: 1.1.0
---

# Test Plan Generator

## Overview

Generate comprehensive test plans for new features, bug fixes, or system changes.
Deeply analyze the feature through documentation, PR reviews, codebase exploration,
and user clarification to produce a structured test plan with prioritized scenarios
covering happy path, configuration, edge cases, negative tests, and scale.

This skill produces documentation only — no test code is written.

## Entry Gates

Before generating a test plan, verify:

1. **Feature description exists** — the user must provide a feature description,
   PR link, Jira/issue link, or verbal description. If missing, ask for it.
2. **Enough detail to test** — the description must explain what the feature does,
   not just its name. If too vague, ask clarifying questions.
3. **Project context available** — read CLAUDE.md to understand the project's
   testing conventions, markers, base classes, and patterns.

## Workflow

### Phase 1: Feature Understanding

Goal: Build a deep, grounded understanding of the feature before writing any test cases.

1. **Read the feature description** provided by the user. Extract:
   - What problem it solves
   - How it works (mechanism/algorithm)
   - What it changes (new behavior vs. existing behavior)
   - Configuration options and defaults
   - Dependencies on other systems
   - Scope boundaries (what's in scope vs. out of scope)

2. **Research the implementation** — launch Explore agents to investigate:
   - **Upstream PR/code**: If a PR link is provided, fetch and analyze the diff.
     Understand what files changed, what functions were added, what behavior shifted.
   - **Existing codebase**: Search for related tests, helpers, and patterns that
     already exist. Identify what's already tested and what gaps remain.
   - **Documentation**: Check for relevant docs, READMEs, or design documents
     in the repository.

3. **Ask clarification questions** — use AskUserQuestion (batch 2-4 related
   questions per round) to resolve ambiguity:
   - Target version/release for the feature
   - Scope: which subsystems to cover (e.g., ReclaimSpace only, or also KeyRotation?)
   - Environment requirements (specific platforms, cluster configs)
   - Priority: what matters most to test first?
   - Any known limitations or constraints

### Phase 2: Happy Path Design

Goal: Identify the single most important end-to-end flow that proves the feature works.

1. **Identify the core behavior** — what is the simplest, most expected use case?
2. **Trace the flow** — from trigger to observable outcome:
   - What action starts the feature?
   - What intermediate state changes occur?
   - What is the final observable result?
3. **Determine verification method** — how to confirm the feature worked:
   - Direct output (API response, resource state)
   - Side effects (logs, metrics, timestamps)
   - Absence of failure (no errors, no crash)
4. **Document as test case** — write the happy path as the first entry in the plan.

### Phase 3: Test Category Expansion

Goal: Systematically expand from happy path into comprehensive coverage.

Apply each category below to the feature. For each category, ask:
"What could go wrong here?" and "What variations matter?"

#### Categories to Cover

**1. Happy Path** — The default, expected behavior with standard inputs.

**2. Configuration** — Variations in settings, parameters, and options:
- Default values
- Custom values
- Disable/enable toggles
- Invalid configuration handling
- Configuration persistence across restarts

**3. Schedule/Timing Variations** (if applicable):
- Different intervals or schedules
- Short vs. long durations
- Boundary conditions (interval equals window, etc.)

**4. Determinism & Consistency**:
- Same input produces same output across runs
- Behavior survives component restarts
- State persists correctly

**5. Scale**:
- Many resources (10+, 100+)
- Concurrent operations
- Resource limits and quotas

**6. Interaction with Other Features**:
- Feature A + Feature B together
- Precedence rules when features overlap
- Backward compatibility with existing behavior

**7. Negative / Error Cases**:
- Invalid inputs
- Missing dependencies
- Partial failures (created 5 of 10, then error)
- Resource not found

**8. Lifecycle**:
- Create, modify, delete flows
- Upgrade/downgrade behavior
- Cleanup and teardown

### Phase 4: Structure the Output

Goal: Present the test plan in a scannable, actionable format.

A complete worked example lives in `references/example-test-plan.md` — read
it if unsure about format, step granularity, or priority assignment.

#### Test Plan Table Format

Use this exact format for the test plan:

```markdown
## Test Plan: [Feature Name] ([Ticket ID])

### Scope
[1-2 sentence description of what is being tested]

### [Category Name]

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 1 | **Descriptive name** | 1. Action one 2. Action two 3. Verify | Expected outcome |
```

#### Rules for Writing Test Cases

- **Test Case**: Bold, descriptive name (not "test 1"). Use sentence case.
- **Steps**: Numbered actions. Start with setup, end with verification.
  Keep steps atomic — one action per step. Use 3-6 steps per case.
- **Expected Result**: Observable, verifiable outcome. Not "it works" but
  "Value reads '2'" or "Jobs created at different timestamps".
- **One behavior per case**: Each test case verifies ONE thing. If two
  behaviors need testing, write two test cases.

#### Priority Matrix

End the test plan with a priority matrix:

```markdown
### Priority Matrix

| Priority | Test Cases | Rationale |
|----------|-----------|-----------|
| **P0 — Must have** | #1-5 | Core feature validation |
| **P1 — Should have** | #6-10 | Configuration and determinism |
| **P2 — Nice to have** | #11-15 | Edge cases and interactions |
| **P3 — Low priority** | #16-18 | Negative tests, rare scenarios |
```

Priority definitions:
- **P0**: Feature doesn't ship without these passing
- **P1**: Important coverage, should be in first test PR
- **P2**: Second PR or follow-up
- **P3**: Backlog, write when time allows

### Phase 5: Review with User

Goal: Validate the test plan before finalizing.

1. Present the complete test plan table
2. Ask the user:
   - "Does this cover the scenarios you care about?"
   - "Any test cases to add or remove?"
   - "Do the priorities look right?"
3. Iterate based on feedback

## Guidelines

- **No code** — this skill produces test plan documentation only. Do not write
  test implementations, fixtures, helpers, or any code.
- **Research first** — always explore the codebase and feature before writing
  test cases. Never guess at behavior.
- **Be specific** — "Verify stagger window is 2 hours" is better than
  "Verify feature works correctly."
- **Ground in reality** — every test case must be verifiable. If the verification
  method is unclear, note it and ask the user.
- **Reuse knowledge** — check what's already tested. Don't duplicate existing
  test coverage in the plan.
- **Mark implemented tests** — if some test cases are already implemented,
  mark them with *(implemented)* in the test case name.
- **Tag with ticket IDs** — if the user provides a Jira/Bugzilla/GitHub issue,
  include it in the plan header.
- **Consider test execution time** — note if a test case requires long waits
  (e.g., "requires ~5min for Jobs to appear") so the user can plan accordingly.

## Troubleshooting

Error: Feature description too vague
Cause: User provided a one-liner without enough detail
Solution: Ask for the PR link, design doc, or a more detailed description
before proceeding. Specific questions: "What does this feature change?",
"How is it configured?", "What's the default behavior?"

Error: No existing tests to reference
Cause: Brand new feature area with no prior test coverage
Solution: Proceed with the test plan based on feature description alone.
Note in the plan that no existing test patterns were found for reference.

Error: Feature spans multiple subsystems
Cause: Complex feature touching many components
Solution: Ask the user to prioritize which subsystems to cover first.
Generate separate test plan sections per subsystem.
