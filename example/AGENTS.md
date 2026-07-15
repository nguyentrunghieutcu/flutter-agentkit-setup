# Flutter Project — Agent Instructions

## Stack
- Flutter stable / Dart 3.x · Provider + ChangeNotifier · go_router · Dio · Hive · custom JWT

## Commands
- `flutter run` / `flutter run --release`
- `flutter analyze` — lint (must be clean before finishing any task)
- `dart fix --apply` — auto fix
- `flutter pub get`
- Never run `flutter build` or `flutter test` unless explicitly asked

## Before every task
1. Read `.claude/PROJECT_MAP.md` for the actual current structure.
   If missing or stale, run: `bash .claude/skills/scan-project/scan.sh`
2. For deeper detail read `.claude/reference/patterns.md` (code patterns) or
   `.claude/reference/api.md` (endpoints) as needed — these are shared,
   tool-agnostic docs, not Claude-specific.
3. Check `.claude/context/known-issues.md` before touching a fragile area.

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
- Do not add, move, or delete folders without asking the user first.
- Do not add packages to `pubspec.yaml` without explicit approval.
- Do not introduce Riverpod, BLoC, or GetX — Provider only.
- Do not use `Navigator.push` — use `context.go()` / `context.push()` (go_router only).
- Do not hardcode colors, font sizes, or spacing — use `Theme.of(context)`.
- Dispose every controller/subscription in `dispose()`.
- No `print()` — `debugPrint()` only, removed before finishing.
- Repositories return `Either<Failure, T>` — never throw to providers.

Full Flutter/Dart coding rules (Provider patterns, lifecycle, navigation,
style, API conventions): see `lib/AGENTS.md`, scoped automatically to the
`lib/` subtree.

## After completing a task
- Re-run `bash .claude/skills/scan-project/scan.sh` if structure changed.
- State root cause explicitly for bug fixes.
- Keep changes minimal and scoped to the request.
