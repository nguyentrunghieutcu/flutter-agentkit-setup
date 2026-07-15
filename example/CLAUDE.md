# Flutter Project

## Stack
- Flutter stable / Dart 3.x
- State: Provider + ChangeNotifier
- Navigation: go_router
- HTTP: Dio + interceptors
- Storage: Hive / shared_preferences
- Auth: custom JWT

## Commands
- `flutter run` — dev
- `flutter run --release` — release
- `flutter analyze` — lint
- `dart fix --apply` — auto fix
- `flutter pub get` — install deps
- `flutter gen-l10n` — regen i18n
- Never run `flutter build` or `flutter test` unless explicitly asked

## Git
Read `docs/git-flow-release.md` before any branch, merge, or release work.

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
| `.claude/context/sprint.md` | Starting a new session or task scope is ambiguous |
| `.claude/context/known-issues.md` | Before fixing a bug or editing a fragile area |
| `.claude/context/changelog.md` | Need to know what changed recently |

---

## skills/ — Invoked by name

| Skill | Invoke when |
|---|---|
| `/scan-project` | `PROJECT_MAP.md` missing or > 7 days old |

Re-run scan manually anytime: `bash .claude/skills/scan-project/scan.sh`

---

## prompts/ — User-invoked only

| Prompt | Invoke when |
|---|---|
| `/review-code <file>` | Reviewing a file or diff against project standards |
| `/add-feature <name>` | Starting a new feature end-to-end |
| `/debug <description>` | Structured bug investigation |

---

## snippets/ — Copy directly into project

| File | Use for |
|---|---|
| `.claude/snippets/base_provider.dart` | Base class for feature providers |
| `.claude/snippets/api_interceptor.dart` | Auth + error Dio interceptors |

---

## memory/ — Written by MCP tool only, agent does not edit manually

| File | MCP tier | Written when |
|---|---|---|
| `.claude/memory/project_facts.md` | `semantic` | New convention or stack fact learned |
| `.claude/memory/decisions_log.md` | `episodic` | Specific decision made in a session |
| `.claude/memory/workflows.md` | `procedural` | Repeatable workflow optimized |
