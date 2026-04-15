---
name: bug-hunt
description: >
  Hunt for real, triggerable bugs in your code using parallel specialized agents
  with validation. Three hunting agents (pattern hunter, logic analyzer,
  contract checker) run in parallel, then a validator/simulator agent filters
  findings through a 3-question kill gate and confidence scoring.
  Use when user says "hunt bugs", "find bugs", "bug hunt", "check for bugs",
  "what bugs are hiding", or wants proactive bug detection beyond code review.
  Do NOT use for security-focused review (use secure-code-reviewer),
  code quality/style (use code-quality), or debugging known failures (use debug).
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Bug Hunt — Multi-Agent Bug Detection with Validation

## Overview

Hunts for real, triggerable bugs using 3 hunting agents in parallel, followed
by a validator/simulator that filters out theoretical findings and scores
survivors by confidence and severity.

Core principle:
> "Can this bug be triggered RIGHT NOW, through a realistic code path, with
> realistic inputs — and does it cause real harm?" If NO — kill the finding.

## Invocation

```
/bug-hunt                    # Hunt in all branch changes vs master
/bug-hunt <files>            # Hunt in specific files
/bug-hunt <directory>        # Hunt in a specific directory
```

## Entry Gates

1. **Code exists** — changed files on branch, or user-specified files/directory
2. **Scope is clear** — if no files specified, scope = branch changes vs master

## Agents

| Agent | Phase | Prompt | Focus |
|-------|-------|--------|-------|
| Pattern Hunter | 1 (parallel) | `references/pattern-hunter-prompt.md` | Off-by-one, null handling, resource leaks, incorrect operators, API misuse, error handling gaps |
| Logic Analyzer | 1 (parallel) | `references/logic-analyzer-prompt.md` | State violations, impossible/missing branches, incorrect conditions, async/concurrency issues |
| Contract Checker | 1 (parallel) | `references/contract-checker-prompt.md` | Caller-callee mismatches, unhandled returns, wrong external API assumptions, error propagation |
| Validator/Simulator | 2 (sequential) | `references/validator-simulator-prompt.md` | Validates findings via kill gate, scores survivors, independently simulates edge-case paths |

## 3-Question Kill Gate

Applied by the Validator to every finding. One "no" = kill.

1. **Reachable?** — Is this code path actually executed?
   Dead code, disabled feature flags, test-only code = kill

2. **Triggerable?** — Can you construct ONE concrete scenario with specific inputs?
   Can't describe the trigger = kill

3. **Unguarded?** — Check 5 constraint layers (all block it = kill):
   - Defaults (schema, DB column, config, API spec)
   - Boundary validation (input validation, API schema, CLI parsing)
   - Type constraints (enums, non-nullable, value ranges)
   - Caller guarantees (all call sites pre-validate)
   - Infrastructure guards (auth middleware, rate limiters, RBAC)

## Confidence & Severity

| Confidence | Meaning |
|------------|---------|
| **High** | Concrete trigger identified, no guards, behavior verified in code |
| **Medium** | Likely triggerable but some uncertainty (complex call chain, partial guards) |
| **Low** | Plausible but multiple conditions must align, or guards may partially block |

| Severity | Definition |
|----------|-----------|
| **Critical** | Data loss, data corruption, crash, security vulnerability, broken core functionality |
| **Major** | Wrong results, silent incorrect behavior, performance degradation, error handling that loses context |
| **Minor** | Edge case with limited blast radius, non-critical incorrect behavior, cosmetic data issue |

## Workflow

### Phase 0: Scope Identification

1. Determine target files:
   - If user specified files/directory: use those
   - Otherwise: `git diff master --name-only` + `git status --short`
2. If no files found, inform user and stop
3. Read all target files to understand the codebase context

### Phase 1: Parallel Hunting (3 agents)

Launch all 3 hunting agents simultaneously using the Agent tool with
`run_in_background: true`.

For each agent:
1. Read its prompt from the corresponding `references/` file
2. Replace `[list files]` with the actual file list
3. Launch with `run_in_background: true`

### Phase 2: Validation & Simulation

After all Phase 1 agents complete, collect their findings and launch the
Validator/Simulator:

1. Read `references/validator-simulator-prompt.md`
2. Replace `[paste all findings from Phase 1]` with the collected findings
3. For borderline findings where the kill/keep decision isn't clear-cut,
   the Validator should consult `references/thinking-models.md`
4. Launch the agent and wait for results

### Phase 3: Consolidation

1. **Merge** validated findings + new simulation findings
2. **Deduplicate** — same bug found by multiple agents = list once with all sources
3. **Sort** by Severity (Critical > Major > Minor), then Confidence (High > Medium > Low)
4. **Apply A→B Signal Method** — if a validated bug reveals a CLASS of mistake
   (e.g., missing null check), scan for siblings: did the developer make the
   same mistake elsewhere in the target files? Time-box: 2 minutes max.

### Phase 4: Report

```markdown
## Bug Hunt Report

**Scope:** [files analyzed]
**Findings:** X validated (Y killed) | Z from simulation

### Critical
| # | File:Line | Bug | Confidence | Trigger | Source |
|---|-----------|-----|-----------|---------|--------|

### Major
| # | File:Line | Bug | Confidence | Trigger | Source |
|---|-----------|-----|-----------|---------|--------|

### Minor
| # | File:Line | Bug | Confidence | Trigger | Source |
|---|-----------|-----|-----------|---------|--------|

### Sibling Signals (A→B)
- [If a bug class was found, note other locations with the same pattern]

### Killed (for transparency)
<details>
<summary>X findings killed by validation</summary>

| # | Finding | Kill Reason |
|---|---------|------------|

</details>
```

### Phase 5: Ask for Decision

End with:
> Which findings would you like me to investigate further or fix?
> Recommendation: [top items with brief rationale]

Wait for user response before making any changes.

## The A→B Signal Method

When the validator confirms a bug, ask: "Is this a one-off, or a class of mistake?"

If it's a class (e.g., "missing null check on API response"), the same developer
likely made the same mistake elsewhere. Scan the target files for siblings.
Report them as "Sibling Signals" — high-confidence leads worth investigating.

Time-box: 2 minutes on sibling scanning. Nothing found = move on.

## Guidelines

- **Never auto-fix** — present findings and wait for user approval
- **Kill theoretical findings ruthlessly** — "could theoretically..." = kill
- **Concrete scenarios only** — every finding must include specific triggering inputs
- **No style/quality overlap** — this is NOT code review. Don't report naming,
  formatting, or "better approaches"
- **Credit sources** — note which agent(s) found each issue
- **Respect scope** — analyze specified files or branch changes, not the entire codebase
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

Error: Too many files to analyze
Cause: Large branch or broad directory scope
Solution: Ask user to scope to specific files or directories

## Example

```
User: /bug-hunt src/api/

Agent: [Phase 0: Identifies 8 files in src/api/]
       [Phase 1: Reads 3 agent prompts from references/, launches hunters in parallel]
       [Collects 12 raw findings]
       [Phase 2: Reads validator prompt, launches Validator/Simulator with all 12]
       [Validator kills 7, validates 5, finds 1 new via simulation]
       [Phase 3: Deduplicates, sorts, checks siblings]

       ## Bug Hunt Report

       **Scope:** src/api/ (8 files)
       **Findings:** 5 validated (7 killed) | 1 from simulation

       ### Critical
       | # | File:Line | Bug | Confidence | Trigger | Source |
       |---|-----------|-----|-----------|---------|--------|
       | 1 | handlers.py:142 | `user_id` from path parsed as string, compared with `==` to int DB ID — always false | High | GET /api/users/42/orders → empty result | Pattern Hunter, Contract Checker |

       ### Major
       | # | File:Line | Bug | Confidence | Trigger | Source |
       |---|-----------|-----|-----------|---------|--------|
       | 2 | service.py:89 | Pagination uses `>=` instead of `>` — skips last page when total is exact multiple of page_size | High | 100 items, page_size=10 → items 91-100 missing | Logic Analyzer |

       ### Minor
       | # | File:Line | Bug | Confidence | Trigger | Source |
       |---|-----------|-----|-----------|---------|--------|
       | 3 | utils.py:55 | `parse_date` assumes UTC when no timezone — wrong for local times | Medium | "2024-01-15T10:00:00" → treated as UTC | Simulator |

       ### Sibling Signals (A→B)
       - Bug #1 (type mismatch): same string-vs-int pattern at handlers.py:198, handlers.py:267

       <details>
       <summary>7 findings killed by validation</summary>

       | # | Finding | Kill Reason |
       |---|---------|------------|
       | K1 | Missing null check on user.email | Guarded: DB NOT NULL + API validation |
       | K2 | Division by zero in calculate_avg | Guarded: caller validates non-empty |

       </details>

       Which findings would you like me to investigate or fix?
       Recommendation: #1 (critical type mismatch) and #2 (pagination off-by-one).
```
