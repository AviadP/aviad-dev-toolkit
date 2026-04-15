# Thinking Models: Debug

Structured reasoning models for debugging. Apply at decision points —
when forming hypotheses, choosing between explanations, or pivoting
after a failed attempt. Not continuously.

Each model counters a specific failure mode documented in the Red Flags
table of the main skill.

## 1. Fault Tree Analysis

**Counters:** Jumping to the first plausible cause without mapping alternatives.

Before forming a hypothesis (Phase 2, step 7), build a fault tree:

1. Start with the observed symptom as the root node
2. Branch into all possible causes at each level (code, config, data,
   environment, dependencies, timing)
3. Use AND/OR gates — some failures require multiple conditions (AND),
   others have independent triggers (OR)
4. Prioritize branches by likelihood AND testability
5. Do NOT prune branches just because they seem unlikely — unlikely
   causes that are easy to test should be tested early

The tree becomes your investigation roadmap. Without it, you test
whatever comes to mind first, which is usually whatever you looked
at most recently — not whatever is most likely.

## 2. Hypothesis-Driven Investigation

**Counters:** Shotgun debugging — making random changes and hoping
something works.

For each hypothesis from the fault tree, follow this strict protocol:

1. **PREDICT** — "If hypothesis H is correct, then test T should
   produce result R"
2. **TEST** — Execute exactly one test, changing one variable
3. **OBSERVE** — Record the actual result (not what you expected)
4. **CONCLUDE** — Matched prediction = SUPPORTED. Failed = ELIMINATED.
   Unexpected result = new evidence, update the fault tree

Never skip the PREDICT step. Without a prediction, you cannot
distinguish a meaningful result from noise.

Never change more than one variable per test. If you change two things
and the bug disappears, you don't know which change fixed it — and
you may have introduced a new bug while masking the original.

## 3. Occam's Razor

**Counters:** Pursuing elaborate multi-component explanations when
simple causes haven't been ruled out.

Before investigating race conditions, framework-level issues, or
complex multi-service interactions, verify the simple explanations:

- Typo in variable/function name
- Wrong file path or import
- Missing or stale dependency
- Incorrect config value or environment variable
- Stale cache or build artifact
- Wrong branch or uncommitted changes

These "boring" causes account for the majority of bugs. Only escalate
to complex hypotheses AFTER the simple ones are eliminated.

**Calibration:** If your current hypothesis requires 3+ things to go
wrong simultaneously, step back and look for a single-point failure.

## 4. Counterfactual Thinking

**Counters:** Confusing correlation ("bug appeared after deploy X")
with causation ("deploy X caused the bug").

When you have a hypothesis about the root cause, construct a
counterfactual:

> "If I change ONLY this one variable/config/line, the bug should
> disappear (or appear)."

Execute the counterfactual test:

- If the bug persists after your targeted change → hypothesis is wrong,
  the cause is elsewhere
- If the bug disappears → you have strong causal evidence

This is more powerful than the timeline correlation ("it broke after
commit abc123") because it tests the *mechanism*, not the timeline.
Commits often contain multiple changes — the counterfactual isolates
which specific change matters.

---

## When NOT to Think

Skip these models when the situation doesn't benefit from them:

- **Stack trace names exact file, line, and cause** — e.g.,
  `TypeError: Cannot read property 'x' of undefined at foo.js:42`.
  Fix it directly. Don't build a fault tree for a null reference
  with a clear stack trace.
- **User told you exactly what's wrong** — skip hypothesis formation,
  go straight to verification and fix.
- **Typo, missing import, wrong path** — Occam's Razor resolves
  it immediately. The models exist for when simple checks fail.
- **Reading error logs** — normal debugging activity, not a decision
  point. Only invoke models when you have multiple plausible
  hypotheses and need to choose which to test first.
- **Reproducing a known fix** — if the root cause is already
  established (from prior investigation or user input), proceed
  to Phase 3 directly.
