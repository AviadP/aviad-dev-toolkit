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
  version: 2.1.0
---

# Ship It — Branch-to-Main Shipping Workflow

## Invocation

```
/ship-it                                  # Auto-generate branch name + commit message
/ship-it <branch-name>                    # Auto-generate commit message
/ship-it <branch-name> "<commit message>" # Explicit commit message
```

## Step 1: Preflight

Run the preflight script to validate all entry gates and collect context:

```bash
bash "<skill-dir>/scripts/preflight.sh"
```

The script checks: changes exist, current branch vs the repo's default branch, secrets scan (sensitive filenames + hardcoded credentials in added lines), GitHub CLI auth, and git aliases. It also outputs the default branch name, changed files, diff stats, a truncated diff preview, and recent commit style.

**If any gate fails**, the script exits with an error message — stop and report it to the user.

**If on a feature branch** (not the default branch), ask: "You're on `<branch>` — ship from here, or switch to `<default-branch>` first?"

**If sensitive files are detected**, note which files will be excluded from staging. **If suspicious added lines are flagged**, read them and judge: real credential → stop and tell the user; false positive (test fixture, variable name) → note it and continue.

## Step 2: Create Branch

If no branch name was provided, generate a short kebab-case name from the
diff (e.g., `fix-retry-timeout`, `add-scope-script`).

```bash
git checkout -b <branch-name>
```

If the branch already exists, stop and ask the user how to proceed.

## Step 3: Stage and Commit

1. Stage relevant files **by name** — never use `git add -A` or `git add .`. Exclude any files flagged by the secrets scan.
2. If no commit message was provided, generate one based on the preflight diff preview and recent commit style.
3. Commit using project alias (or fallback from preflight):

```bash
git cs "<commit message>"
```

If pre-commit hook fails with a false positive (e.g., test variable named `api_key`), inform the user and ask whether to retry with `--no-verify`. If it fails with a real issue, fix it and create a NEW commit — never amend.

## Step 4: Push

```bash
git p
```

If no upstream is set and push fails, use `git push -u origin <branch-name>`.

## Step 5: Create PR

```bash
gh pr create --title "<short title>" --body "$(cat <<'EOF'
## Summary
<bullet points from the actual diff>

## Test plan
<checklist of testing steps>
EOF
)"
```

Keep title under 70 characters. Derive content from the actual diff, not guesses.

## Step 6: Merge and Update

```bash
gh pr merge <pr-number> --merge
git checkout <default-branch> && git pull
```

(`<default-branch>` comes from the preflight output — do not assume `main`.)

## Step 7: Verify and Clean Up

Run these checks — if any fail, report what succeeded and what didn't:

1. `gh pr view <pr-number> --json state --jq .state` — confirm `MERGED`
2. `git log --oneline -1` — confirm HEAD matches the merge commit
3. `git branch -d <branch-name>` — if it fails (unmerged changes), warn instead of force-deleting

## Step 8: Report

```
Ship complete:
- Branch: <branch-name>
- Commit: <short hash>
- PR: <PR URL>
- <default-branch> HEAD: <short hash>
- Gates: all passed / <detail if partial>
```

Only report "Ship complete" if all verification gates passed.
