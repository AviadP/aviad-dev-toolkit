---
name: bug-hunt
description: >
  Hunt for real, triggerable bugs in your code using parallel specialized agents
  with validation. Three hunting agents (pattern hunter, logic analyzer,
  contract checker) run in parallel, then a validator/simulator agent filters
  findings through a 3-question kill gate and confidence scoring. Small diffs
  get a cheaper single-pass quick mode instead of agents.
  Use when user says "hunt bugs", "find bugs", "bug hunt", "check for bugs",
  "what bugs are hiding", or wants proactive bug detection beyond code review.
  Do NOT use for security-focused review (use secure-code-reviewer),
  code quality/style (use code-quality), or debugging known failures (use debug).
metadata:
  author: Aviad Polak
  version: 1.1.0
---

# Bug Hunt — Adaptive Bug Detection with Validation

## Overview

Hunts for real, triggerable bugs through three lenses — patterns, logic,
contracts — then validates every finding with a kill gate that filters out
anything theoretical. Depth is adaptive:

- **Quick mode** (small diffs): single-pass hunt in the main session, no agents
- **Deep mode** (large diffs): 3 hunting agents in parallel + validator agent

Core principle:
> "Can this bug be triggered RIGHT NOW, through a realistic code path, with
> realistic inputs — and does it cause real harm?" If NO — kill the finding.

## Invocation

```
/bug-hunt                    # Hunt in branch changes vs the default branch
/bug-hunt <files|directory>  # Hunt in specific files or a directory
/bug-hunt --quick            # Force quick mode (no agents, cheapest)
/bug-hunt --deep             # Force deep mode (parallel agents)
```

## Phase 0: Scope

1. **User specified files or a directory** — resolve to a concrete file list.
   This is "explicit scope": the files are analyzed in full.
2. **Otherwise** — run the shared scope script:

   ```bash
   bash "<skill-dir>/../../scripts/git-scope.sh" bug-hunt
   ```

   It detects the default branch (origin/HEAD → main → master), writes the
   full diff (untracked files included as new-file diffs) to
   `/tmp/bug-hunt-diff.txt` and the changed-file list to
   `/tmp/bug-hunt-files.txt`, and prints a recommended mode by diff size.
   If it reports no changes, inform the user and stop.

Do NOT read the target files in this phase — reading happens once, inside
whichever mode runs.

## Phase 1: Mode Selection

- User passed `--quick` or `--deep` → use it, no questions.
- Script recommends quick (< 200 changed lines) → use quick mode; tell the
  user in one line.
- Otherwise → ask via AskUserQuestion: **Deep (Recommended)** — thorough,
  4 agents, higher token cost — vs **Quick** — single-pass, cheapest.
  For explicit scope, base the recommendation on total file size (`wc -l`).

## The Three Lenses + Validator

| Role | Prompt file | Focus |
|------|-------------|-------|
| Pattern Hunter | `references/pattern-hunter-prompt.md` | Off-by-one, null handling, resource leaks, wrong operators, API misuse, error-handling gaps |
| Logic Analyzer | `references/logic-analyzer-prompt.md` | Incorrect conditions, missing branches, state issues, async/concurrency, control flow |
| Contract Checker | `references/contract-checker-prompt.md` | Caller-callee mismatches, return-value mishandling, external API assumptions, data format mismatches |
| Validator/Simulator | `references/validator-simulator-prompt.md` | 3-question kill gate (Reachable? Triggerable? Unguarded?) + independent edge-case simulation |

The kill gate is fully defined in the validator prompt — that file is the
single source of truth; do not restate it. Scales used in the report:

| Confidence | Meaning |
|------------|---------|
| **High** | Concrete trigger identified, no guards, behavior verified in code |
| **Medium** | Likely triggerable but some uncertainty (complex call chain, partial guards) |
| **Low** | Plausible but multiple conditions must align, or guards may partially block |

| Severity | Definition |
|----------|-----------|
| **Critical** | Data loss, data corruption, crash, security vulnerability, broken core functionality |
| **Major** | Wrong results, silent incorrect behavior, performance degradation, lost error context |
| **Minor** | Edge case with limited blast radius, non-critical incorrect behavior, cosmetic data issue |

## Scope Block (used in all agent prompts)

Every prompt file contains a `{SCOPE}` placeholder. Fill it with one of:

**Branch scope:**
```
Scope: branch changes only.
- Full diff: /tmp/bug-hunt-diff.txt — read it first; analyze ONLY added/modified code
- Changed files:
<contents of /tmp/bug-hunt-files.txt>
- Repo root: <absolute path>
```

**Explicit scope:**
```
Scope: analyze these files in full:
<file list with absolute paths>
```

## Quick Mode

The main session does everything — no agents:

1. Read the three lens prompts and the validator prompt from `references/`
   (they are small).
2. Read the diff (or the explicit files); open surrounding source only where
   needed to confirm callers, guards, or definitions.
3. Hunt with all three lenses, then apply the 3-question kill gate to every
   candidate finding yourself. Kill anything without a concrete trigger —
   see Red Flags.
4. Jump to Consolidation (skip the sibling scan only if nothing survived).

## Deep Mode

### Hunting (parallel)

Launch all 3 hunting agents in a SINGLE message using the Agent tool with
`run_in_background: true`. For each agent: read its prompt file and replace
`{SCOPE}` with the scope block above.

### Validation

Collect all hunter findings. Read `references/validator-simulator-prompt.md`
and replace:
- `{FINDINGS}` — all collected findings, labeled by source agent
- `{SCOPE}` — the same scope block
- `{THINKING_MODELS}` — absolute path of `<skill-dir>/../../shared/thinking-models.md`

Launch the validator agent and wait for its results.

## Consolidation

1. **Merge** validated findings + new simulation findings
2. **Deduplicate** — same bug from multiple agents = one entry, credit all sources
3. **Sort** by Severity (Critical > Major > Minor), then Confidence (High > Medium > Low)
4. **A→B sibling scan** — if a validated bug reveals a CLASS of mistake
   (e.g., missing null check on API responses), grep the target files for
   siblings and report them as "Sibling Signals" — high-confidence leads.
   Time-box: 2 minutes; nothing found = move on.

## Report

```markdown
## Bug Hunt Report

**Scope:** [files analyzed] | **Mode:** Quick / Deep
**Findings:** X validated (Y killed) | Z from simulation

### Critical
| # | File:Line | Bug | Confidence | Trigger | Source |
|---|-----------|-----|-----------|---------|--------|

### Major
(same columns)

### Minor
(same columns)

### Sibling Signals (A→B)
- [If a bug class was found, other locations with the same pattern]

### Killed (for transparency)
<details>
<summary>X findings killed by validation</summary>

| # | Finding | Kill Reason |
|---|---------|------------|

</details>
```

End with:
> Which findings would you like me to investigate further or fix?
> Recommendation: [top items with brief rationale]

Wait for user response before making any changes.

## Guidelines

- **Never auto-fix** — present findings and wait for user approval
- **Kill theoretical findings ruthlessly** — "could theoretically..." = kill
- **Concrete scenarios only** — every finding must include specific triggering inputs
- **No style/quality overlap** — this is NOT code review. Don't report naming,
  formatting, or "better approaches"
- **Credit sources** — note which lens/agent found each issue
- **Respect scope** — analyze the specified files or branch changes, not the codebase
- **Show killed findings** — collapsed, for tuning the process over time

## Red Flags

| Thought | Reality |
|---------|---------|
| "This COULD be a problem if..." | Can you construct the scenario? If not, kill it. |
| "Best practice says..." | That's code review, not bug hunting. |
| "Missing validation for..." | Is the input actually possible? Check the 5 constraint layers. |
| "This doesn't handle..." | Does it need to? Check if the unhandled case can actually occur. |
| "Potential race condition" | Between which specific concurrent operations? No specifics = kill. |
| "Error not handled" | Does the caller/framework handle it? Check before reporting. |

## Troubleshooting

Error: Hunting agent fails or times out
Cause: Model error, context limit, too many files
Solution: Note the failed agent, continue with others. Suggest narrowing scope.

Error: Validator kills ALL findings
Cause: Hunting agents reported theoretical/guarded bugs
Solution: Working as intended. Report "clean" result. Don't lower the bar.

Error: Scope script fails (not a git repo, no default branch)
Cause: Running outside a git repository or unusual branch setup
Solution: Ask the user for explicit files/directory to hunt in.
