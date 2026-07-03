#!/usr/bin/env bash
set -euo pipefail

# Fetches actionable review feedback for a PR as markdown on stdout:
# unresolved review threads (GraphQL — the REST API cannot filter out
# resolved threads), review summaries, and PR conversation comments.
#
# Usage: fetch-comments.sh <PR_NUMBER|PR_URL>
#   With a bare number, the repo is resolved from the current directory.

PR_INPUT="${1:?Usage: fetch-comments.sh <PR_NUMBER|PR_URL>}"

if [[ "$PR_INPUT" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    PR_NUMBER="${BASH_REMATCH[3]}"
else
    PR_NUMBER="$PR_INPUT"
    NWO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
    OWNER="${NWO%%/*}"
    REPO="${NWO##*/}"
fi

QUERY='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      title
      url
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          path
          line
          comments(first: 30) {
            nodes { author { login } body }
          }
        }
      }
      reviews(first: 50) {
        nodes { author { login } state body }
      }
      comments(first: 50) {
        nodes { author { login } body }
      }
    }
  }
}'

DATA=$(gh api graphql -f query="$QUERY" -F owner="$OWNER" -F repo="$REPO" -F pr="$PR_NUMBER")

echo "$DATA" | jq -r '
  .data.repository.pullRequest as $pr |
  ($pr.reviewThreads.nodes | map(select(.isResolved))) as $resolved |
  ($pr.reviewThreads.nodes | map(select(.isResolved | not))) as $open |

  "# Review Feedback: \($pr.title)",
  "\($pr.url)",
  "",
  "## Unresolved Review Threads (\($open | length) open, \($resolved | length) resolved omitted)",
  "",
  ( $open | to_entries[] |
    "### \(.key + 1). \(.value.path // "general"):\(.value.line // "-")\(if .value.isOutdated then "  [outdated]" else "" end)",
    ( .value.comments.nodes[] | "- **@\(.author.login // "unknown")**: \(.body | gsub("\r"; ""))" ),
    ""
  ),
  "## Review Summaries",
  "",
  ( $pr.reviews.nodes[] | select((.body // "") != "") |
    "- **@\(.author.login // "unknown")** [\(.state)]: \(.body | gsub("\r"; ""))"
  ),
  "",
  "## PR Conversation Comments",
  "",
  ( $pr.comments.nodes[] |
    "- **@\(.author.login // "unknown")**: \(.body | gsub("\r"; ""))"
  )
'
