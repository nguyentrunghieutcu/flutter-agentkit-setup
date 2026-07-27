# PROJECT_RISKS.md

> Generated: 2026-07-27 by `detect-recurring-risks.sh`
> Machine-owned heuristic report; regenerate instead of hand-editing.
> Errors are deterministic project-rule violations. Warnings require human/agent review and may be intentional.

## Summary

- Errors: 0
- Warnings: 0
- Flutter tests detected: 1
- Large-file threshold: 600 lines

## Errors

- None.

## Warnings

- None.

## Prevention Checklist

- **State/lifecycle:** name one authoritative owner for shared state; publish user-visible auth/navigation state before optional cleanup; cover slow or failing cleanup.
- **Legacy compatibility:** test older Firestore/Hive/in-memory objects when adding required fields; use tolerant reads/defaults plus an explicit migration path.
- **Mobile layout:** for changed full-page UI, verify compact widths, dense content, keyboard insets, and both system bars; reserve `SafeArea(top: false)` for intentional modal behavior.

## Required Agent Response

- Read this report before editing a flagged area.
- For each relevant warning, state why it is safe or add a regression guard.
- Re-run `bash .agents/skills/verify-project/scripts/verify.sh` before finishing.
