# Workflow Rules

## Before every task
1. Check `.claude/PROJECT_MAP.md` exists and is recent.
   - Missing or stale (> 7 days) → run `bash .claude/skills/scan-project/scan.sh` first.
   - Exists → read "Structure" and "Features" sections before touching any file.
2. Read only the rules file relevant to the task type:
   - Bug fix → `.claude/rules/bugfix.md`
   - New feature → `.claude/rules/new-feature.md`
   - Architecture question → `.claude/rules/decisions.md`

## While working
- Read a file before editing it.
- Keep changes minimal and scoped to the stated task.
- Follow the pattern already in the file being edited — do not introduce new patterns.
- Do not add packages to `pubspec.yaml` without explicit user approval.
- Do not reformat, reorder imports, or touch unrelated code.

## After completing a task
- If a file or folder was created or moved → update `.claude/PROJECT_MAP.md`
  (or re-run `bash .claude/skills/scan-project/scan.sh`).
- If a new Provider was added → verify it appears after re-scan.
- Append completion summary:

```
## Completed
- [x] <what was done>
- [x] PROJECT_MAP.md updated (if structure changed)
- [x] No unrelated files changed
```

## Never do
- Add, move, or delete folders without user confirmation.
- Run `flutter build`, `flutter test`, or `dart compile` unless asked.
- Use `print()` — use `debugPrint()` only, remove before finishing.
- Create `*_test.dart` files unless tests are explicitly requested.
