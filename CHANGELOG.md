# Changelog

All notable changes to this project are documented here. Entries use `@features` tags for searchability.

---

## 2026-02-12

### Added

- **v0.1 feature doc created** — Walk & Talk feature doc with ideation process, iteration 0 definition, full implementation plan, and acceptance criteria. @features walk-and-talk
  - Files changed: `docs/features/walk-and-talk.md`

### Design

- **Visual style decision — HD-2D** — Settled on Octopath Traveler-inspired HD-2D: 2D sprite art in a 3D-lit world with real-time shadows, depth of field, bloom, and atmospheric lighting. Warm and grounded, not dark/dramatic. This rules out browser-only engines and makes Godot the strong frontrunner. @features visual-style
  - Files changed: `docs/startup-simulator-game-brief.md`

- **Navigation model decision** — Hybrid walk + fast-travel. Walking is the primary mechanic early, shifts to secondary as management scales. Fast-travel unlocks for discovered locations. Walking remains the idea engine throughout — NPCs are always the source of product direction. @features navigation-model
  - Files changed: `docs/startup-simulator-game-brief.md`

- **Project documentation structure established** — Created CLAUDE.md (project entry point), docs/documentation-guide.md (doc system conventions), docs/version-roadmap.md (v0.1–v1.0 breakdown), and CHANGELOG.md. The full game brief has been decomposed into 10 incremental sub-versions, each with scope, iteration 0, and acceptance criteria. @features documentation-setup
  - Files changed: `CLAUDE.md`, `docs/documentation-guide.md`, `docs/version-roadmap.md`, `CHANGELOG.md`
