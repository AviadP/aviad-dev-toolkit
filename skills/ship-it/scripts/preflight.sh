#!/usr/bin/env bash
set -euo pipefail

# Runs all entry gates and collects context for the ship-it skill.
# Replaces 5-6 model turns with a single script call.
#
# Usage: preflight.sh
# Output: structured report to stdout

printf '%s\n' "# Ship-It Preflight Report"
printf '\n'

# --- Gate 1: Changes exist ---
STATUS_OUTPUT=$(git status --porcelain 2>&1)
if [[ -z "$STATUS_OUTPUT" ]]; then
    printf '%s\n' "## Gate: Changes Exist → FAIL"
    printf '%s\n' "Nothing to ship — working tree is clean."
    exit 1
fi
printf '%s\n' "## Gate: Changes Exist → PASS"

# --- Gate 2: Current branch vs default branch ---
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
if REF=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null); then
    DEFAULT_BRANCH="${REF#origin/}"
elif git show-ref --verify --quiet refs/heads/main; then
    DEFAULT_BRANCH="main"
else
    DEFAULT_BRANCH="master"
fi
printf '%s\n' "## Gate: Current Branch → ${CURRENT_BRANCH} (default: ${DEFAULT_BRANCH})"
if [[ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]]; then
    printf '%s\n' "WARNING: On feature branch '${CURRENT_BRANCH}', not ${DEFAULT_BRANCH}."
fi

# --- Gate 3: Secrets scan ---
# 3a: sensitive filenames
SECRET_FILES=""
while IFS= read -r line; do
    file="${line:3}"
    case "$file" in
        .env|.env.*|*.key|*.pem|credentials*|*secret*|*.p12|*.pfx)
            SECRET_FILES="${SECRET_FILES}  - ${file}"$'\n'
            ;;
    esac
done <<< "$STATUS_OUTPUT"

# 3b: hardcoded credentials in added lines (quoted literal 8+ chars)
SECRET_PATTERN="^\+.*(api[_-]?key|apikey|password|passwd|secret|token)[^=:]{0,3}[:=][[:space:]]*['\"][^'\"]{8,}"
SECRET_LINES=$( { git diff; git diff --cached; } 2>/dev/null | grep -inE "$SECRET_PATTERN" | head -10 || true)

if [[ -n "$SECRET_FILES" || -n "$SECRET_LINES" ]]; then
    printf '%s\n' "## Gate: Secrets Scan → WARNING"
    if [[ -n "$SECRET_FILES" ]]; then
        printf '%s\n' "Sensitive files detected (exclude from staging):"
        printf '%s' "$SECRET_FILES"
    fi
    if [[ -n "$SECRET_LINES" ]]; then
        printf '%s\n' "Added lines that look like hardcoded credentials (verify before staging):"
        printf '%s\n' "$SECRET_LINES"
    fi
else
    printf '%s\n' "## Gate: Secrets Scan → PASS"
fi

# --- Gate 4: GitHub CLI auth ---
if gh auth status &>/dev/null; then
    printf '%s\n' "## Gate: GitHub CLI → PASS"
else
    printf '%s\n' "## Gate: GitHub CLI → FAIL"
    printf '%s\n' "Run \`gh auth login\` first."
    exit 1
fi

# --- Gate 5: Git aliases ---
ALIAS_CS=$(git config --get alias.cs 2>/dev/null || echo "")
ALIAS_P=$(git config --get alias.p 2>/dev/null || echo "")
if [[ -n "$ALIAS_CS" && -n "$ALIAS_P" ]]; then
    printf '%s\n' "## Gate: Git Aliases → PASS (cs, p)"
    printf '%s\n' "- cs = ${ALIAS_CS}"
    printf '%s\n' "- p = ${ALIAS_P}"
else
    printf '%s\n' "## Gate: Git Aliases → MISSING"
    printf '%s\n' "Fallback: git commit -s -m / git push"
fi

# --- Context: Changed files ---
printf '\n'
printf '%s\n' "## Changed Files"
git status --short

# --- Context: Diff stat ---
printf '\n'
printf '%s\n' "## Diff Stats"
git diff --stat 2>/dev/null || true
git diff --cached --stat 2>/dev/null || true

# --- Context: Truncated diff (first 100 lines) ---
printf '\n'
printf '%s\n' "## Diff Preview (truncated)"
FULL_DIFF=$(git diff 2>/dev/null; git diff --cached 2>/dev/null)
DIFF_LINES=$(echo "$FULL_DIFF" | wc -l | tr -d ' ')
echo "$FULL_DIFF" | head -100
if [[ "$DIFF_LINES" -gt 100 ]]; then
    printf '%s\n' "... (${DIFF_LINES} total lines, showing first 100)"
fi

# --- Context: Recent commits (for style matching) ---
printf '\n'
printf '%s\n' "## Recent Commits (style reference)"
git log --oneline -5 2>/dev/null || echo "(no commits)"
