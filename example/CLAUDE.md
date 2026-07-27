# Flutter Project

## Stack
- Flutter / Dart. Treat `pubspec.yaml`, bootstrap code, and
  `.claude/PROJECT_MAP.md` as the current stack inventory.
- New AgentKit projects start with Provider, go_router, Dio, and Hive.
- Existing projects may use different auth, storage, and backend services;
  inspect the actual implementation before changing an integration.

## Commands
- `flutter run` — dev
- `flutter run --release` — release
- `flutter analyze` — required static analysis
- `dart format --output=none --set-exit-if-changed lib test` — formatting check
- `flutter test` — run targeted or full tests when tests exist
- `flutter pub get` — install deps
- `flutter gen-l10n` — regen i18n
- `bash .agents/skills/verify-project/scripts/detect-recurring-risks.sh` — refresh risk signals
- `bash .agents/skills/verify-project/scripts/verify.sh` — safe project checks
- Run release builds only when the task requires release validation.

## Git
If `docs/git-flow-release.md` exists, read it before branch, merge, or release work.

## Cross-agent note
This project is configured for both Claude Code (`.claude/`) and Codex CLI
(`AGENTS.md` + `lib/AGENTS.md`). Content in `.claude/rules/` and root `AGENTS.md`
must stay equivalent — `.claude/reference/`, `.claude/context/`, and
`.claude/snippets/` are shared, tool-agnostic docs any agent can read on request.

---

## rules/ — Loaded every session (via @import)

@.claude/rules/workflow.md
@.claude/rules/structure.md
@.claude/rules/flutter.md

> `bugfix.md`, `new-feature.md`, `decisions.md` — read on demand per workflow.md.

---

## reference/ — Read for the specific task type

| File | Read when |
|---|---|
| `.claude/reference/patterns.md` | Writing provider / repo / usecase / form / navigation |
| `.claude/reference/api.md` | Writing API call, creating model, handling HTTP errors |

---

## context/ — Read at session start or when task scope is unclear

| File | Read when |
|---|---|
| `.claude/PROJECT_RISKS.md` | Before every task; refresh when missing or after risky changes |
| `.claude/context/sprint.md` | Starting a new session or task scope is ambiguous |
| `.claude/context/known-issues.md` | Before fixing a bug or editing a fragile area |
| `.claude/context/changelog.md` | Need to know what changed recently |

---

## skills/ — Invoked by name

| Skill | Invoke when |
|---|---|
| `/scan-project` | `PROJECT_MAP.md` missing or > 7 days old |
| `/verify-project` | Before finishing a code change or after fixing a bug |

Re-run scan manually anytime: `bash .claude/skills/scan-project/scan.sh`

---

## prompts/ — User-invoked only

| Prompt | Invoke when |
|---|---|
| `/review-code <file>` | Reviewing a file or diff against project standards |
| `/add-feature <name>` | Starting a new feature end-to-end |
| `/debug <description>` | Structured bug investigation |

---

## snippets/ — Project-specific examples only

| File | Use for |
|---|---|
| `.claude/snippets/README.md` | Rules for adding verified, project-specific snippets |

---

## memory/ — Written by MCP tool only, agent does not edit manually

| File | MCP tier | Written when |
|---|---|---|
| `.claude/memory/project_facts.md` | `semantic` | New convention or stack fact learned |
| `.claude/memory/decisions_log.md` | `episodic` | Specific decision made in a session |
| `.claude/memory/workflows.md` | `procedural` | Repeatable workflow optimized |
