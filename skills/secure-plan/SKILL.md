---
name: secure-plan
description: >
  Review plans, designs, and architecture proposals for security vulnerabilities
  and attack surface exposure. Checks against 11 vulnerability categories derived
  from real-world AI-exploited breaches. Supports --deep flag for parallel
  multi-agent review of large plans or architecture blueprints. Use when user says
  "review plan for security", "security check plan", "is this plan secure", or after
  completing any planning phase involving authentication, APIs, data storage, user
  input, cloud infrastructure, or new dependencies. Do NOT use for reviewing actual
  code — use the secure-code-reviewer agent for that.
metadata:
  author: Aviad Polak
  version: 1.2.0
---

# Secure Plan Reviewer

## Overview

Review implementation plans for security vulnerabilities using 11 vulnerability
categories derived from real-world breaches that AI agents successfully exploited
for under $10 each. Depth is adaptive:

- **Single-pass** (default): the main session applies all categories — right for
  typical feature plans
- **Deep mode** (`--deep`): 3 parallel agents split by attack surface — for
  large plans and architecture blueprints

Both modes end with the interactive phase: pause, ask the user targeted
security questions, incorporate answers, then finalize.

**Severity Rule**: All security issues are CRITICAL by default. Downgrade to
Important only if the issue requires a specific, unlikely attack chain AND the
system is not internet-facing.

**Related:** for reviewing actual code, use the `secure-code-reviewer` agent;
for PR diffs, review-pr's deep mode includes a security checker.

## Invocation

```
/secure-plan                      # Single-pass review (default)
/secure-plan --deep               # Parallel 3-agent review
```

## When to Use

Invoke this skill when reviewing plans for:
- New features involving authentication, authorization, or session management
- API design or endpoint additions
- Database schema or data storage decisions
- Features accepting user input or rendering user content
- Cloud infrastructure or deployment architecture
- Adding new packages or dependencies
- Webhook, callback, or URL-fetching functionality

Do NOT use this skill for scanning existing code files.

## Categories at a Glance

Detailed checklists, probe questions, and mitigations live in
`references/vulnerability-categories.md` — read that file when applying them
(single-pass), or hand its path to agents (deep mode).

| # | Category | Focus |
|---|----------|-------|
| 1 | Authentication Bypass | Skipped auth, custom auth, JWT flaws, unguarded webhooks |
| 2 | Exposed API Docs/Endpoints | Swagger/playground in prod, debug endpoints, verbose errors |
| 3 | Open/Unauthenticated Databases | Default creds, exposed ports, missing segmentation |
| 4 | Open Directory/File Exposure | Static serving, .git/.env exposure, upload paths |
| 5 | Stored XSS and Injection | Unsanitized rendering, string-built queries, command injection |
| 6 | Cloud Storage Misconfiguration | Public buckets, CORS wildcard, long-lived pre-signed URLs |
| 7 | SSRF — deep analysis | User-supplied URL fetches, IMDS pivot, redirect/DNS-rebinding |
| 8 | Repository/Code Secrets | Hardcoded secrets, .gitignore gaps, keys in bundles |
| 9 | Debug/Admin Endpoint Exposure | Actuator/heapdump, DEBUG=True, introspection |
| 10 | Session/Auth Logic Flaws — deep analysis | Fixation, invalidation gaps, localStorage tokens, CSRF, OAuth |
| 11 | Package/Dependency Security | CVEs, maintenance status, pinning, typosquatting |
| D1-D5 | Defensive Domains | Attack surface, input/output hardening, sandboxing, secrets/config, supply chain |

**Dependency checks (category 11) use the shared script — not WebSearch:**

```bash
bash "<skill-dir>/../../scripts/check-deps.sh" <ecosystem> <package> [package...]
# → known OSV vulnerability IDs + latest version and release date
```

## Single-Pass Workflow (default)

1. **Read the Plan**: Read the complete plan to understand the proposed
   architecture and approach
2. **Apply Vulnerability Categories**: Read
   `references/vulnerability-categories.md` and systematically check the plan
   against all 11 categories and 5 defensive domains. Run `check-deps.sh` for
   any proposed packages
3. **Identify Issues**: Document all findings — CRITICAL by default per the
   severity rule
4. **Probe Ambiguities**: STOP and ask the user targeted security questions
   (see Interactive Mode) before finalizing
5. **Present Findings**: Deliver structured feedback in the output format below

**IMPORTANT**: After step 3, you MUST pause and present preliminary findings
with probing questions. Do NOT skip the interactive phase. Ambiguous areas in
a plan are where security vulnerabilities hide.

## Deep Mode (`--deep`)

Use when the plan is large (roughly > 1,500 words or multi-page), is a full
`/architect` blueprint, or spans many surfaces at once (auth + APIs + storage
+ dependencies). If invoked without `--deep` on such a plan, offer deep mode
before starting.

### Plan handoff

If the plan is a file, pass its absolute path to agents. If it only exists in
conversation, write it once to `/tmp/secure-plan-input.md` and pass that path —
never paste the plan text into three prompts.

### Agent split — by attack surface

Launch all 3 agents in a SINGLE message using the Agent tool with
`run_in_background: true`:

| Agent | Categories | Defensive Domains |
|-------|-----------|-------------------|
| Perimeter & Exposure | 1 Auth bypass, 2 API exposure, 4 File/dir exposure, 9 Debug/admin | D1 Attack surface |
| Data & Input | 3 Databases, 5 XSS/injection, 6 Cloud storage, 8 Secrets | D2 Input/output, D4 Secrets & config |
| Flows & Chains | 7 SSRF, 10 Session/auth logic, 11 Dependencies | D3 Sandboxing, D5 Supply chain |

Each agent prompt must include:
- The absolute path to the plan (file or `/tmp/secure-plan-input.md`)
- The absolute path of `references/vulnerability-categories.md` (resolve from
  this skill's directory) plus its assigned category numbers and domains —
  the agent reads the file itself; do NOT paste category text
- The severity rule (CRITICAL by default, as stated in the reference)
- For the Flows & Chains agent: the absolute path of
  `<skill-dir>/../../scripts/check-deps.sh` with instructions to run it for
  every package the plan proposes
- Instructions to report findings in the Output Format fields (category,
  current approach, threat, recommendation) and to list unanswered Probe
  questions as "Open questions" — agents must NOT ask the user directly
- Instructions to be adversarial — find what's exploitable, not what's fine

### Consolidation

1. **Deduplicate** — merge findings flagged by multiple agents, note agreement
2. **Attack-chain pass** — the step shards cannot do themselves: look for
   findings from *different* agents that compose into a single exploit chain
   (e.g., SSRF [7] reaches IMDS → credentials [8] → public bucket write [6]).
   Report each chain as a new CRITICAL finding with the full path spelled out
3. **Collect open questions** from all agents, deduplicate them
4. **Prioritize** — Critical > Important > Minor

Then continue with **Probe Ambiguities** (step 4 of the single-pass workflow) —
the interactive phase always runs in the main session, using the consolidated
open questions. Incorporate the user's answers and present the final report.

## Output Format

Present findings in this structure:

### Critical Issues
Issues that create exploitable vulnerabilities or violate security fundamentals.
- **[Issue description]**
  - Category: [1-11 category name]
  - Current approach: [what the plan proposes]
  - Threat: [how an attacker would exploit this]
  - Recommendation: [specific fix]

### Important Issues
Issues that weaken security posture but require specific conditions to exploit.
- **[Issue description]**
  - Category: [1-11 category name]
  - Current approach: [what the plan proposes]
  - Risk: [why this matters]
  - Recommendation: [specific improvement]

### Minor Issues
Defense-in-depth improvements that enhance the overall security posture.
- **[Issue description]**
  - Suggestion: [improvement idea]

### Security Checklist
- [ ] Authentication bypass vectors checked
- [ ] API exposure reviewed
- [ ] Database access controls verified
- [ ] File/directory exposure checked
- [ ] XSS/injection vectors identified
- [ ] Cloud storage permissions reviewed
- [ ] SSRF vectors analyzed (in depth)
- [ ] Secret management verified
- [ ] Debug/admin endpoints secured
- [ ] Session/auth logic reviewed (in depth)
- [ ] Package/dependency security verified (check-deps.sh run)
- [ ] All 5 defensive domains evaluated
- [ ] (Deep mode) Attack-chain pass completed

### Summary
- Total issues found: [count by severity]
- Recommendation: [Approve / Revise / Reject]
- Top risks: [2-3 most critical findings]

## Interactive Mode

Before finalizing (both modes), you MUST present:

1. **Preliminary findings** grouped by severity
2. **Targeted questions** for ambiguous areas, grouped by category — use the
   Probe lists in the reference file (or the agents' collected open
   questions), asking only what the plan leaves unclear

Example interaction:

> **Preliminary findings:** I identified 3 critical issues related to SSRF
> (Category 7) and session management (Category 10). Before finalizing:
>
> **SSRF questions:**
> - The plan mentions a "URL preview" feature — does this fetch URLs server-side?
> - Will the service run on AWS? If so, is IMDSv2 enforced?
>
> **Session questions:**
> - The plan uses JWT — where will tokens be stored client-side?
> - What happens to active tokens when a user changes their password?

Wait for the user's answers before finalizing the report. Incorporate their
responses into the final assessment — answers may resolve or escalate findings.

## Usage Example

**User provides plan:**
"I plan to add an image upload API. Users provide a URL, the server fetches the
image, resizes it, and stores it in S3. We'll use the `sharp` library for
image processing."

**Secure plan reviewer checks (single-pass — small plan):**
1. **SSRF (Category 7)**: Server fetches from user-supplied URLs — CRITICAL
2. **File exposure (Category 4)**: Uploaded files in S3 — check bucket ACL
3. **Injection (Category 5)**: Image processing with user files — check for image bombs
4. **Package security (Category 11)**: `bash check-deps.sh npm sharp` — CVEs + freshness
5. **Probe**: Ask about URL validation, S3 bucket policy, file size limits

## Troubleshooting

**Error: No plan provided**
Cause: User invoked the skill without sharing a plan first
Solution: Ask the user to provide or describe their plan before running validation

**Error: Plan too vague for security analysis**
Cause: Plan lacks specifics about endpoints, data flow, or infrastructure
Solution: Ask clarifying questions about the intended architecture before proceeding

**Error: check-deps.sh fails**
Cause: No network access, or jq/curl unavailable
Solution: Note unverified packages in the report and recommend the user run
`npm audit` / `pip audit` / equivalent manually

**Error: Deep-mode agent fails or times out**
Cause: Model error or context limit
Solution: Note the failed agent, run its assigned categories yourself in the
main session, continue with the others' results
