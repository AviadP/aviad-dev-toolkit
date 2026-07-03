---
name: verify
description: >
  Post-implementation verification — score how well the code matches the original
  requirements. Produces an intent adherence score (0-100) and per-criterion
  PASS/FAIL checklist with file:line evidence. Use when user says "verify my
  implementation", "does this match the spec", "check against requirements",
  "adherence check", or after completing a feature before creating a PR. Do NOT
  use during planning or for code quality review — use design-validator or
  code-quality for those.
metadata:
  author: Aviad Polak
  version: 1.1.0
---

# Verify — Post-Implementation Adherence Check

## Overview

After implementing a feature, verify that the code actually delivers what was
specified. Compares the implementation against the original requirements and
produces a scored assessment with evidence.

This fills the gap between planning (architect, design-validator) and quality
(code-quality). Those skills ask "is the plan good?" and "is the code clean?"
This skill asks: **"did we build what was asked for?"**

## Iron Law

**NO CLAIMS WITHOUT FRESH EVIDENCE.** If you haven't run the verification
command in this message, you cannot claim it passes. Previous runs, agent
reports, and "should work" are not evidence.

## Invocation

```
/verify                          # Prompt for requirements source
/verify <file>                   # Use a spec/requirements file
/verify <ticket-id>              # Fetch requirements from a ticket description
```

## Entry Gates

Before the workflow can execute, verify:

1. **Requirements exist** — the user must provide requirements from one of:
   - A spec file, plan, or design document
   - A ticket/issue description (fetched via `gh` or pasted)
   - Explicit requirements stated in conversation
   If no requirements source is available, stop: "I need something to verify
   against. Provide a spec file, ticket ID, or describe the requirements."
2. **Implementation exists** — there must be code changes to verify. Run
   the shared scope script to confirm and capture them:
   `bash "<skill-dir>/../../scripts/git-scope.sh" verify`
   (detects the default branch, writes `/tmp/verify-diff.txt` and
   `/tmp/verify-files.txt`). If it reports no changes, stop:
   "No implementation found to verify."
3. **Requirements have testable criteria** — the requirements must contain
   at least one concrete, verifiable criterion. If the requirements are
   too vague (e.g., "make it better"), ask the user to provide specific
   acceptance criteria before proceeding.

## Workflow

### Step 1: Extract Acceptance Criteria

Parse the requirements source and extract every testable criterion as a
numbered list. Present to the user for confirmation:

```
Requirements source: STORY-1234 / spec.md / conversation

Acceptance Criteria extracted:
1. POST /api/users accepts email and password fields
2. Passwords are hashed with bcrypt before storage
3. Duplicate email returns 409 with error message
4. Successful registration returns 201 with user ID
5. Email validation rejects malformed addresses

Is this complete? Add or remove criteria before I verify.
```

Wait for user confirmation. If the user adds or modifies criteria, update
the list before proceeding.

### Step 2: Map Criteria to Code

For each criterion, search the implementation to find the code that
addresses it:

- Use the scope files from the entry gate: `/tmp/verify-files.txt` for the
  changed-file list, `/tmp/verify-diff.txt` for the full diff
- Read each changed file and map logic to criteria
- Use Grep to find relevant patterns, function names, test assertions
- Note criteria with no matching code

### Step 3: Assess Each Criterion

For each criterion, determine PASS or FAIL with evidence:

```
## Acceptance Criteria

1. [PASS] POST /api/users accepts email and password fields
   -> Route defined in src/routes/users.ts:15
   -> Request schema validates both fields in src/schemas/user.ts:8
   -> Test confirms both fields accepted in tests/users.test.ts:23

2. [PASS] Passwords are hashed with bcrypt before storage
   -> bcrypt.hash() called in src/services/user.ts:34
   -> Salt rounds = 12 (line 31)
   -> Test verifies stored password != plain text in tests/users.test.ts:45

3. [FAIL] Duplicate email returns 409 with error message
   -> Unique constraint exists on email column (migration:12)
   -> BUT: no catch for duplicate key error in src/services/user.ts:38
   -> Database error propagates as 500, not 409
   -> FIX: catch unique violation and return 409

4. [PASS] Successful registration returns 201 with user ID
   -> Status 201 returned in src/routes/users.ts:28
   -> Response includes { id: user.id } on line 29

5. [PARTIAL] Email validation rejects malformed addresses
   -> Zod schema validates email format in src/schemas/user.ts:10
   -> BUT: does not reject emails without TLD (e.g., "user@localhost")
   -> Depends on whether RFC-strict validation is required
```

#### Regression Test Verification (for bug fix criteria)

When a criterion relates to fixing a bug, a passing test alone is insufficient.
Verify the test actually catches the bug using the red-green cycle:

1. Run the test → must PASS with the fix in place
2. Revert the fix (`git stash` or comment out the fix)
3. Run the test again → must FAIL (proves the test catches the bug)
4. Restore the fix (`git stash pop` or uncomment)
5. Run the test → must PASS again

If the test passes with the fix reverted, it doesn't actually test the fix.
Mark the criterion as PARTIAL with a note: "Test exists but does not
validate the fix — passes with or without the change."

### Step 4: Score Intent Adherence

Calculate an overall score (0-100) reflecting how well the implementation
matches the stated intent. This is NOT just "criteria passed / total" —
also consider:

- Does the implementation solve the underlying problem?
- Are there deviations from stated intent (scope creep or missed scope)?
- Would someone reading the spec and then the code agree they match?

```
## Intent Adherence: 78/100

The implementation covers the core registration flow correctly.
Hashing, validation, and the happy path work as specified.

Deductions:
- (-15) Criterion 3 (duplicate email handling) is not implemented —
  this is a core requirement, not an edge case
- (-5) Criterion 5 (email validation) is partial — Zod's default
  email validation may be insufficient depending on strictness needs
- (-2) No input length limits on password field — not in the spec
  but a reasonable expectation for a registration endpoint
```

### Step 5: Present Assessment

Combine the criteria checklist and intent score into a single report:

```markdown
## Verification Report

### Intent Adherence: XX/100
[Score justification with specific deductions]

### Criteria Checklist
| # | Status | Criterion | Evidence |
|---|--------|-----------|----------|
| 1 | PASS | [criterion] | [file:line] |
| 2 | FAIL | [criterion] | [what's missing] |
| ... | ... | ... | ... |

### Summary
- Passed: X/Y criteria
- Failed: X/Y criteria
- Partial: X/Y criteria

### Recommended Fixes (for FAIL/PARTIAL)
1. [Criterion #] — [specific fix with file:line]
2. ...
```

### Step 6: Iterate

If any criteria are FAIL or PARTIAL:
- Ask the user: "Want me to fix the failing criteria, or is this acceptable?"
- If the user wants fixes, implement them and return to Step 3 to re-verify
- If the user accepts, note the accepted gaps in the report

## Exit Gates

Before declaring verification complete:

1. **All criteria assessed** — every extracted criterion has a PASS, FAIL,
   or PARTIAL status with evidence
2. **Score justified** — every deduction in the intent score maps to a
   specific criterion or observation
3. **User acknowledged** — the user has seen the report and either approved
   the result or requested fixes

## Guidelines

- **Evidence over opinion** — every PASS needs a file:line reference, every
  FAIL needs proof of absence
- **Don't conflate quality with adherence** — a function can be poorly
  written but still meet the spec (that's code-quality's job). And code
  can be beautiful but miss a requirement
- **PARTIAL is honest** — use it when the implementation addresses a
  criterion but incompletely. Don't force everything into PASS/FAIL
- **Deductions need weight** — a missing core feature costs more than a
  missing edge case. Reflect this in the score
- **Don't add criteria** — verify against what was specified, not what you
  think should have been specified. If you notice missing requirements,
  mention them separately as "observations" outside the checklist
- **Adversarial pass after assessment** — after your initial PASS/FAIL
  assessment (Step 3), apply the models in `references/thinking-models.md`
  to actively seek false PASSes, stub implementations, and confirmation bias

## Red Flags

These thoughts mean you're skipping verification:

| Thought | Reality |
|---------|---------|
| "Tests should pass now" | Run them. "Should" is not evidence. |
| "I'm confident this works" | Confidence ≠ evidence. Run the command. |
| "The linter passed so it's fine" | Linter ≠ tests ≠ build. Verify each claim separately. |
| "The agent said it succeeded" | Agents hallucinate. Check the diff yourself. |
| "I already ran it earlier" | Earlier is stale. Run it fresh. |
| "It's a small change, no need" | Small changes break things too. Verify. |

## Examples

### Example 1: Verify against a spec file
```
User: /verify docs/api-spec.md

Agent: [Reads spec, extracts 8 acceptance criteria]
       [Presents criteria list, user confirms]
       [Maps each criterion to code changes]
       [Produces report: 6 PASS, 1 FAIL, 1 PARTIAL, score 82/100]
       [User asks to fix the FAIL, agent implements, re-verifies -> 95/100]
```

### Example 2: Verify against conversation requirements
```
User: I asked you to add rate limiting to the API. /verify

Agent: [Extracts criteria from earlier conversation:
        1. Rate limit of 100 req/min per IP
        2. Returns 429 with Retry-After header
        3. Configurable via environment variable]
       [Verifies each against the implementation]
       [Report: 3/3 PASS, score 95/100, -5 for missing rate limit logging]
```

## Troubleshooting

Error: No requirements source provided
Cause: User invoked /verify without a spec, ticket, or prior conversation context
Solution: Ask the user to provide requirements — file path, ticket ID, or describe them

Error: Requirements too vague to verify
Cause: Requirements like "improve performance" or "make it work" have no testable criteria
Solution: Ask the user to break requirements into specific, testable acceptance criteria

Error: Implementation spans many files
Cause: Large feature with changes across 20+ files
Solution: Focus on files changed in this branch (`/tmp/verify-files.txt` from the scope script), verify criteria systematically rather than reading every file
