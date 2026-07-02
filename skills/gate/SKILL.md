---
name: gate
description: >
  Pre-ship quality gate — validates scope, runs quality checks, verifies environment
  readiness, and produces a go/no-go report before committing or shipping. Combines
  scope validation, code quality, and environment checks into a single pass.
  Use when user says "run gate", "is this ready", "pre-ship check", "quality gate",
  "check before commit", "check before push", "am I ready to ship", or before
  running /ship-it. Do NOT use for in-progress work — this is a final checkpoint.
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Gate — Pre-Ship Quality Gate

## Overview

Single-command quality gate that answers: **"Is this ready to ship?"**

Runs three checks in sequence:
1. **Environment** — venv active, git state clean, no secrets
2. **Scope** — are the changed files aligned with the task?
3. **Quality** — code quality and bug hunting on changed files only

Produces a go/no-go report. If all gates pass, the user can ship with
confidence. If any gate fails, the report shows exactly what to fix.

## Invocation

```
/gate                             # Full gate: environment + scope + quality
/gate --scope-only                # Only run scope validation (fast)
/gate --no-quality                # Skip quality agents (faster)
/gate <issue-url-or-description>  # Validate scope against a specific task
```

## Step 1: Preflight — Environment Check

Run the preflight script:

```bash
bash "<skill-dir>/scripts/preflight.sh"
```

This checks:
- Current branch and base branch
- Changes exist (vs base branch)
- Virtual environment is active
- No secrets in changed files
- Diff size summary

**If no changes exist**, stop: "Nothing to gate — no changes found."

**If venv is not active**, report as WARNING (not a blocker) with the
activation hint from preflight output.

**If secrets detected**, report as BLOCKER — list the files and stop.

Present the preflight summary before proceeding:

```
## Preflight
- Branch: feature-x (base: main)
- Venv: active (.venv)
- Changes: 4 files, +120 -45
- Secrets: none detected
```

## Step 2: Scope Validation

Compare the files changed on this branch against the stated task scope.

### Determine Expected Scope

The scope comes from one of (in priority order):
1. **Explicit argument** — user passed an issue URL or description
2. **Conversation context** — the task discussed in this session
3. **Branch name** — infer from branch name (e.g., `fix-retry-logic`
   suggests retry-related files)
4. **Commit messages** — `git log main..HEAD --oneline` to infer intent

If scope cannot be determined, ask: "What's this change supposed to do?
I need to know the intent to validate scope."

### Check Scope

For each changed file from preflight output:

1. **In scope** — directly related to the task
2. **Supporting** — necessary infrastructure change (e.g., constants,
   imports) to support an in-scope change
3. **Out of scope** — unrelated to the task

Report:

```
## Scope Check
| File | Status | Reason |
|------|--------|--------|
| test_replica1.py | In scope | Primary test file for the task |
| external_cluster_helpers.py | In scope | Helper methods for the test |
| constants.py | Supporting | New constants used by the test |
| utils.py | OUT OF SCOPE | Unrelated utility change |

Scope verdict: 1 file out of scope
```

**If OUT OF SCOPE files exist:**
- Report them prominently
- Ask: "These files seem outside the task scope. Were they intentional?
  If not, consider reverting them before shipping."

**If `--scope-only` was used**, stop here with the scope report.

## Step 3: Quality Check

**Skip if `--no-quality` was used.**

Run two quality agents in parallel on **changed files only** (not the
entire codebase). Scope to files from the preflight report.

### Launch Agents

Use the Agent tool to launch these two agents **in parallel** with
`run_in_background: true`:

#### Agent 1: Code Review
```
Analyze the code changes on branch `<branch>` compared to `<base>`.
Focus on: bugs, logic errors, security issues, missing error handling.
Scope to ONLY these files: [list from preflight]
Run `git diff <base>` to see the diff.
Classify findings as: Critical, Major, Minor, Nit.
```

#### Agent 2: Bug Hunter
```
Hunt for real, triggerable bugs in the changes on branch `<branch>`
compared to `<base>`. NOT style issues — only bugs that could cause
failures, data corruption, or silent wrong behavior.
Scope to ONLY these files: [list from preflight]
Run `git diff <base>` to see the diff.
For each bug, explain: what triggers it, what happens, how to fix it.
```

### Collect and Consolidate

Wait for both agents. Deduplicate findings. Present:

```
## Quality Check

### Blockers (must fix before ship)
| # | File:Line | Issue | Source |
|---|-----------|-------|--------|
| 1 | helpers.py:45 | Broad except Exception hides failures | Review, BugHunt |

### Warnings (should fix, not blocking)
| # | File:Line | Issue | Source |
|---|-----------|-------|--------|
| 2 | test_foo.py:92 | Missing cleanup in teardown | Review |

### Clean
- No critical issues found by [agent name]
```

## Step 4: Gate Verdict

Combine all three checks into a final verdict:

```
## Gate Verdict: [PASS | WARN | FAIL]

| Check | Status | Details |
|-------|--------|---------|
| Environment | PASS | Venv active, no secrets |
| Scope | PASS | All 4 files in scope |
| Quality | WARN | 0 blockers, 2 warnings |

[One of:]
- PASS — All clear. Ready to ship.
- WARN — No blockers, but warnings exist. Ship at your discretion.
- FAIL — Blockers found. Fix before shipping:
  1. [blocker description]
  2. [blocker description]
```

### Verdict Rules

- **FAIL** if: secrets detected, OR any Critical/blocker quality finding
- **WARN** if: venv not active, OR out-of-scope files exist, OR
  Major quality findings exist
- **PASS** if: none of the above

## Step 5: Next Steps

Based on verdict:

- **PASS**: "All gates passed. Run `/ship-it` when ready."
- **WARN**: "Warnings found — review them above. Ship if acceptable,
  or fix first. Your call."
- **FAIL**: "Blockers found. Want me to fix them?"
  If user says yes, fix the blockers and re-run the gate.

## Guidelines

- **Speed over thoroughness** — this is a checkpoint, not a deep audit.
  Use 2 focused agents, not 5. The user already ran quality checks during
  development; this is the final sanity check.
- **Scope is king** — the scope check is the most valuable part. Scope
  creep causes reverts. Flag it early.
- **Don't block on style** — Nit-level findings should never cause a
  FAIL verdict. Only Critical findings block.
- **Venv is a warning, not a blocker** — the user knows about it, just
  remind them. Pre-commit hooks will catch most issues anyway.
- **Be fast** — target under 60 seconds for the full gate. The preflight
  script handles the heavy lifting upfront.

## Examples

### Example 1: Clean pass
```
User: /gate

Agent: [Runs preflight — 3 files changed, venv active, no secrets]
       [Scope check — all files match the current task]
       [Quality — 0 blockers, 1 nit]

       ## Gate Verdict: PASS
       All gates passed. Ready to ship.
```

### Example 2: Scope creep detected
```
User: /gate https://github.com/org/repo/issues/123

Agent: [Runs preflight — 5 files changed]
       [Scope check — 4 in scope, 1 OUT OF SCOPE (utils.py)]

       ## Scope Check
       utils.py is OUT OF SCOPE — contains a refactoring change
       unrelated to issue #123.

       ## Gate Verdict: WARN
       Consider reverting utils.py changes or splitting into a
       separate PR. Ship with these changes? Your call.
```

### Example 3: Blocker found
```
User: /gate

Agent: [Runs preflight — venv NOT active]
       [Scope — OK]
       [Quality — 1 Critical: broad except Exception]

       ## Gate Verdict: FAIL
       1. BLOCKER: helpers.py:45 — except Exception hides failures.
          Use specific exception instead.
       2. WARNING: venv not active — run 'activate' before committing.

       Want me to fix the blocker?
```

## Troubleshooting

Error: Preflight script fails
Cause: Not in a git repository or no base branch found
Solution: Ensure you're in a git repo with a main/master branch

Error: Cannot determine scope
Cause: No issue URL, branch name is generic, no conversation context
Solution: Ask the user what the change is supposed to do

Error: Quality agent fails
Cause: Model error or timeout
Solution: Report which agent failed, present results from the other
