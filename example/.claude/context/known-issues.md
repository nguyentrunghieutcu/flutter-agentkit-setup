# Known Issues

> Read before fixing a bug or editing a complex/fragile area.
> Agent appends here when discovering a new bug or workaround during a task.

## Active Bugs
| Area | Symptom | Root cause / hypothesis | Workaround | Reported |
|---|---|---|---|---|

## Recurring Patterns
| Pattern | Prevention | Required verification |
|---|---|---|
| Duplicate sources of truth | Name one authoritative owner; derive all mirrors | Test both update directions |
| Async lifecycle ordering | Publish user-visible state before slow cleanup | Test slow/failing cleanup |
| Cross-system schema drift | Change client, backend, rules, and defaults together | Contract or emulator test |
| Retry/concurrency duplication | Use transactions and deterministic IDs | Retry/idempotency test |
| Legacy/default compatibility | Keep tolerant reads/defaults and add explicit migrations | Old document/local-cache fixture |
| Mobile inset/layout regression | Separate full-page and modal safe-area behavior | Compact width plus top/bottom inset widget test |
| Missing regression seam | Extract testable domain/provider/backend behavior | Targeted test or documented manual gap |
| Oversized state/UI coordinator | Split new responsibilities behind explicit interfaces | Ownership test and focused unit/widget tests |

## Resolved Bugs
| Area | Root cause | Resolution | Prevention / regression test | Resolved |
|---|---|---|---|---|

## Fragile Areas
| File / Area | Why fragile |
|---|---|
| `lib/core/network/api_client.dart` | Singleton — affects all API calls |
| `lib/main.dart` | Provider registration order matters |
| `lib/core/router/app_router.dart` | Route changes break deep links |

## Workarounds In Place
| Location | Workaround | Ticket / ETA |
|---|---|---|
