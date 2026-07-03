---
name: review-pr
description: >
  Review a GitHub pull request for bugs, design issues, error handling problems,
  and security vulnerabilities. Validates PR purpose (title, description, issue
  linkage) before code review. Supports two modes: quick (single-pass, no agents)
  for simple PRs and deep (parallel hunters + kill-gate validation with simulation)
  for complex PRs. Clones PR to /tmp for isolated review. Use when user says
  "review PR", "review pull request", "check this PR", "code review", or provides
  a PR URL/number. Do NOT use for reviewing local unstaged changes (use
  code-quality for that).
metadata:
  author: Aviad Polak
  version: 1.2.0
---

# PR Review

Review a GitHub pull request with adaptive depth — quick for simple PRs, deep for complex ones.

## Phase 1: Setup

### 1.1 Parse Input

Extract the PR identifier from the user's argument:
- If a GitHub URL (e.g., `https://github.com/owner/repo/pull/1234`): parse the owner/repo and PR number
- If a number (e.g., `1234`): use the current directory's repo context
- If no argument provided: ask the user for the PR URL or number

### 1.2 Run Setup Script

Run the setup script at `scripts/setup.sh` (relative to this skill) with the PR identifier from step 1.1:

```bash
bash "<skill-dir>/scripts/setup.sh" "<PR_INPUT>"
```

The script handles: cloning the repo, checking out the PR branch, computing the diff, loading project-specific context (review rules, CLAUDE.md), and running purpose validation checks. All results are written to `/tmp/pr-review-context.md`.

### 1.3 Read Context and Display Summary

Read `/tmp/pr-review-context.md` and display the PR Metadata section to the user.

Check the **Purpose Validation** section. If the severity is not PASS, include the finding in the final report under its severity tier with source: **Purpose Validation**. Always continue to code review regardless of purpose findings.

**Purpose validation severity reference:**

| Condition | Severity |
|-----------|----------|
| No meaningful title AND no description AND no issue link | 🔴 BLOCKER |
| Vague title AND no description | 🟠 HIGH |
| Title is OK but no description | 🟡 MEDIUM |
| Everything clear | ✅ Pass (no finding) |

## Phase 2: Mode Selection

If the user already specified a depth in their request ("quick review",
"deep review", `--quick`, `--deep`), use it without asking.

Otherwise read the **Recommended Mode** section from
`/tmp/pr-review-context.md` and ask via AskUserQuestion, putting the
recommended option first with "(Recommended)" in its label:

- **Quick** — Single-pass review, no sub-agents. Best for: small fixes, docs changes, simple refactors, config updates.
- **Deep** — Parallel hunter agents + kill-gate validation. Best for: new features, security-sensitive changes, complex refactors, fundamental architecture changes.

## Phase 3a: Quick Mode

The skill itself performs the review — no agents spawned.

### Review Process

1. Read the full diff (`/tmp/pr-review-diff.txt`)
2. Read the PR description (from metadata gathered in Phase 1)
3. If `review-rules.md` was loaded, check every rule against the diff — any violation is 🔴 BLOCKER severity with source "Rules Violation"
4. Review the diff in priority order:

**Priority 1 — Bugs & Logic Errors:**
- Wrong conditions, inverted booleans, off-by-one errors
- Missing null/undefined/None checks, unsafe access on optional values
- Race conditions, shared mutable state, async ordering issues
- Wrong operators, incorrect precedence
- Missing return values, unreachable code after return
- Type mismatches, lossy conversions

**Priority 2 — Design & Patterns:**
- CLAUDE.md rule violations (if loaded)
- Pattern inconsistency with the rest of the codebase
- Coupling problems, circular dependencies
- Naming that misleads about purpose
- Mixed return types, unclear interfaces
- Functions/classes doing too many things

**Priority 3 — Error Handling:**
- Empty catch blocks, catch-and-continue without logging
- Generic exceptions (`except Exception`, bare `except:`)
- Error messages missing context (what was expected, what was found)
- Swallowed errors hiding real failures behind defaults
- Missing `from e` in exception chaining

**Priority 4 — Security:**
- New endpoints or routes missing auth middleware
- User input rendered without sanitization, dynamic query construction with string interpolation
- Hardcoded secrets, API keys, or credentials in source code
- User-controlled URLs passed to server-side HTTP clients without validation
- Auth tokens stored insecurely, missing CSRF protection on state-changing endpoints
- New dependencies with known CVEs or unpinned versions

5. **For each potential finding**, read the actual source file in `$WORK_DIR` (not just the diff) to understand the full context before reporting.

### Scope Gates

Apply these gates to every potential finding before including it:

- **Scope gate:** Is this code added or modified by this PR? If it's pre-existing code, do NOT flag it.
- **Pattern gate:** Does the project already use this pattern elsewhere? If so, don't flag it — the PR is being consistent.
- **Intent gate:** Does the PR description or code docstrings explain why this design choice was made? If so, respect the author's intent unless it introduces a real bug.

After the review, jump to Phase 4 (Report).

## Phase 3b: Deep Mode

### Step 1: Build Shared Context

Assemble a context block that all hunter agents will receive:

```
PR #<number>: "<title>"
Repository: <owner/repo>
Base branch: <DEFAULT_BRANCH>
Description: <PR body — truncate to 500 chars if longer>
Review Rules: <contents of review-rules.md if loaded, otherwise "None">
Project Conventions: <key sections from CLAUDE.md if loaded, otherwise "None">
Working Directory: <WORK_DIR>
Diff file: /tmp/pr-review-diff.txt
Changed files: <list from --stat>
Dependency check script: <absolute path of <skill-dir>/../../scripts/check-deps.sh>
```

### Step 2: Launch Hunter Agents

Read the agent prompts from `references/` directory (relative to this skill):
- `references/bug-hunter.md`
- `references/design-reviewer.md`
- `references/error-checker.md`
- `references/security-checker.md`

For each prompt, replace `{CONTEXT}` with the shared context block from Step 1.

Launch ALL FOUR agents in a SINGLE message using the Agent tool with `run_in_background: true`. This ensures parallel execution:

```
Agent 1: Bug Hunter        → run_in_background: true
Agent 2: Design Reviewer   → run_in_background: true
Agent 3: Error Checker     → run_in_background: true
Agent 4: Security Checker  → run_in_background: true
```

### Step 3: Collect Results

Wait for all four agents to complete. Collect their findings into a combined list.

If an agent produced no findings, note "No issues found by <agent name>."
If an agent failed, note the failure and continue with results from the others.

### Step 4: Kill-Gate Validation

Read `references/kill-gate.md` and fill its placeholders:
- `{FINDINGS}` — all findings from Step 3 (combined, labeled by source agent)
- `{WORK_DIR}` — the working directory
- `{THINKING_MODELS}` — absolute path of `<skill-dir>/../../shared/thinking-models.md`
  (used for borderline kill/keep decisions)

Launch the validator agent with the filled prompt.

**IMPORTANT:** Findings that are "Rules Violation" (from `review-rules.md`) bypass the kill-gate entirely. They are always reported as BLOCKER.

The validator produces three lists:
1. **Validated findings** — survived all 3 questions, with confidence scores (High/Medium/Low)
2. **New findings** — discovered during independent simulation
3. **Killed findings** — failed at least one question, with kill reason

### Step 5: Deduplicate

If multiple agents flagged the same issue (same file, same or adjacent lines, same category):
- Report it once
- Credit all agents that found it (this increases confidence)
- Use the highest severity rating among the agents
- Use the most concrete trigger scenario

After deduplication, jump to Phase 4 (Report).

## Phase 4: Report

Format the output identically for both quick and deep modes.

```
# PR Review: #<number> — "<title>"
**Mode:** Quick / Deep | **Files:** <N> changed | **Lines:** +<added>, -<deleted>

---

## 🔴 BLOCKER (<count>)

### 1. <Finding title>
**File:** `path/to/file.py:42`
**Issue:** <clear description>
**Trigger:** <concrete scenario — who does what, with what input>
**Suggested fix:**
<code block with fix>
**Source:** <Bug Hunter / Design Reviewer / Error Checker / Security Checker / Purpose Validation / Rules Violation>

---

## 🟠 HIGH (<count>)
<same format per finding>

## 🟡 MEDIUM (<count>)
<same format per finding>

## 🔵 LOW / NITS (<count>)
<same format per finding>

## ✅ What's Done Well
- <positive observation 1>
- <positive observation 2>

## Verdict
<one-line summary>
```

If a severity tier has zero findings, omit that section entirely.

**Deep mode only** — append after the verdict:

```
---
<details>
<summary>Kill-Gate: <X> findings killed</summary>

| # | Finding | Kill Reason |
|---|---------|-------------|
| 1 | <finding> | Unreachable: dead code path |
| 2 | <finding> | Guarded: input validated at API boundary |

</details>
```

## Phase 5: Cleanup

After presenting the report, clean up the temporary workspace:

```bash
bash "<skill-dir>/scripts/setup.sh" --cleanup
```
