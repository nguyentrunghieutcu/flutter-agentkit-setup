# New Feature Rules

Before writing any code, confirm in `.claude/PROJECT_MAP.md`:
- Feature folder does not already exist.
- Required providers are not already implemented.
- Required endpoints are not already implemented.

## Build order (strict)

**1. Domain** — `lib/features/<name>/domain/`
- [ ] Entity: pure Dart, no JSON, no Flutter imports
- [ ] Repository interface: abstract, returns `Either<Failure, T>`
- [ ] Use cases: one class per action, single `call()` method

**2. Data** — `lib/features/<name>/data/`
- [ ] Model: `fromJson`, `toJson`, `toEntity()`
- [ ] Remote source: calls Dio client, returns models
- [ ] Repository impl: wraps source in try/catch, returns `Either`

**3. Presentation** — `lib/features/<name>/presentation/`
- [ ] Provider: `ChangeNotifier`, holds `_isLoading` + `_error` + domain state
- [ ] Screen: `Consumer<Provider>`, shows loading / error / content
- [ ] Widgets: extract any block > ~40 lines into its own file

**4. Wire up**
- [ ] Register provider in `lib/main.dart` `MultiProvider`
- [ ] Add route(s) in `lib/core/router/app_router.dart`
- [ ] Re-run `bash .claude/skills/scan-project/scan.sh`

## Quality gate before finishing
- [ ] Every controller disposed in `dispose()`
- [ ] No hardcoded colors, sizes, strings
- [ ] No `Navigator.push` — use `context.go` / `context.push`
- [ ] No `print()` or leftover `debugPrint`
- [ ] All three states (loading / error / content) handled in every screen
- [ ] `dart fix --apply` clean
