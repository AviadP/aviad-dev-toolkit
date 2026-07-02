#!/usr/bin/env bash
set -euo pipefail

# Gate preflight — collects environment state and runs entry checks.
# Output: structured report to stdout

printf '%s\n' "# Gate Preflight Report"
printf '\n'

# --- Check 1: Git state ---
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
DEFAULT_BRANCH="main"
if ! git rev-parse --verify "$DEFAULT_BRANCH" &>/dev/null; then
    DEFAULT_BRANCH="master"
fi
printf '%s\n' "## Branch: ${CURRENT_BRANCH} (base: ${DEFAULT_BRANCH})"

# --- Check 2: Changes exist ---
DIFF_STAT=$(git diff "${DEFAULT_BRANCH}" --stat 2>/dev/null || echo "")
UNCOMMITTED=$(git status --porcelain 2>/dev/null || echo "")

if [[ -z "$DIFF_STAT" && -z "$UNCOMMITTED" ]]; then
    printf '%s\n' "## Changes: NONE"
    printf '%s\n' "No changes found against ${DEFAULT_BRANCH}. Nothing to gate."
    exit 1
fi

printf '%s\n' "## Changes vs ${DEFAULT_BRANCH}"
printf '%s\n' '```'
echo "$DIFF_STAT"
printf '%s\n' '```'

if [[ -n "$UNCOMMITTED" ]]; then
    printf '\n%s\n' "## Uncommitted Changes"
    printf '%s\n' '```'
    echo "$UNCOMMITTED"
    printf '%s\n' '```'
fi

# --- Check 3: Changed files list ---
printf '\n%s\n' "## Changed Files"
CHANGED_FILES=$(git diff "${DEFAULT_BRANCH}" --name-only 2>/dev/null || echo "")
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null || echo "")

if [[ -n "$CHANGED_FILES" ]]; then
    echo "$CHANGED_FILES"
fi
if [[ -n "$UNTRACKED" ]]; then
    printf '\n%s\n' "### Untracked"
    echo "$UNTRACKED"
fi

# --- Check 4: Venv status ---
printf '\n%s\n' "## Virtual Environment"
if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    printf '%s\n' "Active: ${VIRTUAL_ENV}"
else
    printf '%s\n' "WARNING: No virtual environment active"
    # Check if activate alias exists
    if type activate &>/dev/null 2>&1; then
        printf '%s\n' "Hint: 'activate' alias is available — run it before committing"
    elif [[ -f ".venv/bin/activate" ]]; then
        printf '%s\n' "Hint: .venv found — source .venv/bin/activate"
    fi
fi

# --- Check 5: Diff size ---
printf '\n%s\n' "## Diff Summary"
ADDITIONS=$(git diff "${DEFAULT_BRANCH}" --numstat 2>/dev/null | awk '{s+=$1} END {print s+0}')
DELETIONS=$(git diff "${DEFAULT_BRANCH}" --numstat 2>/dev/null | awk '{s+=$2} END {print s+0}')
FILE_COUNT=$(echo "$CHANGED_FILES" | grep -c . 2>/dev/null || echo "0")
printf '%s\n' "Files: ${FILE_COUNT} | +${ADDITIONS} -${DELETIONS}"

# --- Check 6: Secrets scan ---
printf '\n%s\n' "## Secrets Scan"
SECRET_FILES=""
ALL_FILES=$(echo -e "${CHANGED_FILES}\n${UNTRACKED}" | sort -u)
while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    case "$file" in
        .env|.env.*|*.key|*.pem|credentials*|*secret*|*.p12|*.pfx)
            SECRET_FILES="${SECRET_FILES}${file}\n"
            ;;
    esac
done <<< "$ALL_FILES"

if [[ -n "$SECRET_FILES" ]]; then
    printf '%s\n' "WARNING: Potential secrets detected:"
    printf "$SECRET_FILES"
else
    printf '%s\n' "No secrets detected"
fi

# --- Check 7: Recent commits for style ---
printf '\n%s\n' "## Recent Commit Style"
git log --oneline -5 2>/dev/null || echo "(no commits)"

printf '\n%s\n' "## Diff Preview (first 80 lines)"
printf '%s\n' '```diff'
git diff "${DEFAULT_BRANCH}" 2>/dev/null | head -80
printf '%s\n' '```'
