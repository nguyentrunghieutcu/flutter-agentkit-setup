# PROJECT_MAP.md
> Generated: 2026-07-27
> Generated navigation index. The filesystem and runtime configuration remain authoritative.
> Regenerate anytime:
> `bash .claude/skills/scan-project/scan.sh`
> Do not hand-edit this file. Keep manual notes in `.claude/context/`.

---

## Structure

```
lib/
├── core/
  ├── constants/
  ├── error/
  ├── network/
  ├── router/
  ├── theme/
  ├── utils/
├── features/
  ├── home/
    ├── data/
      ├── models/
      ├── repositories/
      ├── sources/
    ├── domain/
      ├── entities/
      ├── repositories/
      ├── usecases/
    ├── presentation/
      ├── providers/
      ├── screens/
      ├── widgets/
├── shared/
  ├── providers/
  ├── widgets/
```

---

## Dependencies

| Package | Version |
|---|---|
| flutter | sdk: flutter |
  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
| cupertino_icons | ^1.0.8 |
| provider | ^6.1.5+1 |
| go_router | ^17.3.0 |
| dio | ^5.10.0 |
| dartz | ^0.10.1 |
| hive | ^2.2.3 |
| hive_flutter | ^1.1.0 |
| shared_preferences | ^2.5.5 |

---

## Features (1 found)

| Feature | Path | Layers present |
|---|---|---|
| home | `lib/features/home` | domain:✓ data:✓ presentation:✓ |

---

## Providers (1 found)

| Provider | File |
|---|---|
| `AppInfoProvider` | `lib/features/home/presentation/providers/app_info_provider.dart` |

---

## Screens

| Screen | File |
|---|---|
| `home_screen` | `lib/features/home/presentation/screens/home_screen.dart` |

---

## Routes

| Path | Defined in |
|---|---|
| / | lib/core/router/app_router.dart:6 |

---

## Shared Widgets

| Widget | File |
|---|---|
| `app_error_view` | `lib/shared/widgets/app_error_view.dart` |
| `app_loading_indicator` | `lib/shared/widgets/app_loading_indicator.dart` |

---

## Backend Surfaces

| System | Path | Responsibility |
|---|---|---|
| _(none detected)_ | | |

---

## Tests (1 Flutter test files)

| Suite | Path | Status |
|---|---|---|
| Flutter | `test/` | 1 test files detected |

---

## Large Dart Files

| Lines | File |
|---|---|
| _(none at or above 600 lines)_ | |
