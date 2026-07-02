---
name: risk-assess
description: >
  Assess the risk and blast radius of a proposed code change before implementing it.
  Evaluates CI impact, framework-wide vs localized scope, rollback path, and identifies
  blindspots. Use when user says "what's the risk", "is this safe", "assess the impact",
  "risk assess", "blast radius", or before applying framework-wide or CI-affecting changes.
  Do NOT use for code quality review (use code-quality) or plan validation (use design-validator).
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Risk Assess — Change Impact Assessment

## Overview

Evaluate the risk of a proposed change before implementation. Answers three
questions: **"What could break?"**, **"How wide is the blast radius?"**, and
**"What's the rollback path?"**

This fills the gap between planning and quality. `/design-validator` asks
"is the plan good?", `/code-quality` asks "is the code clean?", this skill
asks: **"is it safe to ship this?"**

## Guiding Principle

*"First, do no harm."* — A change that is small in code can be wide in
impact. A one-line fix to a shared utility can affect every test in CI.
This skill forces that analysis before implementation.

## Invocation

```
/risk-assess                      # Assess current plan or recent changes
/risk-assess <file or plan>       # Assess a specific change or plan
/risk-assess --diff               # Assess the current branch diff
```

## Entry Gates

1. **Change exists** — there must be either:
   - A plan described in conversation
   - A diff on the current branch (`git diff main --stat`)
   - A file or document describing the proposed change
   If none exist, ask: "What change should I assess? Describe the plan or
   point me to a diff."
2. **Change is non-trivial** — if the change is a single-line typo fix or
   comment edit, report "Low risk — no impact analysis needed" and stop.

## Workflow

### Step 1: Identify the Change Surface

Determine what is being changed and where it lives:

```bash
git diff main --stat               # Files touched
git diff main --numstat            # Lines added/removed per file
```

If working from a plan (not a diff), list the files and functions that
would be modified.

Classify each changed file:

| Category | Examples | Risk Level |
|----------|----------|------------|
| **Shared utility / framework** | utils.py, helpers.py, base classes, conftest.py | HIGH |
| **Configuration / constants** | constants.py, config.py, settings | HIGH |
| **Test infrastructure** | fixtures, factories, setup/teardown | HIGH |
| **CI / pipeline** | Makefile, tox.ini, .github/, Jenkinsfile | HIGH |
| **Feature code** | specific module, single endpoint | MEDIUM |
| **Single test file** | test_specific_feature.py | LOW |
| **Documentation** | README, docstrings, comments | LOW |

### Step 2: Measure Blast Radius

For each HIGH or MEDIUM risk file, trace its dependents:

1. **Import graph** — who imports this module?
   ```bash
   grep -rn "from <module> import\|import <module>" --include="*.py" .
   ```
2. **Call sites** — who calls the changed function?
   ```bash
   grep -rn "<function_name>" --include="*.py" .
   ```
3. **Test coverage** — which tests exercise this path?
   ```bash
   grep -rn "<function_name>\|<class_name>" tests/ --include="*.py"
   ```
4. **CI configurations** — does this run in CI pipelines?

Count and report:
- Number of files that import the changed module
- Number of direct callers of changed functions
- Number of test files that exercise changed code
- Number of CI jobs that run affected tests

### Step 3: Identify Behavioral Changes

For each modification, classify the behavioral impact:

| Impact Type | Description | Risk |
|-------------|-------------|------|
| **No behavior change** | Refactoring, renaming, reordering | LOW |
| **Additive** | New function, new parameter with default | LOW |
| **Narrowing** | Stricter validation, tighter timeout | MEDIUM |
| **Broadening** | Relaxed validation, wider catch | MEDIUM |
| **Control flow change** | Different branching, new skip/exit | HIGH |
| **Error handling change** | Different exception type, new fallback | HIGH |
| **Side effect change** | Different logging, state mutation, I/O | HIGH |

### Step 4: Find Blindspots

Actively look for things the plan does NOT address:

1. **Teardown / cleanup** — if setup changes, does teardown still match?
2. **Existing consumers** — are there callers that depend on the current
   behavior (including error behavior)?
3. **Timing assumptions** — does anything depend on execution order or
   timing that this change affects?
4. **Environment differences** — will this behave differently in CI vs
   local, or across cluster versions?
5. **Rollback** — if this fails in production/CI, can it be reverted
   cleanly? Are there schema migrations or state changes that prevent
   simple rollback?
6. **Silent failures** — does this change turn an error into a silent
   pass or vice versa?
7. **Edge cases from session history** — has this area caused issues
   before? Check `~/memories/` for prior incidents.

### Step 5: Score and Report

Produce a structured risk report:

```markdown
## Risk Assessment

### Overall Risk: [LOW | MEDIUM | HIGH | CRITICAL]

### Change Summary
- Files: X modified, Y in shared/framework code
- Blast radius: Z files depend on changed modules
- Behavioral impact: [classification from Step 3]

### Blast Radius
| Changed File | Category | Dependents | Risk |
|-------------|----------|------------|------|
| utils.py | Shared utility | 45 importers | HIGH |
| test_foo.py | Single test | 0 | LOW |

### Behavioral Changes
| Change | Before | After | Impact |
|--------|--------|-------|--------|
| timeout | 300s | 60s | Narrowing — may cause false failures |

### Blindspots Identified
1. [Description] — [Why this is a risk]
2. [Description] — [Why this is a risk]

### Rollback Path
- [Can this be cleanly reverted? Yes/No with explanation]
- [Are there state changes that persist? Database, config, etc.]

### Recommendation
[One of:]
- **Proceed** — low risk, localized change, clean rollback
- **Proceed with caution** — medium risk, test thoroughly before merge
- **Stage it** — high risk, deploy incrementally or behind a flag
- **Reconsider** — critical risk, the blast radius is too wide for the
  benefit. Consider an alternative approach.

### Mitigation Steps (if Proceed with caution or Stage it)
1. [Specific action to reduce risk]
2. [Specific action to reduce risk]
```

### Step 6: Present and Discuss

After presenting the report:
- If HIGH/CRITICAL: ask "Want me to explore a lower-risk alternative?"
- If MEDIUM with blindspots: highlight the top blindspot and ask if the
  user wants to address it before proceeding
- If LOW: confirm "Looks safe to proceed. Any concerns?"

## Guidelines

- **Trace, don't guess** — use grep and import analysis, not assumptions
  about how widely a module is used
- **Severity reflects reachability** — a bug in dead code is low risk
  regardless of how scary it looks
- **CI impact matters most** — for test infrastructure projects, the
  primary risk is breaking CI pipelines, not runtime behavior
- **Prior incidents inform risk** — if this area has caused reverts or
  CI failures before, bump the risk level
- **Low-risk alternatives are always worth mentioning** — if the user
  can achieve the same goal with a localized change, say so
- **Don't block unnecessarily** — LOW and MEDIUM risks with clean
  rollback paths should proceed. This skill identifies risk, it doesn't
  gatekeep

## Examples

### Example 1: Framework utility change
```
User: I want to add a health check to verify_storage_cluster()
       /risk-assess

Agent: ## Risk Assessment
       ### Overall Risk: HIGH
       - verify_storage_cluster() is called by 23 test fixtures
       - Adding a check here could skip tests that currently pass
       - Blast radius: all tests using the managed-service fixture
       ### Blindspots
       1. Tests that run during upgrade may see transient unhealthy state
       2. Teardown assumes setup succeeded — if check skips setup, teardown
          may fail on cleanup of resources that were never created
       ### Recommendation: Proceed with caution
       - Add the check with a configurable timeout
       - Run against a representative CI job before merging
```

### Example 2: Localized test fix
```
User: I'm adding a retry to this specific test assertion
       /risk-assess

Agent: ## Risk Assessment
       ### Overall Risk: LOW
       - Change is in a single test file
       - No shared code modified
       - Rollback: simple revert
       Looks safe to proceed. Any concerns?
```

## Troubleshooting

Error: No change to assess
Cause: User invoked without a plan, diff, or file reference
Solution: Ask what change they want assessed

Error: Change surface too large to trace
Cause: Refactor touching 50+ files
Solution: Focus on HIGH-risk files first, report that full trace was not feasible
