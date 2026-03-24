---
name: khali-shared-conventions
description: Cross-project conventions shared across all khalid's projects — Git workflow, PR standards, code quality gates, and deployment patterns.
---

# Khali Shared Conventions

## Git Workflow
- Branch naming: `feat/`, `fix/`, `refactor/`, `docs/`, `chore/`
- Conventional Commits: `type(scope): description`
- Squash merge to main
- Always rebase before PR

## Commit Types
| Type       | Use for                          |
|------------|----------------------------------|
| `feat`     | New feature                      |
| `fix`      | Bug fix                          |
| `refactor` | Code change (no feature/fix)     |
| `docs`     | Documentation only               |
| `style`    | Formatting, whitespace           |
| `test`     | Adding/fixing tests              |
| `chore`    | Build, CI, dependency updates    |
| `perf`     | Performance improvement          |

## Code Quality Gates
1. **Lint passes** — zero warnings
2. **Tests pass** — all unit + integration
3. **Type check** — strict mode, no `any`
4. **Format** — auto-formatted before commit

## PR Standards
- Title matches conventional commit format
- Description includes: What, Why, How, Testing
- Screenshots for UI changes
- Max 400 lines changed per PR

## Security Rules
- Never commit secrets or API keys
- Use `.env` files (gitignored) for local config
- Validate all user input on backend
- Use parameterized queries for SQL

## Documentation
- README.md in every project root
- Architecture Decision Records for major changes
- Inline JSDoc/dartdoc for public APIs
