---
description: Structured bug investigation with full context. User-invoked only.
disable-model-invocation: true
argument-hint: <description of the bug>
---

# Debug: $ARGUMENTS

## Step 1 — Gather context
Read `.claude/context/known-issues.md` — is this bug already documented?

## Step 2 — Locate the layer
- Widget rendering → start in the screen file
- State not updating → start in the provider
- Wrong data → start in repository / remote source
- Network error → start in `lib/core/network/`

## Step 3 — Trace the data path
API response → `fromJson` → repository → use case → provider field →
`notifyListeners()` → `Consumer` rebuild. Find where the chain breaks.

## Step 4 — Apply fix
Follow `.claude/rules/bugfix.md`. Minimal change only.

## Step 5 — After fix
- Remove all `debugPrint` added during investigation.
- If unknown bug, add it to `.claude/context/known-issues.md`.
- Completion summary must state root cause explicitly.
