# Thinking Models: Bug Hunt

Structured reasoning models for the Validator/Simulator agent. Apply
when a finding is borderline — partially guarded, complex call chain,
or unclear reachability. Not for clear-cut kills or obvious validates.

The 3-Question Kill Gate handles the majority of findings cleanly.
These models are for the 10-20% where judgment is needed.

## 1. Chesterton's Fence

**Counters:** Killing findings about "dead code" that is actually alive.

Before killing a finding as "unreachable" or "dead code," verify that
the code is genuinely dead — not just hard to trace:

1. **grep for the function/method name** — check all files, not just
   the obvious callers. Include config files, test fixtures, and
   dynamic dispatch patterns
2. **Check for framework conventions** — decorators (`@app.route`,
   `@pytest.fixture`, `@celery.task`), magic methods (`__init__`,
   `__call__`), and registration patterns make code callable without
   explicit imports
3. **Check for string-based references** — `getattr()`, dictionary
   lookups keyed by function name, template references, CLI entry
   points in setup.cfg/pyproject.toml
4. **Check git blame** — recently added code is less likely to be dead.
   Code from years ago with no recent callers is more likely dead

Kill only if you can demonstrate the code is unreachable — not just
that you couldn't find callers with a single grep.

## 2. Occam's Razor

**Counters:** Validators constructing elaborate scenarios to justify
keeping weak findings alive.

When evaluating a finding's trigger scenario, check its complexity:

- **1 condition** (e.g., "pass empty string") → likely real, keep
- **2 conditions** (e.g., "pass empty string AND config X is set") →
  plausible, verify both conditions can co-occur
- **3+ conditions** (e.g., "pass empty string AND config X AND race
  with concurrent request AND cache is stale") → probably not real

If a trigger scenario requires 3+ simultaneous conditions, the
simplest explanation is usually that the guards work. Downgrade to
Low confidence rather than keeping at Medium.

**Exception:** Security vulnerabilities. Attackers actively construct
multi-condition scenarios. A 3-condition trigger for an auth bypass
or injection is still worth reporting — mark as Low confidence but
keep the severity.

## 3. Counterfactual Thinking

**Counters:** Accepting "guarded" findings at face value without
verifying the guards actually hold.

For Medium-confidence findings where guards are the reason for
uncertainty, construct a counterfactual:

> "If guard X were removed or changed, would this become triggerable?"

This matters because:
- Guards can be refactored away by someone who doesn't know they're
  load-bearing
- Validation middleware can be bypassed by internal callers
- Type constraints can be loosened in future changes
- Config defaults can be overridden in production

If removing one guard makes the finding Critical → report as
**"guarded but fragile"** at Low confidence with a note: "Currently
blocked by [guard]. Worth monitoring if [guard] changes."

If removing the guard still doesn't make it triggerable (multiple
independent guards exist) → kill it. Defense in depth is working.

---

## When NOT to Think

Skip these models when the decision is clear-cut:

- **Finding clearly fails kill gate Q1** — code is commented out,
  inside an `if False:` block, in a test-only file with no production
  path. Kill immediately, no reasoning needed.
- **Finding clearly passes all 3 gates with High confidence** —
  concrete trigger, no guards, verified behavior. Validate immediately.
- **Style or quality issue** — naming, formatting, "could be cleaner."
  Kill immediately — that's code review, not bug hunting.
- **Finding is identical to another already-validated finding** —
  deduplicate, don't re-reason. Credit both source agents.
