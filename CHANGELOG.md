# Changelog

All notable changes to Flutter AgentKit are documented in this file.

## [1.1.0] - 2026-07-27

### Added

- Add a generated recurring-risk report covering agent configuration, navigation,
  logging, state ownership, lifecycle, persistence, backend, test, and layout risks.
- Add a non-destructive `verify-project` workflow for formatting, analysis, Flutter
  tests, and existing backend checks.
- Add canonical Codex project skills under `.agents/skills/`, with legacy
  `.codex/skills/` compatibility and a Codex code-reviewer configuration.
- Add a domain use-case test to newly scaffolded Flutter projects.
- Add backend, test, route, dependency, and large-file inventories to the generated
  project map.

### Changed

- Preserve project-owned context and reference files when refreshing configuration
  with `--force`.
- Strengthen guidance for state ownership, async cleanup, schema compatibility,
  idempotency, system insets, regression tests, and cross-system changes.
- Treat `PROJECT_MAP.md` as a fully generated navigation index and keep durable
  project knowledge under `.claude/context/`.

### Removed

- Remove generic interceptor and provider snippets that could conflict with a
  project's real authentication, networking, or state-management boundaries.

## [1.0.0] - 2026-07-15

- Initial public release with Flutter project scaffolding and shared agent
  configuration for Claude Code, Codex, Cursor, and Windsurf.
