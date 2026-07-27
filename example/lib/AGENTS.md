# Flutter / Dart Coding Rules
> Scoped to lib/ — merged after root AGENTS.md for any work inside this tree.

## Provider
- Use `ChangeNotifier` for shared presentation state and notify only after the
  observable state is internally consistent.
- Name one authoritative owner for each shared field. Other providers expose
  derived/read-only views instead of stale mutable mirrors.
- Keep `_isLoading`, `_error`, and domain state as private fields with public getters.
- Use `Consumer<T>` or `Selector<T, R>` for scoped rebuilds.
- Use `context.read<T>()` for one-time access; do not mutate providers during build.

## Widgets
- Prefer `StatelessWidget` + Provider over `StatefulWidget`.
- Always use `const` constructors where possible.
- Break `build` methods longer than ~40 lines into private `_build*` methods.
- Keep ephemeral UI state local; move shared or domain state to Provider.
- Full-page routes preserve top and bottom system insets. Use
  `SafeArea(top: false)` only for intentional modal content and verify compact widths.

## Lifecycle
- Dispose every `TextEditingController`, `AnimationController`, `StreamSubscription`.
- After `await`, check `mounted` before using `State`, `context`, or controllers.
- In sign-out/reset flows, publish visible state before awaiting optional slow
  cleanup when detaching cleanup is safe.

## Persistence compatibility
- Treat Flutter models, backend validation, database Rules, defaults, and
  migrations as one contract when persisted fields or roles change.
- Keep reads tolerant of older Firestore/Hive/in-memory objects and cover an
  old-data fixture before making a field required.

## Navigation
- `context.go()` for root/tab navigation. `context.push()` when back is needed.
- Never use `Navigator.push` or `MaterialPageRoute` directly.

## Lists
- Always `ListView.builder` or `SliverList` for dynamic lists.

## API
- Use the existing integration boundary. Never instantiate HTTP, Firebase,
  database, or storage clients in widgets.
- `FormData` + `MultipartFile` for uploads — never base64 in JSON.

## Bug fix protocol
Diagnose layer first: widget → provider → usecase → repository → network.
Trace the full data path before editing. Check duplicate sources of truth,
async ordering, retry/idempotency, schema/rules drift, and lifecycle safety.
Keep the fix focused and add a regression test when feasible.

## Code hygiene
No `print()`. Remove temporary `debugPrint`. Run the project verification skill.
