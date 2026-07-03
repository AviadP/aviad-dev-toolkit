---
name: discover
description: >
  Uncover and document requirements for a project or feature through progressive
  discovery. Produces a structured requirements document. Use when the user wants
  to: (1) define what to build before designing architecture, (2) create a requirements
  doc or PRD, (3) scope a new feature or project, (4) clarify what a project needs
  before implementation. Trigger on: /discover command, or when the user asks to
  "define requirements", "what should we build", "scope this feature", "create a PRD",
  "requirements for this project", or similar discovery requests. Do NOT use for
  architecture design (use /architect), code review, or debugging.
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Requirements Discovery

Uncover what needs to be built through structured, progressive questioning.
Focus on the WHAT and WHY — leave the HOW to /architect.

## Iron Law

**NO REQUIREMENTS WITHOUT EVIDENCE.** Every requirement in the output document
must trace back to something the user explicitly stated or confirmed. Do not
invent requirements, assume features, or add scope the user didn't ask for.

## Entry Gates

Before starting discovery, verify:

1. **User has a goal** — they must have at least a rough idea of what they
   want to build. If they have nothing ("I want to build something"), help
   them brainstorm direction first, then restart discovery once there's a
   concrete goal.
2. **Scope is assessable** — you can tell whether this is one project or
   multiple. If unclear, that's your first question.

## Workflow

Execute these phases sequentially. Get user approval before advancing.

### Phase 1: Context & Scope

1. Read the user's initial description carefully
2. Check existing project state if applicable (files, docs, recent commits)
3. **Scope check** — is this one project or multiple independent subsystems?
   - If multiple: help decompose into sub-projects, define relationships
     and build order. Run discovery on the first sub-project.
   - If one: proceed to Phase 2

### Phase 2: Progressive Discovery

Ask questions in small, adaptive rounds to build understanding. Start broad,
go deep where complexity lives.

**Question flow — adapt, don't checklist-walk:**

Start with the core: "What problem are you solving, and for whom?"

Then explore based on what the answers reveal:

**Problem & Users**
- What's the pain point today? What happens if this doesn't get built?
- Who are the target users? (roles, volume, technical level)
- Are there different user types with different needs?

**Success & Value**
- How will you know this is working? What changes for users?
- What's the minimum viable version? What can wait for later?
- Are there measurable outcomes? (metrics, KPIs, adoption targets)

**Behavior & Flows**
- Walk me through the main user journey, step by step
- What are the critical decision points in the flow?
- What happens when things go wrong? (error states, edge cases)

**Constraints & Context**
- Timeline and budget? Team size and skills?
- Technology mandates or restrictions?
- Compliance requirements? (GDPR, HIPAA, SOC 2, PCI DSS)
- Integrating with existing systems or greenfield?
- What external dependencies exist? (APIs, services, data sources)

**Scale & Performance**
- Expected user volume? Data volume? Growth projections?
- Real-time requirements? (chat, notifications, live updates)
- Availability and latency expectations?

**Rules for questioning:**
- **Small batches via AskUserQuestion.** Group 2-4 tightly related questions
  per round (the tool renders them cleanly) — never dump all categories at
  once. Each round's answers shape the next round.
- **Multiple choice when possible** — easier to answer than open-ended.
- **Skip what's answered** — if the initial description covers it, don't re-ask.
- **Progressive depth** — start broad, dig deeper only where answers reveal
  complexity or ambiguity. If a topic is clear, move on.
- **Stop when you have enough** — not every category needs deep exploration.
  A simple feature might need 4-5 questions total. Don't over-question.

### Phase 3: Approach Exploration

Before locking in direction:

1. Propose 2-3 different approaches to solving the problem
2. For each: what it includes, trade-offs, who it's best for
3. Give your recommendation with clear rationale
4. Get user alignment on direction

This is about WHAT to build, not HOW to build it (that's architect's job).
Approaches here are about product scope and strategy, not tech stack.

### Phase 4: Requirements Document

1. Read `assets/requirements-template.md`
2. Compile all confirmed requirements into the template
3. Fill every section — no placeholders, no TBDs
4. **Self-review** before presenting:
   - **Placeholder scan** — any "TBD", "TODO", vague language?
   - **Consistency check** — do sections contradict each other?
   - **Scope check** — does this match what the user asked for? (apply YAGNI)
   - **Ambiguity check** — could any requirement be read two ways?
   - **Traceability check** — can every requirement trace to something the user said?
   Fix issues inline, then present to the user.
5. Ask the user to review the document
6. Incorporate feedback and finalize
7. Save to a location specified by the user (or suggest a sensible default)

### Phase 5: Handoff

After the requirements doc is approved:

- If the project needs architecture: suggest running `/architect` next.
  The architect skill will detect the requirements doc and use it as input,
  skipping its own requirements intake phase.
- If the project is small enough to implement directly: suggest next steps
  (e.g., /test-plan, /design-validator, or direct implementation).
- Do NOT start implementation. This skill produces documentation only.

## Guidelines

- **YAGNI ruthlessly** — if the user didn't ask for it, don't add it
- **Depth matches complexity** — a simple CRUD feature gets a short doc;
  a multi-tenant SaaS platform gets a detailed one
- **Product language, not tech language** — write requirements as behaviors
  and outcomes, not implementation details. "Users can reset their password
  via email" not "Implement password reset endpoint with SMTP integration"
- **Scope boundaries are critical** — explicitly document what's OUT of scope.
  This prevents scope creep later and gives architect clear boundaries.
- **Don't solve architecture problems** — if the user asks "should we use
  PostgreSQL or MongoDB?", redirect: "That's an architecture decision —
  let's first nail down what data you need to store and how it's accessed.
  /architect will handle the technology choice."

## Examples

### Example 1: New SaaS Feature
User says: "I want to add team collaboration to our project management tool"
Actions:
1. Phase 1 — Check existing project, confirm single feature scope
2. Phase 2 — Discover: who collaborates, how, real-time needs, permissions
3. Phase 3 — Propose: basic sharing vs. real-time co-editing vs. comment-based
4. Phase 4 — Write requirements doc with user flows, scope, constraints
5. Phase 5 — Suggest /architect for system design
Result: Requirements document ready for architecture planning

### Example 2: Small Feature
User says: "I need a password reset flow"
Actions:
1. Phase 1 — Check existing auth system
2. Phase 2 — Quick discovery: email or SMS? Expiry? Rate limiting?
3. Phase 3 — Skip (straightforward, one clear approach)
4. Phase 4 — Short requirements doc (1 page)
5. Phase 5 — Small enough to implement directly, suggest /test-plan
Result: Concise requirements doc, no architecture needed

### Example 3: Vague Request
User says: "I want to build something with AI"
Actions:
1. Phase 1 — No clear goal yet, help brainstorm direction first
2. Guide toward a concrete problem to solve
3. Restart discovery once there's a clear goal
Result: User has clarity before requirements gathering begins

## Troubleshooting

Error: User provides extremely detailed technical requirements upfront
Cause: User may have already done discovery and wants architecture
Solution: Acknowledge the work, suggest /architect directly. Offer to
formalize their requirements into a doc if they want one.

Error: User keeps adding scope during discovery
Cause: Excited about possibilities, not focused yet
Solution: Capture everything, then in Phase 3 explicitly prioritize.
Use the "minimum viable version" question to force focus.

Error: User can't answer "what problem does this solve?"
Cause: Solution-first thinking (they know WHAT they want but not WHY)
Solution: Don't block on this. Ask about the user journey instead —
the problem statement often emerges from describing the workflow.
