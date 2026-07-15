# Clean Architecture

The generated structure uses three primary layers, inspired by
`guilherme-v/flutter-clean-architecture-example`:

- **Presentation**: Flutter UI and state management.
- **Domain**: entities, repository interfaces, and pure-Dart use cases.
- **Data**: sources, DTOs/models, and repository implementations.

The project is organized **feature-first**, so every business domain has all
three layers in `lib/features/<feature>/`.

## Dependency rule

- `domain` does not import `data` or `presentation`.
- `data` may import `domain`, but not `presentation`.
- `presentation` calls business logic through use cases and repository abstractions.
- `core` contains only shared infrastructure, never feature-specific business logic.
