# Review Rules

Rules listed here are **BLOCKER-level** — any violation in a PR is automatically
flagged as 🔴 BLOCKER regardless of what the reviewer would otherwise rate it.

Place this file at `<repo>/review-rules.md` or `<repo>/.claude/review-rules.md`.

## Rules

1. All database queries MUST use parameterized statements
2. No secrets or credentials in code or logs
3. All new public functions MUST have type hints
4. Never use `except Exception` — always use specific exceptions
