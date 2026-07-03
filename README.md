# Aviad Dev Toolkit

Development quality toolkit for Claude Code — requirements discovery,
architecture planning, PR review, bug hunting, code quality review, security
review, refactoring, debugging, test planning, cross-session memory, and git
shipping.

## Components

### Skills (16)
| Skill | Description |
|-------|-------------|
| architect | Web app architecture blueprint generator |
| bug-hunt | Adaptive bug detection (quick/deep) with validation and kill gate |
| code-quality | Parallel multi-agent code quality review |
| debug | Systematic root cause investigation |
| discover | Progressive requirements discovery and documentation |
| design-validator | Plan validation before implementation |
| gate | Pre-ship quality gate with go/no-go report |
| refactor | Two-phase code analysis and refactoring |
| remember | Cross-session memory management |
| review-pr | PR review with adaptive depth (quick/deep) and kill-gate validation |
| review-response | Handle incoming code review feedback |
| risk-assess | Risk and blast-radius assessment for proposed changes |
| secure-plan | Security review for plans/designs, adaptive depth (single-pass / --deep 3-agent) |
| ship-it | Git branch-to-main shipping workflow |
| test-plan | Structured test plan generation |
| verify | Post-implementation intent adherence scoring |

### Agents (5)
| Agent | Description |
|-------|-------------|
| branch-code-simplifier | Simplify branch changes vs the default branch |
| code-best-practices-reviewer | Best practices compliance review |
| code-cleanup-post-dev | Remove debug logs, unused imports |
| dead-code-detector | Find unused/duplicate code |
| secure-code-reviewer | Security vulnerability scanner for code |

### Shared infrastructure
| Path | Purpose |
|------|---------|
| `scripts/git-scope.sh` | Default-branch detection + diff/file-list generation for bug-hunt, code-quality, gate, and risk-assess |
| `scripts/check-deps.sh` | Dependency CVE + freshness lookup (OSV.dev, PyPI, npm) for secure-plan and review-pr |
| `shared/thinking-models.md` | Validation reasoning models used by bug-hunt and review-pr kill gates |

## Installation

### Via Marketplace (recommended — enables auto-updates)
```
/plugin marketplace add AviadP/aviad-plugin-marketplace
/plugin install aviad-dev-toolkit@aviad-plugin-marketplace
```

### Direct from GitHub
```
claude plugin add AviadP/my-claude-skills
```

### Manual (legacy)
```bash
git clone git@github.com:AviadP/my-claude-skills.git ~/my_claude_skills
# Then symlink skills/ and agents/ to ~/.claude/
```
