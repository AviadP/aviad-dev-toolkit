---
name: debug
description: >
  Systematic debugging workflow — find root cause before attempting fixes.
  Four-phase investigation: reproduce, gather evidence, form hypothesis,
  implement fix. Use when user says "debug this", "why is this failing",
  "fix this bug", "test is broken", "getting an error", or encounters
  any unexpected behavior. Do NOT use for refactoring working code —
  use refactor for that.
metadata:
  author: Aviad Polak
  version: 1.1.0
---

# Debug — Systematic Root Cause Investigation

## Overview

Find the root cause before attempting a fix. Most debugging time is wasted
on guessing and patching symptoms. This skill enforces investigation first,
fix second.

## Iron Law

**NO FIXES WITHOUT ROOT CAUSE.** You must complete Phase 1 (reproduce and
gather evidence) before proposing any fix. If you catch yourself thinking
"let me just try changing X," stop — you're guessing.

## Entry Gates

1. **Bug exists** — there must be a concrete symptom: error message, test
   failure, unexpected behavior, or crash. If the user says "something
   feels wrong" without specifics, ask for the exact symptom before proceeding.
2. **Code is accessible** — the relevant source code must be readable.
   If the bug is in a third-party dependency, confirm the user wants to
   investigate (vs. filing an issue upstream).

## Workflow

### Phase 1: Reproduce and Gather Evidence

1. **Read the error carefully**
   - Read the full error message and traceback, not just the last line
   - Identify the exception type, the file:line where it originates,
     and the call chain that led there

2. **Read the code**
   - Read the function where the error occurs
   - Read the calling code to understand how it got there
   - Understand what the code is *supposed* to do before analyzing
     why it doesn't

3. **Reproduce consistently**
   - Run the failing test or operation to confirm the failure
   - Note: does it fail every time or intermittently?
   - If intermittent, identify what varies between runs (timing,
     data, environment, concurrency)

4. **Check recent changes**
   - `git log --oneline -20` — did something change recently?
   - `git status --short && git diff` — are there uncommitted changes that could cause this?
   - If the code worked before, `git bisect` to find the breaking commit

5. **Gather evidence at boundaries**
   - For layered systems, add logging or inspect data at each component
     boundary: what enters and exits each layer?
   - This reveals WHERE the data goes wrong, narrowing the search space
   - Example: if API returns wrong data, check: handler input → service
     input → DB query → DB result → service output → handler output

6. **Find a working example**
   - Search the codebase for similar code that works correctly
   - Compare: what's different between the working case and the failing case?
   - The difference is often the root cause

### Phase 2: Form and Test Hypothesis

7. **Form a single hypothesis**
   - Based on the evidence, state one specific hypothesis:
     "The bug is caused by [X] because [evidence Y]"
   - A good hypothesis explains ALL the symptoms, not just some
   - A good hypothesis predicts the failure rate: if your hypothesis
     says it should fail 100% of the time but it's intermittent,
     your hypothesis is wrong

8. **Test the hypothesis minimally**
   - Change ONE variable to test your hypothesis
   - If the hypothesis is correct, the change should fix the symptom
   - If it doesn't fix it, the hypothesis is wrong — go back to step 5,
     don't stack another guess on top

9. **Architectural catch**
   - If 3+ hypotheses have failed, STOP
   - The problem is likely architectural, not a surface-level bug
   - Present to the user: "Three fix attempts have failed. The evidence
     suggests [X] might be an architectural issue rather than a simple
     bug. Should we reconsider the approach?"

**STOP and present hypothesis with evidence to the user before proceeding
to Phase 3.**

### Phase 3: Implement Fix

10. **Write a failing test first**
    - Create a test that reproduces the bug
    - Run it — it must FAIL (proves the test catches the bug)
    - If you can't write a test that fails, you haven't found the root cause

11. **Implement the minimal fix**
    - Change the least amount of code that fixes the root cause
    - Do not refactor surrounding code — stay focused on the bug

12. **Verify the fix**
    - Run the failing test — must PASS now
    - Revert the fix temporarily — test must FAIL again (red-green cycle)
    - Restore the fix — test must PASS again
    - Run the broader test suite to check for regressions

## Exit Gates

Before declaring the bug fixed:

1. **Root cause identified** — you can explain WHY the bug happened in
   one sentence
2. **Fix is minimal** — the change addresses the root cause, not symptoms
3. **Test proves it** — a test exists that fails without the fix and
   passes with it
4. **No regressions** — broader test suite still passes

## Red Flags

These thoughts mean you're skipping investigation:

| Thought | Reality |
|---------|---------|
| "Let me just try changing X" | That's guessing. Investigate first. |
| "I think I know what it is" | Thinking ≠ knowing. Read the code and verify. |
| "It's probably a timing issue" | What specifically is slow and why? "Timing" is not a root cause. |
| "Let me add a retry/sleep" | Retries mask bugs. Find why it fails. |
| "The error message says X so the fix is Y" | Error messages describe symptoms, not causes. |
| "One more attempt" (after 2 failures) | Stop. Revisit your assumptions. |
| "Let me increase the timeout" | Why is the operation slow? That's the real question. |
| "Works on my machine" | What's different? Environment IS evidence. |

## Guidelines

- **Investigate unexplained specifics** — when evidence doesn't fully explain
  the failure, don't paper over it with vague justifications. The unexplained
  detail is often where the real root cause hides.
- **Start from the tail** — for large log files, read the last section first
  to find the error, then work backwards for context.
- **Evidence over intuition** — cite file:line for every claim about what
  the code does. "I think this function does X" is not evidence.
- **One variable at a time** — when testing hypotheses, change only one thing.
  Multiple changes at once make it impossible to know what worked.
- **Don't confuse mechanism with cause** — "a TimeoutError was raised" is the
  mechanism. "The database connection pool was exhausted because connections
  weren't being returned" is the cause.
- **Structured reasoning at decision points** — when forming hypotheses,
  choosing between explanations, or pivoting after a failed attempt,
  consult `references/thinking-models.md` for reasoning protocols.

## Examples

### Example 1: Test failure with clear traceback

```
User: test_bucket_versioning is failing with NoSuchElementException

Agent: [Phase 1: Reads the error, reads the test code, reads the page object]
       [Finds: test clicks "enable versioning" but the button locator
        targets the old PatternFly 4 class, not PF5]
       [Evidence: grep shows button class changed in latest ODF version]
       [Hypothesis: locator is version-specific, needs [class*=] pattern]
       [Presents hypothesis with evidence]
       [User approves]
       [Phase 3: Writes test, fixes locator, verifies red-green cycle]
```

### Example 2: Intermittent failure

```
User: test_node_maintenance passes locally but fails in Jenkins sometimes

Agent: [Phase 1: Reads test code — calls drain_nodes()]
       [Reads drain_nodes() — has a timeout, no PDB check]
       [Hypothesis 1: PDB blocks eviction on single-replica pods]
       [Tests: checks if failure correlates with single-replica clusters]
       [Evidence confirms: fails only on clusters with 1 replica per zone]
       [Root cause: test doesn't account for PDB constraints]
       [Presents to user with evidence]
```
