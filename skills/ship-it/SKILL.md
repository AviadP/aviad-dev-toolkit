---
name: ship-it
description: >
  Automate the full git shipping workflow — create branch, commit, push, open PR,
  merge, and update local main. Use when user says "ship it", "ship my changes",
  "push and merge", "create a PR and merge", or when there are staged/unstaged
  changes ready to ship. Do NOT use for partial workflows like just committing
  or just pushing without the full branch-to-main cycle.
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Ship It — Branch-to-Main Shipping Workflow

## Overview

Automates the complete git shipping cycle: create a feature branch, commit changes, push to remote, open a PR on GitHub, merge it, and update local main. Respects the project's git aliases (`git cs`, `git p`).

## Invocation

```
/ship-it <branch-name>                    # Auto-generate commit message
/ship-it <branch-name> "<commit message>" # Explicit commit message
```

## Workflow

Execute these steps **sequentially** — each depends on the previous:

### Step 1: Preflight Check

1. Run `git status` to verify there are changes to commit (staged or unstaged).
2. If no changes exist, stop and inform the user.
3. Run `git diff` and `git diff --cached` to understand what will be committed.
4. Run `git log --oneline -5` to match commit message style.

### Step 2: Create Branch

```bash
git checkout -b <branch-name>
```

If the branch already exists, stop and ask the user how to proceed.

### Step 3: Stage and Commit

1. Stage relevant files by name (avoid `git add -A` or `git add .`).
2. **Never** stage files that likely contain secrets (`.env`, credentials, tokens).
3. If no commit message was provided, draft one based on the diff analysis.
4. Commit using the project alias:

```bash
git cs "<commit message>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

5. If the pre-commit hook fails with a **false positive** (e.g., test files flagged for containing `api_key` as a variable name), inform the user and ask whether to retry with `--no-verify`.
6. If the hook fails with a **real issue**, fix it and create a NEW commit (never amend).

### Step 4: Push

```bash
git p
```

If this is the first push for the branch and `git p` fails because no upstream is set, use:

```bash
git push -u origin <branch-name>
```

Then retry with `git p` for subsequent pushes.

### Step 5: Create PR

Create a pull request using `gh pr create`:

```bash
gh pr create --title "<short title>" --body "$(cat <<'EOF'
## Summary
<bullet points describing the changes>

## Test plan
<checklist of testing steps>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- Keep the PR title under 70 characters.
- Derive the summary from the actual diff, not guesses.

### Step 6: Merge

```bash
gh pr merge <pr-number> --merge
```

### Step 7: Update Local Main

```bash
git checkout main && git pull
```

### Step 8: Report

Output a summary:
- Branch name
- Commit hash
- PR URL
- Final main HEAD

## Examples

### Example 1: Ship a new feature
```
User: /ship-it add-starship-config
Agent: [Verifies git aliases: git config --get alias.cs, git config --get alias.p]
       [Runs git status — finds 1 modified file: terminal_cfg/starship.toml]
       [Creates branch: git checkout -b add-starship-config]
       [Stages file by name: git add terminal_cfg/starship.toml]
       [Commits: git cs "Update starship prompt configuration"]
       [Pushes: git p]
       [Creates PR with summary derived from diff]
       [Merges PR]
       [Updates local main: git checkout main && git pull]

       Ship complete:
       - Branch: add-starship-config
       - Commit: a1b2c3d
       - PR: https://github.com/user/repo/pull/42
       - Main HEAD: e4f5g6h
```

### Example 2: Ship with explicit commit message
```
User: /ship-it fix-login-bug "Fix null pointer in auth middleware"
Agent: [Verifies git aliases exist]
       [Same flow, uses provided commit message instead of auto-generating]
```

## Rules

- **Always** use `git cs` instead of `git commit` (project alias).
- **Always** use `git p` instead of `git push` (project alias).
- **Never** force push.
- **Never** amend commits — create new ones if fixes are needed.
- **Never** stage `.env`, credential files, or secrets.
- **Never** skip hooks without informing the user and getting approval.
- Stage files **by name**, not with `-A` or `.`.
- If any step fails, stop and report the error — don't continue blindly.

## Troubleshooting

Error: Git aliases (cs, p) not found
Cause: Project aliases not configured on this machine
Solution: Fall back to `git commit -s -m` and `git push`, or ask the user to set up aliases first

Error: Merge conflicts on PR
Cause: Main has diverged since branch was created
Solution: Stop, inform the user, suggest rebasing locally before retrying merge

Error: PR checks failing
Cause: CI pipeline rejects the changes
Solution: Stop, show the failing check output, ask the user to fix before retrying merge

Error: GitHub auth failure on gh commands
Cause: gh CLI not authenticated or token expired
Solution: Ask the user to run `gh auth login` and retry
