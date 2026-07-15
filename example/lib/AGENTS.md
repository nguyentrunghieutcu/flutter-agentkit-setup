# Flutter / Dart Coding Rules
> Scoped to lib/ — merged after root AGENTS.md for any work inside this tree.

## Provider
- Extend `ChangeNotifier`. Always call `notifyListeners()` after mutating state.
- Keep `_isLoading`, `_error`, and domain state as private fields with public getters.
- Use `Consumer<T>` for scoped rebuilds. Use `context.read<T>()` only in callbacks.
- Never call `context.watch` or `context.read` in a method called during `build`.

## Widgets
- Prefer `StatelessWidget` + Provider over `StatefulWidget`.
- Always use `const` constructors where possible.
- Break `build` methods longer than ~40 lines into private `_build*` methods.
- Never call `setState` in a large widget — push state to the Provider layer.

## Lifecycle
- Dispose every `TextEditingController`, `AnimationController`, `StreamSubscription`.
- Add `if (!mounted) return;` after every `await` inside a `StatefulWidget`.

## Navigation
- `context.go()` for root/tab navigation. `context.push()` when back is needed.
- Never use `Navigator.push` or `MaterialPageRoute` directly.

## Lists
- Always `ListView.builder` or `SliverList` for dynamic lists.

## API
- Use the shared Dio client from `lib/core/network/`. Never instantiate Dio in a feature.
- `FormData` + `MultipartFile` for uploads — never base64 in JSON.

## Bug fix protocol
Diagnose layer first: widget → provider → usecase → repository → network.
Common causes: missing `notifyListeners()`, missing `mounted` check, provider
outside `MultiProvider` tree, `notifyListeners()` called during build phase.
Trace data path fully before editing. Minimal fix only — no surrounding refactors.

## Code hygiene
No `print()`. Remove `debugPrint` before finishing. `dart fix --apply` clean.
