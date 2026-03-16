---
name: remember
description: >
  Create or update a memory file in ~/memories/ that captures full project context
  for cross-session continuity. Use when user says "remember this", "save context",
  "load context", "what was I working on", or when starting, progressing, or wrapping
  up medium-to-large features. Supports "save" and "load" modes. Do NOT use for
  short-lived tasks or quick one-off questions that don't need cross-session recall.
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Remember — Cross-Session Memory Manager

## Overview

Maintain persistent memory files in `~/memories/` that capture everything about a feature or project: architecture, PRs, design decisions, review history, test status, and next steps. These files serve as the single source of truth that any future session can load to resume work without re-exploring the codebase.

## Invocation

```
/remember <TICKET_ID>              # Save/update (default)
/remember save <TICKET_ID>         # Explicit save
/remember load <TICKET_ID>         # Load context into session
/remember <TICKET_ID> <message>    # Save with specific focus (e.g., "PR2 review done")
```

## Modes

### Save Mode (default)

Creates or updates `~/memories/<TICKET_ID>.md`.

**When creating a NEW memory file:**
1. Gather context from all available sources (see Context Gathering below)
2. Use the template in `assets/memory-template.md` as the structure guide
3. Fill in all sections with current state
4. Write to `~/memories/<TICKET_ID>.md`

**When UPDATING an existing memory file:**
1. Read the existing `~/memories/<TICKET_ID>.md`
2. Gather current context (git state, conversation history, recent changes)
3. Update only the sections that changed — preserve historical content
4. Add new sections if new phases/PRs were started
5. Update status fields, review history, and next steps
6. Never delete information from previous sessions — only append or update status

### Load Mode

Reads `~/memories/<TICKET_ID>.md` into the current session context.

1. Read `~/memories/<TICKET_ID>.md`
2. Present a brief summary to the user:
   - Feature name and overall status
   - Current phase/PR and its status
   - Key pending items or next steps
3. Note any stale information (e.g., "PR2 was IN REVIEW — you may want to check if it's merged")
4. The agent now has full context and can proceed with work

## Context Gathering

When saving, gather information from these sources (in priority order):

### 1. Conversation History (highest priority)
- What was discussed, decided, and implemented in this session
- Code review findings and resolutions
- Design decisions and trade-offs

### 2. Git State
```bash
git log --oneline -20                    # Recent commits
git log --oneline master..HEAD           # Branch commits
git diff master --stat                   # Changed files
git branch --show-current                # Current branch
```

### 3. Existing Context Files
- `PR*_CONTEXT.md` files in the repo or worktrees
- `*PLAN*.md` or `*SPLIT*.md` files
- `.claude/PROGRESS.md` in the project

### 4. GitHub PRs
```bash
gh pr list --state all --search "<feature keywords>" --json number,title,state,mergedAt
gh api repos/<owner>/<repo>/pulls/<number>/reviews   # Review comments
```

### 5. Related Memory Files
- Check `~/memories/` for related tickets
- Check `~/worktrees/` for related worktrees

### 6. Test Files
- Local test results and file locations
- Mock project details if applicable

## Memory File Structure

Follow the template in `assets/memory-template.md`. Key sections:

| Section | Purpose | Required |
|---------|---------|----------|
| Header | Ticket ID, feature title, one-liner | Yes |
| Overview | What the feature does and why | Yes |
| Architecture | How components fit together | Yes for multi-PR |
| Per-PR sections | Status, components, files, decisions, reviews | Yes |
| Testing | Local tests, mock projects, results | If applicable |
| Key Files | Quick reference table | Yes |
| Lessons Learned | Patterns, bugs, techniques | Encouraged |
| Next Steps | Pending work checklist | Yes |
| Cleanup | Worktree/branch cleanup commands | If applicable |

## Quality Guidelines

### DO
- Include exact line numbers for key methods/functions
- Record reviewer names and their specific comments
- Document WHY decisions were made, not just WHAT
- Include file paths that can be directly opened
- Keep PR/phase sections self-contained (readable independently)
- Note deferred items and why they were deferred
- Include git commit hashes for traceability

### DON'T
- Include full code listings (reference by file:line instead)
- Duplicate large amounts of text from other files (link instead)
- Include temporary debugging notes
- Add speculative future plans beyond the next immediate step
- Remove historical information when updating

## Examples

### Creating a new memory
```
User: /remember PROJECT-1234
Agent: [Gathers context from git, conversation, PRs, worktrees]
       [Creates ~/memories/PROJECT-1234.md with full project state]
       "Created memory file for PROJECT-1234. Captured: PR1 (merged), PR2 (in review, 7 methods), PR3 (not started)."
```

### Updating after progress
```
User: /remember PROJECT-1234 PR2 reviewer comments addressed
Agent: [Reads existing memory, gathers new context]
       [Updates PR2 section with review history, new fixes]
       "Updated PROJECT-1234 memory: Added reviewer's comments and resolutions to PR2 section."
```

### Loading at session start
```
User: /remember load PROJECT-1234
Agent: [Reads ~/memories/PROJECT-1234.md]
       "Loaded PROJECT-1234 context:
        - Feature: Multi-Region Topology Support (3 PRs)
        - PR1: MERGED (foundation)
        - PR2: IN REVIEW (core setup, 7 methods, reviewer comments addressed)
        - PR3: NOT STARTED (exporter + test)
        - Next: Push PR2 fixes, wait for merge, then start PR3"
```

## File Naming Convention

- File: `~/memories/<TICKET_ID>.md`
- Use the ticket/issue ID as the filename (e.g., `PROJECT-1234.md`)
- If no ticket ID exists, use a descriptive kebab-case name (e.g., `my-feature.md`)

## Troubleshooting

Error: Memory file not found on load
Cause: No memory file exists for the given ticket ID
Solution: List available files in ~/memories/ and suggest the closest match, or switch to save mode to create one

Error: ~/memories/ directory does not exist
Cause: First time using the skill on this machine
Solution: Create the directory with `mkdir -p ~/memories/` before writing

Error: Stale or outdated memory data
Cause: Memory was saved sessions ago and project state has changed
Solution: On load, cross-reference git state and PR status to flag stale sections, then prompt user to update
