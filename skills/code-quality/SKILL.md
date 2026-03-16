---
name: code-quality
description: >
  Run parallel code quality agents (code review, simplifier, dead code detector,
  cleanup, best practices) on branch changes. Use when user says "check code quality",
  "review my changes", "run quality check", "is my code ready", or when finishing a
  feature, before committing, or before creating a PR. Do NOT use for reviewing
  a single file in isolation or for existing code that hasn't changed.
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Code Quality — Parallel Multi-Agent Review

## Overview

Launches 5 specialized code quality agents **in parallel** against the current branch changes (compared to master). Collects results and presents a single consolidated report with prioritized, deduplicated findings.

## Invocation

```
/code-quality              # Review all unstaged + untracked changes vs master
/code-quality <files>      # Focus on specific files
```

## Agents

| Agent | Type | Purpose |
|-------|------|---------|
| Code Reviewer | `pr-review-toolkit:code-reviewer` | Bugs, logic errors, security, conventions |
| Code Simplifier | `branch-code-simplifier` | Complexity reduction, duplication, simplification |
| Dead Code Detector | `dead-code-detector` | Unused functions, imports, locators, constants |
| Post-Dev Cleanup | `code-cleanup-post-dev` | Debug logs, TODO comments, dev artifacts |
| Best Practices | `code-best-practices-reviewer` | Coupling, cohesion, naming, error handling, CLAUDE.md compliance |

## Instructions

When the user invokes this skill:

### Step 1: Identify scope

Run `git diff master --stat` and `git status --short` to identify all changed and untracked files. If the user provided specific files, scope to those.

### Step 2: Launch all 5 agents in parallel

Use the Task tool to launch **all 5 agents simultaneously in a single message** with `run_in_background: true`. Each agent gets a prompt like:

```
Analyze the code changes on branch `<branch>` compared to `master`.
[Agent-specific focus area].
The changes are across these files: [list files].
Run `git diff master` to see the full diff.
```

For untracked files, mention them explicitly so agents read them directly.

### Step 3: Collect results

Wait for all agents using `TaskOutput` with `block: true`. If an agent fails (model error, timeout), note it and continue with the others.

### Step 4: Consolidate and deduplicate

Many agents will flag the same issues. Consolidate into a single report:

1. **Deduplicate** — if multiple agents flag the same issue, list it once with all agent sources
2. **Prioritize** — rank by severity: High > Medium > Low
3. **Categorize**:
   - **Actionable** — issues in code introduced by this branch
   - **Already Good** — positive observations
   - **Out of Scope** — pre-existing issues not introduced by this branch
   - **Already Known** — issues tracked elsewhere (e.g., placeholder IDs)

### Step 5: Present consolidated report

Use this format:

```markdown
## Consolidated Code Quality Report

### Actionable Items

| # | Priority | File | Issue | Source |
|---|----------|------|-------|--------|
| 1 | High | file.py:line | Description | Agent1, Agent2 |
| ... | ... | ... | ... | ... |

### Already Good (positive notes)
- [bullet list of things done well]

### Out of Scope (pre-existing, not from this branch)
- [bullet list]

### Already Known
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

## Example

```
User: /code-quality

Agent: [Runs git diff master --stat, identifies 6 changed files]
       [Launches 5 agents in parallel with run_in_background: true]
       [Collects all results]
       [Deduplicates and consolidates]

       ## Consolidated Code Quality Report

       ### Actionable Items
       | # | Priority | File | Issue | Source |
       |---|----------|------|-------|--------|
       | 1 | High | views.py:2543 | Unused locator `foo_bar` | Dead code, Simplifier |
       | 2 | Medium | utils.py:88 | Missing type hints | Simplifier, Best practices |

       ### Already Good
       - Clean abstraction with mapping dict
       - Backward-compatible defaults

       Which items would you like me to fix? I recommend #1 and #2.
```

## Troubleshooting

Error: Agent fails or times out
Cause: Model error, context limit, or network issue during parallel execution
Solution: Note the failed agent in the report, continue with results from the remaining agents

Error: No changes found on branch
Cause: Branch is identical to master or all changes are committed and merged
Solution: Inform the user there are no changes to review, suggest checking the correct branch

Error: Too many changed files for agents to process
Cause: Large feature branch with extensive changes
Solution: Ask the user to scope the review to specific files using `/code-quality <files>`
