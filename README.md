# Aviad Dev Toolkit

Development quality toolkit for Claude Code — architecture planning,
code quality review, security review, refactoring, cross-session memory, and git shipping.

## Components

### Skills (7)
| Skill | Description |
|-------|-------------|
| architect | Web app architecture blueprint generator |
| design-validator | Plan validation before implementation |
| secure-plan | Security vulnerability review for plans and designs |
| code-quality | Parallel multi-agent code quality review |
| ship-it | Git branch-to-main shipping workflow |
| refactor | Two-phase code analysis and refactoring |
| remember | Cross-session memory management |

### Agents (5)
| Agent | Description |
|-------|-------------|
| branch-code-simplifier | Simplify branch changes vs master |
| code-best-practices-reviewer | Best practices compliance review |
| code-cleanup-post-dev | Remove debug logs, unused imports |
| dead-code-detector | Find unused/duplicate code |
| secure-code-reviewer | Security vulnerability scanner for code |

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
