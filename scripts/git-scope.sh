#!/usr/bin/env bash
set -euo pipefail

# Shared branch-scope resolver for review skills (bug-hunt, code-quality).
# Detects the default branch, diffs the working tree against the merge-base
# (branch commits + uncommitted changes, no upstream noise), and writes scope
# files that agents read instead of re-running git themselves.
#
# Usage: git-scope.sh <prefix>
#   e.g. git-scope.sh bug-hunt → /tmp/bug-hunt-diff.txt, /tmp/bug-hunt-files.txt
#
# stdout: summary (default branch, counts, recommended review mode)

PREFIX="${1:?Usage: git-scope.sh <prefix>  (e.g. bug-hunt, code-quality)}"
DIFF_FILE="/tmp/${PREFIX}-diff.txt"
FILES_FILE="/tmp/${PREFIX}-files.txt"

# --- Detect default branch: origin/HEAD → main → master ---
DEFAULT_BRANCH=""
if REF=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null); then
    DEFAULT_BRANCH="${REF#origin/}"
    # No local branch of that name (e.g., PR branch checked out directly) —
    # use the remote-tracking ref as the diff base instead
    if ! git show-ref --verify --quiet "refs/heads/${DEFAULT_BRANCH}"; then
        DEFAULT_BRANCH="$REF"
    fi
else
    for candidate in main master; do
        if git show-ref --verify --quiet "refs/heads/${candidate}"; then
            DEFAULT_BRANCH="$candidate"
            break
        fi
    done
fi

if [[ -z "$DEFAULT_BRANCH" ]]; then
    echo "ERROR: could not detect default branch (no origin/HEAD, main, or master)" >&2
    exit 1
fi

# --- Diff working tree against merge-base ---
MERGE_BASE=$(git merge-base "$DEFAULT_BRANCH" HEAD)
git diff "$MERGE_BASE" > "$DIFF_FILE"

# Append untracked files as new-file diffs so the diff is self-contained
while IFS= read -r f; do
    git diff --no-index -- /dev/null "$f" >> "$DIFF_FILE" || true
done < <(git ls-files --others --exclude-standard)

# --- File list (untracked marked) ---
{
    git diff "$MERGE_BASE" --name-only
    git ls-files --others --exclude-standard | sed 's/$/  [untracked]/'
} > "$FILES_FILE"

TRACKED=$(git diff "$MERGE_BASE" --name-only | grep -c '' || true)
UNTRACKED=$(git ls-files --others --exclude-standard | grep -c '' || true)

# Changed lines = +/- lines in the diff, excluding +++/--- file headers
ADD_DEL=$(grep -c '^[+-]' "$DIFF_FILE" || true)
HEADERS=$(grep -cE '^(\+\+\+|---) ' "$DIFF_FILE" || true)
CHANGED_LINES=$((ADD_DEL - HEADERS))

RECOMMENDED_MODE="deep"
if [[ "$CHANGED_LINES" -lt 200 ]]; then
    RECOMMENDED_MODE="quick"
fi

echo "Default branch: ${DEFAULT_BRANCH} (merge-base $(git rev-parse --short "$MERGE_BASE"))"
echo "Current branch: $(git branch --show-current)"
echo "Changed files: ${TRACKED} tracked + ${UNTRACKED} untracked"
echo "Changed lines: ${CHANGED_LINES}"
echo "Diff file: ${DIFF_FILE}"
echo "File list: ${FILES_FILE}"
echo "Recommended mode: ${RECOMMENDED_MODE}"

if [[ "$CHANGED_LINES" -eq 0 ]]; then
    echo "No changes found — nothing to review."
elif [[ "$CHANGED_LINES" -gt 5000 ]]; then
    echo "Warning: very large diff — consider scoping to specific files."
fi
