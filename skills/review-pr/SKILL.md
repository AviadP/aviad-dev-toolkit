---
name: review-pr
description: >
  Review a GitHub pull request for bugs, design issues, and error handling
  problems. Supports two modes: quick (single-pass, no agents) for simple PRs
  and deep (parallel hunters + kill-gate validation) for complex PRs. Clones
  PR to /tmp for isolated review. Use when user says "review PR", "review
  pull request", "check this PR", "code review", or provides a PR URL/number.
  Do NOT use for reviewing local unstaged changes (use code-quality for that)
  or for security-focused review (use secure-code-reviewer for that).
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# PR Review

Review a GitHub pull request with adaptive depth — quick for simple PRs, deep for complex ones.

## Phase 1: Setup

### 1.1 Parse Input

Extract the PR identifier from the user's argument:
- If a GitHub URL (e.g., `https://github.com/owner/repo/pull/1234`): parse the owner/repo and PR number
- If a number (e.g., `1234`): use the current directory's repo context
- If no argument provided: ask the user for the PR URL or number

### 1.2 Clone and Gather Context

Run these commands to set up an isolated review workspace:

```bash
# Resolve repo info from the PR
REPO=$(gh pr view <PR_NUMBER> --json headRepository --jq '.headRepository.owner.login + "/" + .headRepository.name')
DEFAULT_BRANCH=$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)

# Fetch PR metadata
gh pr view <PR_NUMBER> --repo "$REPO" --json title,body,labels,files,additions,deletions,changedFiles

# Clone to isolated workspace
WORK_DIR="/tmp/pr-review-${REPO##*/}-<PR_NUMBER>"
git clone --depth=100 "https://github.com/${REPO}.git" "$WORK_DIR" 2>/dev/null
cd "$WORK_DIR"
gh pr checkout <PR_NUMBER> --repo "$REPO"

# Compute diff against base branch
git diff "${DEFAULT_BRANCH}...HEAD" > /tmp/pr-review-diff.txt
git diff "${DEFAULT_BRANCH}...HEAD" --stat > /tmp/pr-review-stat.txt
```

### 1.3 Load Project-Specific Context

Check if the cloned repo has review customization files. Load them if they exist:

1. **Review rules** — check `$WORK_DIR/.claude/review-rules.md` then `$WORK_DIR/review-rules.md`. If found, read it. These rules define BLOCKER-level violations specific to this project.
2. **Project conventions** — check `$WORK_DIR/.claude/CLAUDE.md`. If found, read it to understand project-specific coding conventions, patterns, and standards.
3. If neither exists, proceed without them — the skill works with defaults.

### 1.4 Display PR Summary

Show the user a brief summary before proceeding:

```
PR #<number>: "<title>"
Repository: <owner/repo>
Files: <N> changed (+<additions>, -<deletions>)
Labels: <labels>
Review rules: <loaded / not found>
Project conventions: <loaded / not found>
```

If the PR has >1000 lines changed, note: "Large PR — deep mode will use significant tokens."

## Phase 2: Mode Selection

Ask the user which review depth to use (via AskUserQuestion):

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

5. **For each potential finding**, read the actual source file in `$WORK_DIR` (not just the diff) to understand the full context before reporting.

### Scope Gates

Apply these gates to every potential finding before including it:

- **Scope gate:** Is this code added or modified by this PR? If it's pre-existing code, do NOT flag it.
- **Pattern gate:** Does the project already use this pattern elsewhere? If so, don't flag it — the PR is being consistent.
- **Intent gate:** Does the PR description or code docstrings explain why this design choice was made? If so, respect the author's intent unless it introduces a real bug.

After the review, jump to Phase 5 (Report).

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
```

### Step 2: Launch Hunter Agents

Read the agent prompts from `references/` directory (relative to this skill):
- `references/bug-hunter.md`
- `references/design-reviewer.md`
- `references/error-checker.md`

For each prompt, replace `{CONTEXT}` with the shared context block from Step 1.

Launch ALL THREE agents in a SINGLE message using the Agent tool with `run_in_background: true`. This ensures parallel execution:

```
Agent 1: Bug Hunter       → run_in_background: true
Agent 2: Design Reviewer  → run_in_background: true
Agent 3: Error Checker    → run_in_background: true
```

### Step 3: Collect Results

Wait for all three agents to complete. Collect their findings into a combined list.

If an agent produced no findings, note "No issues found by <agent name>."
If an agent failed, note the failure and continue with results from the others.

### Step 4: Kill-Gate Validation

Read `references/kill-gate.md`. Launch a validator agent with:
- All findings from Step 3 (combined, labeled by source agent)
- Working directory: `$WORK_DIR`
- Diff file: `/tmp/pr-review-diff.txt`
- For borderline decisions: instruct the validator to read `references/thinking-models.md`

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

After deduplication, jump to Phase 5 (Report).

## Phase 5: Report

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
**Source:** <Bug Hunter / Design Reviewer / Error Checker / Rules Violation>

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

## Phase 6: Cleanup

After presenting the report, clean up the temporary workspace:

```bash
rm -rf "$WORK_DIR"
rm -f /tmp/pr-review-diff.txt /tmp/pr-review-stat.txt
```
