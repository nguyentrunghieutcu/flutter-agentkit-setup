---
description: Starts a new Flutter feature end-to-end following project patterns. User-invoked only.
disable-model-invocation: true
argument-hint: <feature-name>
---

# Add Feature: $ARGUMENTS

Before writing any code:
1. Read `.claude/PROJECT_MAP.md` — confirm `$ARGUMENTS` feature does not already exist.
2. Read `.claude/reference/api.md` — note any existing endpoints for this domain.
3. Read `.claude/reference/patterns.md` — use these exact patterns.
4. Follow `.claude/rules/new-feature.md` step by step.

## Folder to create
`lib/features/$ARGUMENTS/`

## Build order
Domain → Data → Presentation → Wire up → Re-run scan-project

## Done when
- [ ] All layers implemented per `new-feature.md` checklist
- [ ] Provider registered in `main.dart`
- [ ] Route added in `app_router.dart`
- [ ] `bash .claude/skills/scan-project/scan.sh` re-run
- [ ] `context/changelog.md` updated with new entry
