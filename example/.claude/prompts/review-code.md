---
description: Reviews a file or diff for Flutter/Provider correctness, patterns, and style. User-invoked only.
disable-model-invocation: true
argument-hint: <file-path or branch>
---

# Code Review

## Target
$ARGUMENTS

Read the target file(s). Cross-reference against `.claude/rules/flutter.md`
and `.claude/reference/patterns.md`.

## Review checklist

**Provider**
- [ ] `notifyListeners()` called after mutation, not before
- [ ] No business logic inside widget `build()`
- [ ] `Consumer` used for scoped rebuilds
- [ ] `context.read` only in callbacks, never in `build`

**Lifecycle**
- [ ] Every controller disposed in `dispose()`
- [ ] `if (!mounted) return;` after every `await` in StatefulWidget

**Style**
- [ ] No hardcoded colors or font sizes
- [ ] No `Navigator.push` — go_router only
- [ ] No `print()` — removed before finishing
- [ ] `const` constructors used where possible

**Structure**
- [ ] File is in correct layer per `.claude/rules/structure.md`
- [ ] No cross-layer imports

## Output format
For each finding: **File:line** — what is wrong — concrete fix.
End with: `✅ No issues` or `⚠️ N issues found`.
