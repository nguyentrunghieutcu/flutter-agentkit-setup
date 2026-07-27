---
paths:
  - "lib/**/*.dart"
---

# Flutter / Dart Coding Rules

## Provider
- Extend `ChangeNotifier` for shared presentation state. Notify only after the
  observable state is internally consistent.
- Keep `_isLoading`, `_error`, and domain state as private fields with public getters.
- Use `Consumer<T>` or `Selector<T, R>` for scoped rebuilds.
- Use `context.read<T>()` for one-time access; do not trigger mutations during build.
- Register in `main.dart` `MultiProvider`. Use `ChangeNotifierProxyProvider` when dependent.

## Widgets
- Prefer `StatelessWidget` + Provider over `StatefulWidget`.
- Always use `const` constructors where possible.
- Break `build` methods longer than ~40 lines into private `_build*` methods.
- Keep ephemeral UI state local with `setState`; move shared or domain state to Provider.

## Lifecycle
- Dispose every `TextEditingController`, `AnimationController`, `StreamSubscription`.
- After an `await`, check `mounted` before touching `State`, `context`, or controllers.

## Navigation
- Use `context.go()` for root/tab navigation (replaces stack).
- Use `context.push()` when back navigation is needed.
- Never use `Navigator.push` or `MaterialPageRoute` directly.

## Style
- Feature widgets use theme/tokens; literal colors and typography belong in theme files.
- Never install new icon packages — use `Icons.*` or existing assets.

## Lists
- Always use `ListView.builder` or `SliverList` for dynamic lists.
- Never build lists with `.map().toList()` inside `ListView` children.

## API
- Use the project's existing integration boundary. Do not instantiate network,
  Firebase, database, or storage clients inside widgets.
- Repositories return `Either<Failure, T>`. Catch exceptions inside the repository.
- Use `FormData` + `MultipartFile` for file uploads — never embed base64 in JSON.

## Code hygiene
- Remove all `debugPrint`, unused imports, dead code before finishing.
- Never use `print()`.
- Run formatting and static analysis checks before considering a task complete.
