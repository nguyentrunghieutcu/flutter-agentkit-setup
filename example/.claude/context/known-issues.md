# Known Issues

> Read before fixing a bug or editing a complex/fragile area.
> Agent appends here when discovering a new bug or workaround during a task.

## Active Bugs
| Area | Description | Workaround | Reported |
|---|---|---|---|

## Fragile Areas
| File / Area | Why fragile |
|---|---|
| `lib/core/network/api_client.dart` | Singleton — affects all API calls |
| `lib/main.dart` | Provider registration order matters |
| `lib/core/router/app_router.dart` | Route changes break deep links |

## Workarounds In Place
| Location | Workaround | Ticket / ETA |
|---|---|---|
