---
name: code-quality
description: >
  Run parallel code quality agents (code review, simplifier & structure,
  dead code & dev artifacts) on branch changes. Use when user says "check code quality",
  "review my changes", "run quality check", "is my code ready", or when finishing a
  feature, before committing, or before creating a PR. Do NOT use for reviewing
  a single file in isolation or for existing code that hasn't changed.
metadata:
  author: Aviad Polak
  version: 1.1.0
---

# Code Quality — Parallel Multi-Agent Review

## Overview

Reviews current branch changes (vs the default branch) through 3 specialized
agents running **in parallel**, then presents a single consolidated report
with prioritized, deduplicated findings. Small diffs skip the agents and get
a cheaper single-pass review.

## Invocation

```
/code-quality              # Review all branch + working-tree changes vs default branch
/code-quality <files>      # Focus on specific files
/code-quality --deep       # Force agents even for a small diff
```

## Agents

Each agent's task prompt extends its base focus with an absorbed area, so 3
agents cover what 5 did before:

| Agent | Type | Focus (base + absorbed) |
|-------|------|-------------------------|
| Code Reviewer | `pr-review-toolkit:code-reviewer` | Bugs, logic errors, security, CLAUDE.md/convention compliance |
| Simplifier & Structure | `branch-code-simplifier` | Complexity, duplication, over-engineering + coupling/cohesion, naming, error-handling patterns |
| Cruft Detector | `dead-code-detector` | Unused functions/imports/constants + dev artifacts: debug logs, TODO leftovers, commented-out code |

(`code-best-practices-reviewer` is folded into Simplifier & Structure and
`code-cleanup-post-dev` into Cruft Detector; both remain available as
standalone agents.)

## Severity Levels

Use these 4 levels when classifying findings. All agents and the consolidation
step must use the same definitions.

| Severity | Definition | Action |
|----------|-----------|--------|
| **Critical** | Security vulnerability, data loss risk, crash, race condition, broken functionality | Must fix before merge |
| **Major** | Logic error, missing validation, performance issue (N+1, unbounded), missing tests for new behavior | Should fix before merge |
| **Minor** | Style inconsistency, suboptimal but correct code, redundancy, missing docs | Fix in this PR or follow-up |
| **Nit** | Naming suggestion, alternative approach equally valid, formatting preference | Optional, author's discretion |

## Instructions

### Step 1: Identify scope

Run the shared scope script:

```bash
bash "<skill-dir>/../../scripts/git-scope.sh" code-quality
```

It detects the default branch (origin/HEAD → main → master), writes the full
diff (untracked files included as new-file diffs) to
`/tmp/code-quality-diff.txt` and the file list to
`/tmp/code-quality-files.txt`, and recommends a mode by diff size.
If the user provided specific files, scope the review to those.
If there are no changes, inform the user and stop.

### Step 2: Pick depth

- Script recommends quick (< 200 changed lines) and the user did not pass
  `--deep` → **single-pass review**: read the diff yourself, review it against
  all three focus areas from the Agents table using the severity definitions,
  then jump to Step 4. Tell the user agents were skipped (re-run with
  `--deep` to force them).
- Otherwise → launch agents (Step 3).

### Step 3: Launch all 3 agents in parallel

Use the Agent tool to launch **all 3 agents simultaneously in a single
message** with `run_in_background: true`. Each agent gets a prompt like:

```
Analyze the code changes on branch `<branch>` compared to `<default branch>`.
[Agent-specific focus, including the absorbed areas from the Agents table.]
The full diff is at /tmp/code-quality-diff.txt (untracked files appear as
new-file diffs). Changed files:
<contents of /tmp/code-quality-files.txt>
Read source files for surrounding context as needed — do NOT re-run git diff.
Classify each finding as: Critical, Major, Minor, or Nit.
- Critical: security, data loss, crash, race condition
- Major: logic error, missing validation, performance, missing tests
- Minor: style, suboptimal but correct, redundancy
- Nit: naming, formatting, alternative approaches
```

Collect results with `TaskOutput` (`block: true`). If an agent fails (model
error, timeout), note it and continue with the others.

### Step 4: Consolidate and deduplicate

Multiple agents may flag the same issues. Consolidate into a single report:

1. **Deduplicate** — if multiple agents flag the same issue, list it once with all agent sources
2. **Prioritize** — rank by severity: Critical > Major > Minor > Nit
3. **Categorize**:
   - **Actionable** — issues in code introduced by this branch
   - **Already Good** — positive observations
   - **Out of Scope** — pre-existing issues not introduced by this branch
   - **Already Known** — issues tracked elsewhere (e.g., placeholder IDs)

### Step 5: Present consolidated report

Use this format:

```markdown
## Consolidated Code Quality Report

### Critical (must fix)
| # | File | Issue | Source |
|---|------|-------|--------|
| 1 | file.py:line | Description | Agent1, Agent2 |

### Major (should fix)
| # | File | Issue | Source |
|---|------|-------|--------|
| 2 | file.py:line | Description | Agent1 |

### Minor (nice to fix)
| # | File | Issue | Source |
|---|------|-------|--------|
| 3 | file.py:line | Description | Agent2 |

### Nit (optional)
- file.py:line — Description (Source)

### Already Good
- [bullet list of things done well]

### Out of Scope (pre-existing, not from this branch)
- [bullet list]
```

### Step 6: Ask for decision

End with:
> Which of these would you like me to address? My recommendation: [top 3 items with brief rationale].

Then wait for user response before making any changes.

## Guidelines

- **Never auto-fix** — always present findings and wait for user approval
- **Minimize noise** — only report issues with high confidence
- **Respect scope** — focus on changes from this branch, not the entire codebase
- **Be concise** — the consolidated report should be scannable in under 30 seconds
- **Credit agents** — note which agent(s) found each issue for transparency

## Troubleshooting

Error: Agent fails or times out
Cause: Model error, context limit, or network issue during parallel execution
Solution: Note the failed agent in the report, continue with results from the remaining agents

Error: Scope script reports no changes
Cause: Branch is identical to the default branch and the working tree is clean
Solution: Inform the user there is nothing to review, suggest checking the correct branch

Error: Too many changed files for agents to process
Cause: Large feature branch with extensive changes
Solution: Ask the user to scope the review to specific files using `/code-quality <files>`
