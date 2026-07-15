# Architectural Decisions

Read this before suggesting any change to stack, patterns, or folder structure.
These decisions are final unless the user explicitly reopens them.

## State management: Provider
Do not introduce Riverpod, BLoC, or GetX. If you believe a change is warranted,
say so — but still implement with Provider.

## Navigation: go_router
Never use `Navigator.push`, `Navigator.pushNamed`, or `MaterialPageRoute`.

## Error handling: Either (dartz)
Repositories return `Either<Failure, T>`. Never throw from a repository.

## Theming: ThemeData only
No hardcoded colors, sizes, or font values anywhere.

## Shared widgets over duplication
All reusable UI lives in `lib/shared/widgets/`. Never create one-off styled
buttons or text fields in screens.

---
> To propose a new decision, state it explicitly and wait for user confirmation.
> Then append it here in the format above.
