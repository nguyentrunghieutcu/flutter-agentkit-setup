---
name: verify-project
description: Detect recurring Flutter/Firebase architecture risks and run safe local validation for Flutter plus optional Node backends. Use before finishing code changes, after bug fixes, or when repeated regressions suggest ownership, async ordering, schema parity, idempotency, layout, tests, analysis, or backend checks may have been skipped.
---

# Verify Project

Run the bundled script from the repository root:

```bash
bash .agents/skills/verify-project/scripts/verify.sh
```

The script does not auto-fix, deploy, migrate, or build releases. It runs
the recurring-risk detector, formatting checks, `flutter analyze`, Flutter
tests when present, and existing `check` scripts in `functions/` or `worker/`.
The detector writes `.claude/PROJECT_RISKS.md`; errors fail verification while
heuristic warnings stay visible for review. Report skipped checks as gaps.
