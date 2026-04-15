# Thinking Models: Architect

Structured reasoning models for the tech stack research and evaluation
phase (Phase 2). Apply when comparing technologies, forming
recommendations, or evaluating trade-offs. Not continuously.

Each model counters a specific bias in technology research.

## 1. Survivorship Bias

**Counters:** Only finding success stories while missing failures
and abandoned projects.

After gathering evidence FOR a recommended technology, actively
search for projects that ABANDONED it:

- Search GitHub issues for "migrated away from", "replaced X with",
  "problems with X at scale"
- Check if major projects have moved away recently
- Look for deprecation notices or maintainer warnings
- Check npm/PyPI download trends — declining adoption is a signal

A technology with 10 blog posts praising it and 100 quiet migrations
away from it looks great until you check the graveyard. Weight
negative evidence (migration stories, deprecation notices, unresolved
issues) MORE heavily than positive — failures are underreported.

## 2. Confirmation Bias Counter

**Counters:** Searching for evidence that confirms your initial
recommendation while ignoring disconfirming evidence.

After forming your initial stack recommendation, spend one research
cycle searching AGAINST it:

- Search: "{technology} problems", "{technology} limitations"
- Search: "why not {technology}", "{technology} vs {competitor}"
- Check GitHub issues sorted by most commented (reveals pain points)

For each piece of disconfirming evidence:
- Either refute it with higher-confidence sources (version fixed it,
  applies to different use case)
- Or add it as a caveat to your recommendation

If you cannot find ANY criticism → your search was too narrow.
Every technology has trade-offs.

## 3. Steel Man

**Counters:** Dismissing alternatives without giving them their
strongest possible case.

Before recommending against a technology the user mentioned or that
appeared in research, construct its STRONGEST possible case:

- What would a passionate advocate say?
- What use cases does it serve better than your recommendation?
- What trade-offs favor it over your pick?

Present the steel-manned alternative alongside your recommendation
with an honest comparison. If the steel-manned alternative is
genuinely competitive for this specific project, say so — don't
force a winner when the choice is close.

---

## When NOT to Think

Skip these models when the situation doesn't benefit from them:

- **User already decided** — if the user said "we're using React"
  in Phase 1, don't run Steel Man on Vue. Research how to use
  React well, not whether React is the right choice.
- **Standard stack lookups** — checking the latest version of a
  library or reading its API docs doesn't need bias correction.
- **Single-technology phases** — if the architecture section involves
  one technology with no alternatives to evaluate (e.g., "add ESLint
  rule"), skip comparative models.
- **Team has deep expertise** — if the user said "we've used Django
  for 5 years," the switching cost outweighs any marginal benefit
  of alternatives. Don't Steel Man a framework migration.
