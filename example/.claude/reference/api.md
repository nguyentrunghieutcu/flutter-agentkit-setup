# Integration Reference

> Routing index for external systems. Verify every claim against the current
> source and configuration before editing an integration.

## Source of Truth

- Dependencies: `pubspec.yaml`
- App bootstrap and client construction: `lib/main.dart`, `lib/app.dart`
- HTTP clients: `lib/core/network/`
- Firebase setup: `firebase.json`, `firestore.rules`, `functions/` when present
- Other backends/workers: inspect their package and deployment config

## Integration Inventory

| System | Client / Source | Auth | Contract owner |
|---|---|---|---|
| HTTP API | Inspect `lib/core/network/` | Verify interceptor/client | Backend route/schema |
| Firebase | Inspect app bootstrap and repositories | Firebase Auth / Rules | `firestore.rules`, Functions |
| Local storage | Inspect data sources | Device-local | Models and migration code |

Replace these generic rows with project-specific paths after the first scan.

## Change Checklist

- Identify the authoritative owner of each field.
- Update client model, repository/source, backend handler, security rules, and
  migration/default behavior together when a schema crosses boundaries.
- Make retryable backend operations idempotent.
- Use a transaction/batch for multi-document invariants.
- Preserve the existing error contract and user-safe messages.
- Add a regression test or document the exact manual verification.

## Endpoint / Callable Registry

| System | Operation | Input | Output | Owner |
|---|---|---|---|
| _(fill from source)_ | | | | |
