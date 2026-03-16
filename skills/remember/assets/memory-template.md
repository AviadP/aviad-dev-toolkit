# {TICKET_ID}: {FEATURE_TITLE}

{One-line description of the feature/project.}
{Optional: Links to plan docs, progress docs, or related resources.}

---

## Overview

{2-3 sentences explaining the feature, why it exists, and its scope.}

## Architecture

{Architecture diagram or component map showing how pieces fit together.
Use ASCII art, tables, or plain text — whatever fits the project.
Label each component with its origin (PR/phase).}

---

## {Phase/PR 1}: {Title} — {STATUS}

| Field | Value |
|-------|-------|
| Branch | `{branch_name}` |
| PR | [#{number}]({url}) |
| Status | **{MERGED/IN REVIEW/IN PROGRESS/NOT STARTED}** |
| Commit(s) | `{hash}` |

### What it does
{Brief description of what this phase adds.}

### Components added
{List of classes, methods, functions, or files added with 1-line descriptions.}

### Files modified
| File | Changes |
|------|---------|
| `path/to/file` | {+N lines, description} |

### Design decisions
{Key choices made and why. Include alternatives considered if relevant.}

### Review history
{Reviewer comments, what was applied, what was deferred, and why.}

---

## {Phase/PR N}: {Title} — {STATUS}

{Repeat the same structure for each phase/PR.}

---

## Testing

{Local test setup, mock projects, test results.
Include file paths and how to run them.}

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `path/to/file` | {description} |

---

## Lessons Learned

{Patterns discovered, bugs encountered, useful techniques.
These help future sessions avoid repeating mistakes.}

---

## Next Steps / Pending Work

{What remains to be done. Checklist format preferred.}

---

## Cleanup

{Commands or steps to clean up worktrees, branches, temp files after completion.}
