# Structure Rules

## Source of truth
The filesystem, `pubspec.yaml`, and runtime configuration are authoritative.
`.claude/PROJECT_MAP.md` is a generated navigation index created by
`bash .claude/skills/scan-project/scan.sh`; do not hand-edit it.
- Do not assume a folder, service, or dependency exists — verify it directly.
- Follow the existing layout for local changes. Ask before a broad architecture move.
- After any structural change, re-run the scan script.

## Folder layout (canonical)
```
lib/
├── core/            # Shared infrastructure — never feature-specific
│   ├── constants/
│   ├── network/     # Dio client, interceptors
│   ├── router/      # go_router definitions
│   ├── theme/       # ThemeData, ColorScheme, TextTheme
│   └── utils/       # Pure helper functions
├── features/        # One folder per business domain
│   └── <name>/
│       ├── data/
│       │   ├── models/       # JSON models — fromJson/toJson/toEntity
│       │   ├── repositories/ # Concrete repo implementations
│       │   └── sources/      # Remote + local data sources
│       ├── domain/
│       │   ├── entities/     # Pure Dart — no JSON, no Flutter
│       │   ├── repositories/ # Abstract interfaces
│       │   └── usecases/     # One class, one call() method
│       └── presentation/
│           ├── providers/    # ChangeNotifier classes
│           ├── screens/      # One file per screen
│           └── widgets/      # Widgets scoped to this feature
├── shared/
│   ├── providers/   # Cross-feature providers (auth, theme, locale)
│   └── widgets/     # Shared UI components
└── main.dart        # MultiProvider root
```

## Naming
| Thing | Convention | Example |
|---|---|---|
| Files | snake_case | `product_card.dart` |
| Classes | PascalCase | `ProductCard` |
| Providers | `<Feature>Provider` | `CartProvider` |
| Screens | `<Feature>Screen` | `CartScreen` |
| Use cases | `<Verb><Noun>UseCase` | `FetchProductsUseCase` |
| Models | `<Name>Model` | `ProductModel` |
| Entities | `<Name>` | `Product` |

## Layer dependency rule
`domain` never imports from `data` or `presentation`.
`data` never imports from `presentation`.
Violations must be raised with the user before proceeding.
