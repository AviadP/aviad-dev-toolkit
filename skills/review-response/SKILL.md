---
name: review-response
description: >
  Handle incoming code review feedback on your PR with technical rigor.
  Verifies reviewer suggestions against the codebase before implementing,
  pushes back when feedback is incorrect, and avoids performative agreement.
  Use when user says "address review comments", "handle PR feedback",
  "respond to review", "fix review comments", or receives code review
  feedback to act on.
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Review Response — Handle Incoming Code Review Feedback

## Overview

When someone reviews your PR, evaluate their feedback with technical rigor
before acting on it. This skill prevents blind implementation of incorrect
suggestions and ensures every change is verified against codebase reality.

This fills the gap between reviewing others' code (code-quality, code-review)
and verifying your own work (verify). Those skills ask "is this code good?"
This skill asks: **"is this feedback correct, and should I implement it?"**

## Invocation

```
/review-response                    # Prompt for PR number or feedback source
/review-response <pr-number>        # Fetch comments from GitHub PR
/review-response <feedback>         # Handle pasted feedback
```

## Iron Law

**NO IMPLEMENTATION WITHOUT VERIFICATION.** Every reviewer suggestion must
be checked against the codebase before implementing. Reviewer feedback is
input to evaluate, not orders to execute.

## Entry Gates

Before the workflow can execute, verify:

1. **Feedback exists** — the user must provide review feedback from one of:
   - A GitHub PR number (fetched via `gh pr view` and `gh api`)
   - Pasted review comments
   - Feedback described in conversation
   If no feedback source is available, stop: "I need review feedback to
   respond to. Provide a PR number, paste the comments, or describe them."
2. **Code exists** — there must be code that was reviewed. Identify the
   branch and changed files via `git diff`.
3. **Feedback is actionable** — at least one comment requests a change,
   asks a question, or flags an issue. If all comments are approvals
   with no action items, stop: "All review comments are approvals. Nothing
   to address."

## Workflow

### Step 1: Gather All Feedback

Collect all review comments and organize them:

- For GitHub PRs: use `gh api repos/{owner}/{repo}/pulls/{number}/comments`
  and `gh api repos/{owner}/{repo}/pulls/{number}/reviews`
- Group by file and line number
- Identify the reviewer for each comment
- Note which comments are threads vs standalone

Present the gathered feedback:

```
Found X review comments from Y reviewer(s):

1. [file.py:42] "Consider using a set instead of list for lookups" — @reviewer
2. [file.py:78] "This could raise KeyError" — @reviewer
3. [General] "Why not use the existing helper?" — @reviewer

Proceeding with verification.
```

### Step 2: Classify Each Comment

For each comment, classify as:

- **Bug/Error** — reviewer found a real defect
- **Suggestion** — reviewer proposes a different approach
- **Question** — reviewer needs clarification
- **Style** — formatting, naming, convention preference
- **Scope** — reviewer wants additional functionality beyond PR scope

### Step 3: Verify Against Codebase

For each Bug/Error and Suggestion comment, verify before implementing:

1. **Is it technically correct?**
   - Read the code the reviewer references
   - Does the issue they describe actually exist?
   - Grep for evidence supporting or refuting their claim

2. **Does the suggestion break functionality?**
   - Trace the impact of the proposed change
   - Check if other code depends on current behavior
   - Look for tests that would break

3. **Is there a reason for the current implementation?**
   - Check git blame for context on why code was written this way
   - Read surrounding comments or docstrings
   - Check if it matches existing codebase patterns (Grep)

4. **YAGNI check (for "implement properly" suggestions)**
   - Grep codebase for actual usage of the code in question
   - If unused or single-use, suggest removal over refactoring
   - If widely used, the suggestion may have merit

5. **Does the reviewer have full context?**
   - Check if the reviewer understands the PR's intent
   - Look for constraints they may not be aware of

### Step 4: Decide Action for Each Comment

Present verification results and recommended action:

```
## Review Feedback Analysis

| # | File | Type | Verdict | Action |
|---|------|------|---------|--------|
| 1 | file.py:42 | Suggestion | ✅ Valid | Implement — set lookup is O(1) vs O(n) |
| 2 | file.py:78 | Bug | ❌ Invalid | Push back — key is guaranteed by line 65 |
| 3 | General | Question | ❓ Clarify | Respond — explain design choice |
| 4 | file.py:90 | Suggestion | ⚠️ Partial | Discuss — valid idea but breaks API |
| 5 | file.py:12 | Scope | 🚫 Out of scope | Defer — not part of this PR |

Proceed with implementing valid items?
```

**STOP and wait for user confirmation.**

### Step 5: Implement Accepted Changes

After user confirms which items to implement:

1. **Order:** Bug fixes first → Simple suggestions → Complex changes
2. **One at a time:** Implement each change separately, verify it works
3. **Test after each:** Run relevant tests to confirm no regression
4. **Track:** Mark each item as done

### Step 6: Draft Responses

For each comment, draft a reply:

**For implemented changes:**
```
Fixed. Changed to set for O(1) lookups.
```

**For rejected suggestions (push back):**
```
The key is guaranteed to exist — it's set on line 65 by
`_init_mapping()` which runs before this method is called.
No KeyError is possible here.
```

**For questions:**
```
This approach was chosen because [specific reason].
[Link to relevant code or docs if helpful].
```

**For out-of-scope items:**
```
Good idea — tracking this separately in [ticket/issue].
Keeping this PR focused on [original scope].
```

Present all drafted responses for user approval before posting.

## Exit Gates

Before declaring review response complete:

1. **All comments addressed** — every comment has a verdict (implement,
   push back, clarify, or defer)
2. **Implementations verified** — each implemented change passes tests
3. **Responses drafted** — reply text ready for every comment
4. **User approved** — user has reviewed all responses before posting

## Red Flags

These thoughts mean you're skipping verification:

| Thought | Reality |
|---------|---------|
| "The reviewer is probably right" | Verify. Reviewers miss context. |
| "I'll just implement it quickly" | Quick implementation of wrong feedback wastes more time |
| "This is a senior reviewer" | Seniority ≠ correctness on this specific code |
| "It's a small change, no need to check" | Small changes break things too |
| "I don't want to push back" | Incorrect code is worse than an awkward conversation |
| "They must know something I don't" | Check. Often they don't have full context |

## Communication Guidelines

- **No performative agreement** — never say "Great point!", "You're absolutely
  right!", or "Thanks for catching this!" followed by blind implementation
- **Be direct** — "Fixed." or "This isn't an issue because [evidence]"
- **Evidence over opinion** — cite file:line, not "I think..."
- **Acknowledge valid catches** — "Good catch — [specific issue]. Fixed."
- **Disagree with evidence** — when pushing back, show why with code references

## Examples

### Example 1: Handle GitHub PR comments

```
User: /review-response 1234

Agent: [Fetches comments via gh api]
       [Classifies 5 comments: 2 bugs, 2 suggestions, 1 question]
       [Verifies each against codebase]
       [Finding: 1 bug valid, 1 bug invalid, both suggestions valid, question needs answer]
       [Presents analysis table]
       [User approves: implement valid items, push back on invalid bug]
       [Implements 3 changes, drafts 5 responses]
       [User reviews and approves responses]
```

### Example 2: Handle pasted feedback

```
User: Reviewer said "you should add error handling for the API call on line 45"

Agent: [Reads line 45 and surrounding context]
       [Finds: the API call is already wrapped in a retry decorator that handles errors]
       [Verdict: Invalid — error handling already exists via @retry decorator on line 40]
       [Drafts push-back response with evidence]
```
