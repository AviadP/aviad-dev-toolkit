#!/usr/bin/env bash
set -euo pipefail

# Prepares PR review workspace and validates PR purpose.
# Handles Phase 1 of the review-pr skill: clone, checkout, diff, project
# context, purpose validation, and mode recommendation.
#
# Usage: setup.sh <PR_NUMBER|PR_URL>
#        setup.sh --cleanup
#
# Output: /tmp/pr-review-context.md (structured context for the skill)

if [[ "${1:-}" == "--cleanup" ]]; then
    rm -rf /tmp/pr-review-*/
    rm -f /tmp/pr-review-diff.txt /tmp/pr-review-stat.txt /tmp/pr-review-context.md
    echo "Cleaned up PR review workspace."
    exit 0
fi

PR_INPUT="${1:?Usage: setup.sh <PR_NUMBER|PR_URL>}"

# --- Parse input ---
if [[ "$PR_INPUT" =~ github\.com/([^/]+/[^/]+)/pull/([0-9]+) ]]; then
    REPO="${BASH_REMATCH[1]}"
    PR_NUMBER="${BASH_REMATCH[2]}"
else
    PR_NUMBER="$PR_INPUT"
    # Resolve the BASE repo from the PR URL — headRepository would be the
    # fork on cross-repo PRs, and PR numbers belong to the base repo.
    RESOLVED_URL=$(gh pr view "$PR_NUMBER" --json url --jq '.url')
    if [[ "$RESOLVED_URL" =~ github\.com/([^/]+/[^/]+)/pull/ ]]; then
        REPO="${BASH_REMATCH[1]}"
    else
        echo "ERROR: could not resolve repository for PR #${PR_NUMBER}" >&2
        exit 1
    fi
fi

DEFAULT_BRANCH=$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)

# --- Fetch PR metadata ---
PR_META=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json title,body,labels,additions,deletions,changedFiles,url)
TITLE=$(echo "$PR_META" | jq -r '.title')
BODY=$(echo "$PR_META" | jq -r '.body // ""')
LABELS=$(echo "$PR_META" | jq -r '[.labels[].name] | join(", ")')
ADDITIONS=$(echo "$PR_META" | jq -r '.additions')
DELETIONS=$(echo "$PR_META" | jq -r '.deletions')
CHANGED_FILES=$(echo "$PR_META" | jq -r '.changedFiles')
PR_URL=$(echo "$PR_META" | jq -r '.url')

# --- Clone and checkout ---
WORK_DIR="/tmp/pr-review-${REPO##*/}-${PR_NUMBER}"
rm -rf "$WORK_DIR"
git clone --depth=100 "https://github.com/${REPO}.git" "$WORK_DIR" 2>/dev/null
cd "$WORK_DIR"
gh pr checkout "$PR_NUMBER" --repo "$REPO" 2>/dev/null

# --- Compute diff (deepen if the shallow clone lacks the merge-base) ---
if ! git diff "${DEFAULT_BRANCH}...HEAD" > /tmp/pr-review-diff.txt 2>/dev/null; then
    git fetch --deepen=1000 origin "$DEFAULT_BRANCH" 2>/dev/null || true
    git diff "${DEFAULT_BRANCH}...HEAD" > /tmp/pr-review-diff.txt
fi
git diff "${DEFAULT_BRANCH}...HEAD" --stat > /tmp/pr-review-stat.txt

# --- Load project context ---
RULES_STATUS="not found"
REVIEW_RULES=""
for rules_path in ".claude/review-rules.md" "review-rules.md"; do
    if [[ -f "$rules_path" ]]; then
        REVIEW_RULES=$(<"$rules_path")
        RULES_STATUS="loaded"
        break
    fi
done

CONVENTIONS_STATUS="not found"
PROJECT_CONVENTIONS=""
for conventions_path in "CLAUDE.md" ".claude/CLAUDE.md"; do
    if [[ -f "$conventions_path" ]]; then
        PROJECT_CONVENTIONS=$(<"$conventions_path")
        CONVENTIONS_STATUS="loaded (${conventions_path})"
        break
    fi
done

# --- Purpose validation ---
TITLE_QUALITY="PASS"
TITLE_LOWER=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')
WORD_COUNT=$(echo "$TITLE" | wc -w | tr -d ' ')
if [[ "$WORD_COUNT" -le 1 ]]; then
    TITLE_QUALITY="FAIL"
fi
for bad in fix update changes wip misc stuff test temp todo; do
    if [[ "$TITLE_LOWER" == "$bad" ]]; then
        TITLE_QUALITY="FAIL"
        break
    fi
done

DESC_QUALITY="PASS"
if [[ -z "$(echo "$BODY" | tr -d '[:space:]')" ]]; then
    DESC_QUALITY="FAIL"
fi

ISSUE_LINKED="NOT FOUND"
COMBINED="$BODY $TITLE"
if echo "$COMBINED" | grep -qE '#[0-9]+' 2>/dev/null; then
    ISSUE_LINKED="PASS"
elif echo "$COMBINED" | grep -qE '[A-Z]{2,}-[0-9]+' 2>/dev/null; then
    ISSUE_LINKED="PASS"
elif echo "$BODY" | grep -qE 'github\.com/.+/issues/[0-9]+' 2>/dev/null; then
    ISSUE_LINKED="PASS"
fi

PURPOSE_SEVERITY="PASS"
PURPOSE_FINDING=""
if [[ "$TITLE_QUALITY" == "FAIL" && "$DESC_QUALITY" == "FAIL" && "$ISSUE_LINKED" == "NOT FOUND" ]]; then
    PURPOSE_SEVERITY="BLOCKER"
    PURPOSE_FINDING="No meaningful title, no description, and no issue link. Cannot determine PR intent."
elif [[ "$TITLE_QUALITY" == "FAIL" && "$DESC_QUALITY" == "FAIL" ]]; then
    PURPOSE_SEVERITY="HIGH"
    PURPOSE_FINDING="Vague title and no description. PR purpose is unclear."
elif [[ "$DESC_QUALITY" == "FAIL" ]]; then
    PURPOSE_SEVERITY="MEDIUM"
    PURPOSE_FINDING="No PR description provided."
fi

# --- Recommended review mode ---
TOTAL_CHANGES=$((ADDITIONS + DELETIONS))
RECOMMENDED_MODE="deep"
if [[ "$TOTAL_CHANGES" -lt 200 && "$CHANGED_FILES" -le 10 ]]; then
    RECOMMENDED_MODE="quick"
fi

# --- Generate output ---
OUTPUT="/tmp/pr-review-context.md"
{
    printf '%s\n' "# PR Review Context"
    printf '\n'
    printf '%s\n' "## PR Metadata"
    printf '%s\n' "- **PR:** #${PR_NUMBER}"
    printf '%s\n' "- **Title:** ${TITLE}"
    printf '%s\n' "- **URL:** ${PR_URL}"
    printf '%s\n' "- **Repository:** ${REPO}"
    printf '%s\n' "- **Base branch:** ${DEFAULT_BRANCH}"
    printf '%s\n' "- **Files changed:** ${CHANGED_FILES} (+${ADDITIONS}, -${DELETIONS})"
    printf '%s\n' "- **Labels:** ${LABELS:-none}"
    printf '%s\n' "- **Review rules:** ${RULES_STATUS}"
    printf '%s\n' "- **Project conventions:** ${CONVENTIONS_STATUS}"

    printf '\n'
    printf '%s\n' "## PR Description"
    if [[ -n "$(echo "$BODY" | tr -d '[:space:]')" ]]; then
        printf '%s\n' "$BODY"
    else
        printf '%s\n' "(empty)"
    fi

    printf '\n'
    printf '%s\n' "## Purpose Validation"
    printf '%s\n' "- **Title quality:** ${TITLE_QUALITY}"
    printf '%s\n' "- **Description:** ${DESC_QUALITY}"
    printf '%s\n' "- **Issue linkage:** ${ISSUE_LINKED}"
    printf '%s\n' "- **Severity:** ${PURPOSE_SEVERITY}"
    if [[ -n "$PURPOSE_FINDING" ]]; then
        printf '%s\n' "- **Finding:** ${PURPOSE_FINDING}"
    fi

    printf '\n'
    printf '%s\n' "## Recommended Mode"
    printf '%s\n' "${RECOMMENDED_MODE} (${TOTAL_CHANGES} lines changed across ${CHANGED_FILES} files)"

    printf '\n'
    printf '%s\n' "## Working Directory"
    printf '%s\n' "$WORK_DIR"

    printf '\n'
    printf '%s\n' "## Diff Stats"
    cat /tmp/pr-review-stat.txt

    if [[ -n "$REVIEW_RULES" ]]; then
        printf '\n'
        printf '%s\n' "## Review Rules"
        printf '%s\n' "$REVIEW_RULES"
    fi

    if [[ -n "$PROJECT_CONVENTIONS" ]]; then
        printf '\n'
        printf '%s\n' "## Project Conventions"
        printf '%s\n' "$PROJECT_CONVENTIONS"
    fi
} > "$OUTPUT"

# Large PR warning
if [[ $((ADDITIONS + DELETIONS)) -gt 1000 ]]; then
    printf '%s\n' ""
    printf '%s\n' "Warning: Large PR (${ADDITIONS}+ / ${DELETIONS}-) — deep mode will use significant tokens."
fi

printf '%s\n' "Context written to ${OUTPUT}"
printf '%s\n' "Workspace: ${WORK_DIR}"
