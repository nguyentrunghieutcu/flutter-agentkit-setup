---
paths:
  - "lib/**/*.dart"
---

# Flutter / Dart Coding Rules

## Provider
- Extend `ChangeNotifier`. Always call `notifyListeners()` after mutating state.
- Keep `_isLoading`, `_error`, and domain state as private fields with public getters.
- Use `Consumer<T>` for scoped rebuilds. Use `context.read<T>()` only in callbacks.
- Never call `context.watch` or `context.read` in a method called during `build`.
- Register in `main.dart` `MultiProvider`. Use `ChangeNotifierProxyProvider` when dependent.

## Widgets
- Prefer `StatelessWidget` + Provider over `StatefulWidget`.
- Always use `const` constructors where possible.
- Break `build` methods longer than ~40 lines into private `_build*` methods.
- Never call `setState` in a large widget — push state to the Provider layer.

## Lifecycle
- Dispose every `TextEditingController`, `AnimationController`, `StreamSubscription`.
- Add `if (!mounted) return;` after every `await` inside a `StatefulWidget`.

## Navigation
- Use `context.go()` for root/tab navigation (replaces stack).
- Use `context.push()` when back navigation is needed.
- Never use `Navigator.push` or `MaterialPageRoute` directly.

## Style
- Never hardcode colors: use `Theme.of(context).colorScheme.*`
- Never hardcode font sizes: use `Theme.of(context).textTheme.*`
- Never install new icon packages — use `Icons.*` or existing assets.

## Lists
- Always use `ListView.builder` or `SliverList` for dynamic lists.
- Never build lists with `.map().toList()` inside `ListView` children.

## API
- Use the shared Dio client from `lib/core/network/`. Never instantiate Dio in a feature.
- Repositories return `Either<Failure, T>`. Catch exceptions inside the repository.
- Use `FormData` + `MultipartFile` for file uploads — never embed base64 in JSON.

## Code hygiene
- Remove all `debugPrint`, unused imports, dead code before finishing.
- Never use `print()`.
- `dart fix --apply` before considering any task complete.
