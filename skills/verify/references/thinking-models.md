# Thinking Models: Verify

Structured reasoning models for post-implementation verification.
Apply after the initial criteria assessment (Step 3) as an adversarial
pass — actively seeking what you might have missed. Not continuously.

Each model counters a specific failure mode in the verification process.

## 1. Inversion

**Counters:** Checking what IS correct instead of seeking what could
be WRONG.

After completing your initial PASS/FAIL assessment of all criteria,
flip the perspective. List 3 specific ways this implementation could
be WRONG despite your assessment:

- A criterion marked PASS that might be a stub or shallow implementation
- A code path that handles the happy case but silently drops errors
- A test that passes but doesn't actually exercise the stated behavior
- Data that flows through the system but is never validated or persisted

For each, write a concrete check:
- Grep for a specific pattern (empty returns, no-op handlers)
- Test with a specific input (boundary value, empty string, null)
- Trace data from entry point to storage — does it actually arrive?

If the check reveals a problem, downgrade the criterion from PASS to
PARTIAL or FAIL.

**Stub detection patterns to watch for:**
- `return []` or `return {}` with no upstream query
- `return <div>Component</div>` (React placeholder)
- `onClick={() => {}}` (no-op handler)
- `fetch('/api/...')` with no await, no assignment, no error handling
- `useState([])` that never gets populated from an API or data source
- `// TODO` or `// FIXME` inside a function marked as implemented
- Query result assigned but never returned or used

## 2. Confirmation Bias Counter

**Counters:** Being primed by the implementation to see success.
When you read the code and it looks like it handles a criterion,
you're inclined to mark PASS without probing deeper.

After your initial assessment AND after running Inversion, do a
structured disconfirmation pass. Find exactly one of each:

1. **One partially-met criterion** — a criterion you marked PASS where
   the implementation covers the common case but misses an edge case
   stated or implied by the requirement
2. **One misleading test** — a test that passes but doesn't actually
   validate the behavior it claims to test (e.g., asserts on the wrong
   value, mocks away the logic under test, tests setup not behavior)
3. **One uncovered error path** — an error condition with no test
   coverage (e.g., what happens when the external API returns 500?
   when the DB connection drops? when input is malformed?)

Report these findings even if the overall score remains high. They
are observations, not automatic downgrades — but they give the user
visibility into verification depth.

## 3. Chesterton's Fence

**Counters:** Marking intentional deviations as failures.

Before downgrading a criterion to FAIL because the implementation
differs from the spec, check whether the deviation was intentional:

1. Check git blame — was there a commit message explaining the choice?
2. Check code comments — is there a "NOTE:" or "DECISION:" explaining
   why it diverges?
3. Check the conversation history — did the user approve a different
   approach during implementation?
4. Check if the spec itself is ambiguous — does it allow multiple
   valid interpretations?

If the deviation was intentional and documented, mark as PASS with
a note: "Implemented differently than spec — [reason]. Meets intent."

If the deviation is undocumented, mark as PARTIAL and ask the user:
"The implementation does X instead of Y. Was this intentional?"

---

## When NOT to Think

Skip these models when the situation doesn't benefit from them:

- **Binary existence checks** — if a criterion is "file X exists" and
  the file clearly exists with substantive content, don't run Inversion
  on it. Reserve models for behavioral and wiring criteria.
- **Clear test results** — if a test suite exits 0 with all tests
  passing and the tests clearly exercise the stated behavior, accept
  the result. Only invoke models when test results are ambiguous or
  when you suspect tests don't test what they claim.
- **Re-verifying after fixes** — if the user fixed a FAIL criterion
  and you're re-checking, a targeted check is sufficient. Don't run
  the full adversarial pass again on criteria that previously passed.
- **Small, focused changes** — if the implementation is a 10-line bug
  fix with one criterion, the full Confirmation Bias Counter pass
  (find one partial, one misleading test, one uncovered path) is
  overkill. Apply proportionally to scope.
