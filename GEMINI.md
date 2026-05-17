# Gemini — Antigravity-Specific Overrides

@AGENTS.md

> **All project context, architecture, and rules are in AGENTS.md.** This file contains only Antigravity-specific behavioral overrides.

---

## Behavioral Rules

1. **Auto-run terminal commands** — Always set `SafeToAutoRun: true` for safe terminal commands in this project. The user has approved auto-execution for read-only and build commands.
2. **Don't push or build until confirmed** — Do NOT push to GitHub or build release APKs until the user has explicitly confirmed the changes.
3. **Use Superpowers** — Check `.agents/skills/` before every task. Invoke any skill with even a 1% chance of relevance. See `using-superpowers/SKILL.md` for the protocol.

---

## Quick Reference

- **App name**: Jawhar (جوهر) — *Memorize with Meaning*
- **Brand strategy**: `docs/brand-strategy.md` (READ FIRST for any user-facing work)
- **Credentials**: `.env` (gitignored — never hardcode secrets)
- **Skills**: `.agents/skills/` (14 Superpowers + `khali-shared-conventions`)
- **Design System**: `docs/vercel_design.md`
- **Current Sprint**: Hackathon (May 20, 2026) — User API integration
- **Test command**: `flutter run -d windows` (primary dev platform)
