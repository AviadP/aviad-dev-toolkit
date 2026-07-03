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
  version: 1.1.0
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
5. **Apply Validation Categories**: Read `references/validation-categories.md`
   and systematically check the plan against all 9 categories
6. **Identify Issues**: Document weaknesses, assumptions, and inefficiencies found
7. **Suggest Improvements**: Provide specific, actionable recommendations
8. **Categorize by Severity**: Classify issues as Critical, Important, or Minor
9. **Present Findings**: Deliver structured feedback with checklist format

## Validation Categories

The detailed checklists live in `references/validation-categories.md` — read
that file when applying them (step 5), or hand its path to agents in deep mode.

| # | Category | Focus |
|---|----------|-------|
| 1 | Code Reusability | Does proposed code already exist? Extend instead of duplicate |
| 2 | Architecture & Design | SRP, coupling/cohesion, artifact wiring, dependency & abstraction justification (YAGNI) |
| 3 | Framework & Project Conventions | Match existing patterns, correct framework feature use, reliable cleanup |
| 4 | Project-Specific Guidelines | CLAUDE.md rules: type hints, early returns, specific exceptions |
| 5 | Performance & Scalability | Batching/caching, N+1, pagination, resource leaks, race-prone timing |
| 6 | Assumptions & Edge Cases | Environment assumptions, partial failures, input validation, hardcoded values |
| 7 | Testing Strategy | Testable in isolation, deterministic, manageable fixtures |
| 8 | UI & Integration | Unverified navigation/state assumptions, arbitrary sleeps, minimal interactions |
| 9 | Scope Reduction | Silent requirement downgrades ("v1", "hardcoded for now") — always Critical |

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
- The absolute path of `references/validation-categories.md` (resolve it from
  this skill's directory) plus which category numbers to apply — the agent
  reads the file itself; do NOT paste category text into the prompt
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

## References

- `references/validation-categories.md` — the 9 detailed category checklists
  (single source of truth for what to check)
- Project-specific pattern files can be added to `references/` to extend
  validation with domain knowledge, e.g., `references/ocs_ci_patterns.md` —
  OCS-CI fixture, factory, and test patterns

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
