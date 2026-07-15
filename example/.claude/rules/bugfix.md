---
paths:
  - "lib/**/*.dart"
---

# Bug Fix Rules

## Diagnose before touching code
1. Identify which layer the bug lives in: widget → provider → usecase → repository → network.
2. Read the relevant screen, provider, and repository files before any change.
3. Do not assume the bug is where the symptom appears.

## Common Flutter/Provider bugs

**UI not updating**
Cause: `notifyListeners()` not called, or called before state mutation.
Fix: mutate state first, then `notifyListeners()`.

**`setState called after dispose`**
Cause: async completes after widget leaves tree.
Fix: `if (!mounted) return;` after every `await` in a `StatefulWidget`.

**`ProviderNotFoundException`**
Cause: widget is outside `MultiProvider` tree, or wrong `BuildContext`.
Fix: verify provider is registered in `main.dart`.

**Infinite rebuild**
Cause: `context.watch` inside a method called from `build`, or `notifyListeners()` in constructor.
Fix: move `watch` to `Consumer` builder.

**API result not shown in UI**
Trace: API response → model `fromJson` → repository → usecase → provider field →
`notifyListeners()` → `Consumer` rebuild. Find where the chain breaks.

**Memory leak / dispose error**
Fix: override `dispose()`, call `.dispose()` on every controller and `.cancel()` on subscriptions.

## After the fix
- Remove any `debugPrint` added during investigation.
- State root cause clearly in completion summary.
