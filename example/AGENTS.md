# Flutter Project — Agent Instructions

## Stack
- Flutter / Dart. `pubspec.yaml`, bootstrap code, and `.claude/PROJECT_MAP.md`
  describe the current stack; do not assume auth, storage, or backend choices.
- New AgentKit projects use Provider + ChangeNotifier and go_router by default.

## Commands
- `flutter run` / `flutter run --release`
- `flutter analyze` — lint (must be clean before finishing any task)
- `dart format --output=none --set-exit-if-changed lib test`
- `flutter test` — run when tests exist or behavior changed
- `flutter pub get`
- `bash .agents/skills/verify-project/scripts/detect-recurring-risks.sh` — refresh risk signals
- `bash .agents/skills/verify-project/scripts/verify.sh` — safe validation suite
- Run release builds only when the task requires them.

## Before every task
1. Read `.claude/PROJECT_MAP.md` for the actual current structure.
   If missing or stale, run: `bash .claude/skills/scan-project/scan.sh`
2. Read `.claude/PROJECT_RISKS.md`. If missing, run:
   `bash .agents/skills/verify-project/scripts/detect-recurring-risks.sh`
   Treat errors as blockers and warnings as required heuristic review.
3. For deeper detail read `.claude/reference/patterns.md` (code patterns) or
   `.claude/reference/api.md` (endpoints) as needed — these are shared,
   tool-agnostic docs, not Claude-specific.
4. Check `.claude/context/known-issues.md` before touching a fragile area.

## Folder layout
```
lib/
├── core/{constants,network,router,theme,utils}/
├── features/<name>/{data,domain,presentation}/
├── shared/{providers,widgets}/
└── main.dart
```
Domain never imports data or presentation. Data never imports presentation.
See `.claude/rules/structure.md` for full naming conventions.

## Non-negotiable rules
- Follow the existing structure; ask before broad architecture or migration changes.
- Do not add packages to `pubspec.yaml` without explicit approval.
- Do not introduce Riverpod, BLoC, or GetX — Provider only.
- Do not use `Navigator.push` — use `context.go()` / `context.push()` (go_router only).
- Feature UI uses theme/tokens; literal visual tokens belong in theme files.
- Dispose every controller/subscription in `dispose()`.
- No `print()` — `debugPrint()` only, removed before finishing.
- Keep widgets away from direct network/Firebase/storage client construction.
- Name one authoritative owner for shared state; derive mirrors instead of
  maintaining duplicate mutable copies across providers.
- When persisted fields or roles change, update client models, backend checks,
  database Rules, tolerant defaults/migrations, and tests as one contract.
- Full-page routes preserve both system insets; `SafeArea(top: false)` is only
  for an intentional modal boundary and requires compact/inset verification.

Full Flutter/Dart coding rules (Provider patterns, lifecycle, navigation,
style, API conventions): see `lib/AGENTS.md`, scoped automatically to the
`lib/` subtree.

## After completing a task
- Re-run `bash .claude/skills/scan-project/scan.sh` if structure changed.
- Run `bash .agents/skills/verify-project/scripts/verify.sh`.
- Add a regression test for bug fixes when a stable seam exists; otherwise
  document the exact manual verification and missing seam.
- State root cause explicitly for bug fixes.
- Keep changes minimal and scoped to the request.
