#!/usr/bin/env bash
set -euo pipefail

# Gate preflight — git scope (via shared git-scope.sh) + environment checks.
# Output: structured report to stdout. Exits 1 if there is nothing to gate.
#
# Scope files written by git-scope.sh:
#   /tmp/gate-diff.txt   full diff vs merge-base (untracked included)
#   /tmp/gate-files.txt  changed file list

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
GIT_SCOPE="${SCRIPT_DIR}/../../../scripts/git-scope.sh"

printf '%s\n' "# Gate Preflight Report"
printf '\n'

# --- Git scope: default branch, merge-base diff, file list ---
printf '%s\n' "## Git Scope"
SCOPE_OUTPUT=$(bash "$GIT_SCOPE" gate)
printf '%s\n' "$SCOPE_OUTPUT"

if grep -q "No changes found" <<< "$SCOPE_OUTPUT"; then
    printf '\n%s\n' "Nothing to gate."
    exit 1
fi

printf '\n%s\n' "## Changed Files"
cat /tmp/gate-files.txt

# --- Venv status ---
printf '\n%s\n' "## Virtual Environment"
if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    printf '%s\n' "Active: ${VIRTUAL_ENV}"
else
    printf '%s\n' "WARNING: No virtual environment active"
    if [[ -f ".venv/bin/activate" ]]; then
        printf '%s\n' "Hint: .venv found — source .venv/bin/activate"
    fi
fi

# --- Secrets scan 1: sensitive filenames ---
printf '\n%s\n' "## Secrets Scan"
SECRET_FILES=""
while IFS= read -r file; do
    file="${file%"  [untracked]"}"
    [[ -z "$file" ]] && continue
    case "$file" in
        .env|.env.*|*.key|*.pem|credentials*|*secret*|*.p12|*.pfx)
            SECRET_FILES="${SECRET_FILES}  - ${file}"$'\n'
            ;;
    esac
done < /tmp/gate-files.txt

# --- Secrets scan 2: hardcoded credentials in added lines ---
# Flags added lines that assign a quoted literal (8+ chars) to a
# key/password-style variable name
SECRET_PATTERN="^\+.*(api[_-]?key|apikey|password|passwd|secret|token)[^=:]{0,3}[:=][[:space:]]*['\"][^'\"]{8,}"
SECRET_LINES=$(grep -inE "$SECRET_PATTERN" /tmp/gate-diff.txt | head -10 || true)

if [[ -n "$SECRET_FILES" || -n "$SECRET_LINES" ]]; then
    printf '%s\n' "WARNING: Potential secrets detected:"
    if [[ -n "$SECRET_FILES" ]]; then
        printf '%s\n' "Sensitive filenames:"
        printf '%s' "$SECRET_FILES"
    fi
    if [[ -n "$SECRET_LINES" ]]; then
        printf '%s\n' "Added lines that look like hardcoded credentials (diff-file line numbers):"
        printf '%s\n' "$SECRET_LINES"
    fi
else
    printf '%s\n' "No secrets detected"
fi

# --- Recent commits for style ---
printf '\n%s\n' "## Recent Commit Style"
git log --oneline -5 2>/dev/null || echo "(no commits)"
