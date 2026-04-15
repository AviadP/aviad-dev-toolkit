# Thinking Models: Refactor

Structured reasoning models for Phase 1 (Issue Discovery). Apply when
assigning severity, evaluating whether a finding is real, or deciding
whether an issue belongs in scope. Not continuously.

Each model counters a specific failure mode in code analysis.

## 1. Circle of Concern vs Circle of Control

**Counters:** Scope creep into code the user didn't ask to refactor.

Before reporting an issue, check: is this in the code the user pointed
to (Circle of Control), or in adjacent/calling/imported code (Circle
of Concern)?

- **Control** (user's target code) → report with full detail and
  severity
- **Concern** (adjacent code that interacts with the target) → report
  separately under "Out of Scope Observations" with a note:
  "Found while analyzing [target]. Not in scope but worth noting."

This prevents analysis from ballooning. The user asked to refactor
function X, not the entire module. If function X calls broken function
Y, note it — but don't design a fix for Y unless the user asks.

**Exception:** If the out-of-scope issue is the actual root cause of
an in-scope problem (e.g., the target function is complex because the
helper it calls has a bad API), mention the dependency explicitly and
let the user decide whether to expand scope.

## 2. First Principles

**Counters:** Suggesting design patterns without verifying the code
has the problem the pattern solves.

Before recommending "extract to a factory," "use dependency injection,"
"apply the strategy pattern," or any other pattern-based fix,
decompose:

1. **What problem does this pattern solve?** (e.g., factory solves
   "many similar objects with different creation logic")
2. **Does this code actually have that problem?** Check the usage
   patterns found via grep in Phase 1, step 3
3. **Would the simpler alternative work?** A plain function, a
   dictionary lookup, or an if/else chain is often better than a
   pattern when there are only 2-3 cases

If the code has 2 usage patterns → a pattern is premature.
If the code has 10+ usage patterns with variation → a pattern may help.

The recommendation should come from the code's actual constraints, not
from "this kind of code usually benefits from pattern X."

## 3. Chesterton's Fence

**Counters:** Classifying code as "bad" without understanding why it
was written that way.

Before assigning Critical or High severity to a finding, check:

1. **git blame** — when was this code written and by whom? Was there
   a commit message explaining the choice?
2. **Comments** — is there a `NOTE:`, `HACK:`, `WORKAROUND:`, or
   inline comment explaining why the code looks unusual?
3. **Test files** — is there a test that specifically exercises this
   "bad" code in a way that suggests it's intentional?
4. **Issue tracker references** — does the code reference a ticket
   number that might explain the constraint?

Common cases where "bad" code is intentional:
- Working around a framework bug (with a comment citing the issue)
- Meeting a performance requirement that prevents the "clean" approach
- Backward compatibility with an older API version
- Matching an external system's quirky behavior

If the code has a documented reason → downgrade severity and note:
"Appears intentional — [reason]. Consider revisiting if [constraint]
no longer applies."

If no documented reason exists → keep severity but note: "No documented
rationale found. Verify with the team before changing."

---

## When NOT to Think

Skip these models when the finding is clear-cut:

- **Obvious bugs** — null dereference with no guard, off-by-one in a
  loop boundary, exception swallowed silently with no logging. Report
  directly at appropriate severity.
- **Clear duplication** — identical 20-line blocks in the same file.
  Report directly.
- **YAGNI violations** — grep returns zero usages for a method/class.
  Flag for removal directly, don't reason about whether someone might
  need it someday.
- **Violations of project conventions** — if CLAUDE.md says "use
  specific exceptions" and the code uses `except Exception`, that's
  a factual finding. No reasoning needed.
