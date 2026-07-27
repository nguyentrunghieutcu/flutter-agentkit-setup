# Agent Setup Audit — Badminton Smash

Date: 2026-07-27

## Scope

Review the Flutter AgentKit generator and the generated Badminton Smash agent
configuration, using repeated project bugs as evidence. The focus is agent
context accuracy, task routing, validation, regression prevention, and
cross-system Flutter/Firebase/Worker changes.

## Findings

### High — Project context described the wrong architecture

The root instructions still described custom JWT, generic Dio interceptors, and
Hive/shared_preferences as the primary stack. Badminton Smash actually uses
Firebase Auth, Firestore, FCM, Firebase Functions, a Cloudflare Worker, and Hive
as fallback/migration storage. This encouraged locally consistent but
project-wrong changes.

Resolution:
- Replaced generic stack claims with actual ownership boundaries.
- Added `CONTEXT.md` and integration-reference routing.
- Added scoped backend instructions in `functions/AGENTS.md` and `worker/AGENTS.md`.

### High — Repeated bugs had no regression gate

At the initial audit the project had zero Flutter test files, while the
instructions explicitly told agents not to create or run tests. Resolved bugs
were recorded historically but were not connected to prevention or regression
coverage.

Resolution:
- Removed the test prohibition.
- Added `verify-project`, which runs formatting, analysis, Flutter tests when
  present, Functions checks, and Worker checks.
- New AgentKit projects now include a real domain test.
- Added recurring-root-cause and regression-policy sections to known issues.

Remaining risk:
- Badminton Smash now has 17 Flutter tests, but the central `SessionProvider`
  ownership/auth-cleanup paths still have no focused regression suite.
- Firebase Functions now run syntax validation plus a Firestore Rules emulator
  suite, but callable/scheduled handler behavior still lacks focused unit tests.

### High — Codex skill configuration was malformed and drifted

The repository skill copy used `.Codex` path casing, omitted the required skill
name, and lived primarily under the legacy `.codex/skills` path. The three skill
copies had already diverged.

Resolution:
- Made `.agents/skills` the canonical Codex project-skill location.
- Added valid `name` and `description` metadata.
- Retained `.codex/skills` only as a legacy mirror.
- Validated both project skills with the skill validator.

### High — Scan and upgrade operations could erase project knowledge

`scan.sh` claimed to preserve manual sections but rewrote the entire project map.
Likewise, `--force` could overwrite known issues, changelog entries, integration
contracts, and project-specific patterns.

Resolution:
- Made `PROJECT_MAP.md` fully generated and moved manual knowledge to context files.
- Added seed-file behavior so `--force` preserves `.claude/context/` and
  `.claude/reference/`.
- Smoke-tested preservation with sentinel entries.

### Medium — Project discovery ignored the riskiest surfaces

The old map scanned only `lib/`, misclassified `screenshot_detection.dart` as a
screen, used a non-portable route pattern, undercounted Dart files, and omitted
Functions, Worker, Rules, tests, and large-file hotspots.

Resolution:
- Added backend, test, and hotspot inventories.
- Fixed screen matching, route parsing, dependency display, and Dart-file counting.

### Medium — Rules were too absolute but not enforceable

Rules such as “never run tests,” “never add folders,” “always mounted after every
await,” and “never setState in a large widget” were either harmful or too broad.
At the same time, important rules such as single-source ownership, transaction
requirements, and schema/rules parity were absent.

Resolution:
- Scoped local UI state, lifecycle checks, and architecture decisions accurately.
- Added explicit ownership, async ordering, idempotency, migration/default, and
  cross-system schema guardrails.
- Paired instructions with executable validation.

### Medium — Generic snippets encoded unsafe patterns

The generated auth interceptor assumed a custom refresh-token flow and retried
with a new unconfigured Dio instance. Copying it into Badminton Smash would have
bypassed the configured Firebase-token client behavior.

Resolution:
- Removed generic auth/API/Provider code snippets.
- Kept only a README requiring snippets to be extracted from verified production code.

### Medium — Hotspots concentrate regression risk

The project contains multiple screens above 1,000 lines and two central providers
around 1,700 lines. Most repeated bugs involve ownership or coordination across
these files.

Mitigation added:
- Project map highlights files at or above 600 lines.
- Agent rules require extracting a testable seam when new behavior would add a
  new responsibility.
- `verify-project` generates `.claude/PROJECT_RISKS.md` and flags multiple large
  providers as an ownership-risk review signal.

Remaining work:
- Extract session/card/notification responsibilities from `SessionProvider`.
- Extract persistence/sync/scoring responsibilities from `TrackerProvider`.
- Decompose the largest screens by user flow rather than only private build methods.

## Recurring Patterns Observed

1. Duplicate or stale state between `SessionProvider` and `TrackerProvider`.
2. Slow async cleanup blocking visible auth/navigation state.
3. Client, backend, Rules, and persisted defaults changing at different times.
4. Multi-document operations lacking transaction/status preconditions.
5. Scheduled or retryable operations requiring deterministic idempotency.
6. Older Firestore/Hive/in-memory objects missing newly required fields.
7. Mobile compact-layout and system-inset regressions.

## Executable Recurring-Risk Guard

The setup installs
`.agents/skills/verify-project/scripts/detect-recurring-risks.sh`, mirrors it to
Claude and legacy Codex skill locations, and runs it automatically during setup
and every `verify-project` execution.

Deterministic blockers:
- Stale unsafe agent instructions (`custom JWT`, generic `AuthInterceptor`,
  `.Codex`, `dart fix --apply`, or a test prohibition).
- Direct `Navigator.push`/`MaterialPageRoute` use when go_router is configured.
- Dart `print()` calls.

Heuristic review signals:
- Missing Flutter tests, missing Rules emulator coverage, or backend checks with
  no behavioral-test signal.
- Direct network/Firebase/storage construction in presentation code.
- Awaited cleanup helpers that may block visible auth/navigation state.
- `SafeArea(top: false)` inside page/screen files.
- Dart files at or above 600 lines and multiple large Provider owners.
- Large Provider files without a focused filename-matching test.
- Batch writes without a visible transaction, plus retryable jobs that appear
  to create auto-ID documents.
- Functions checks that cover Rules/emulators but not callable/trigger/scheduled
  handler behavior.

The generated report labels warnings as heuristic so agents do not pretend
regex can prove a semantic bug. It also carries a cross-system checklist for
schema/rules/default/migration parity, deterministic idempotency, legacy data
compatibility, and compact-width/system-inset verification.

## Score

| Area | Before | After | Notes |
|---|---:|---:|---|
| Context accuracy | 4/10 | 9/10 | Actual Firebase/Worker ownership is explicit |
| Agent compatibility | 3/10 | 9/10 | Valid `.agents/skills`, scoped AGENTS, Codex reviewer |
| Project discovery | 5/10 | 9/10 | Backends, tests, routes, hotspots included |
| Validation automation | 3/10 | 9/10 | Safe verify workflow plus recurring-risk detector |
| Regression prevention | 1/10 | 7/10 | 17 Flutter tests, Rules tests, and risk guard exist; central ownership gaps remain |
| State ownership guidance | 4/10 | 9/10 | Session vs Tracker ownership documented |
| Backend/security guidance | 4/10 | 9/10 | Auth, Rules, transaction, idempotency checks |
| Upgrade safety | 3/10 | 9/10 | Context/reference files survive `--force` |
| Maintainability guidance | 5/10 | 8/10 | Hotspots visible; extraction rules added |
| Documentation quality | 7/10 | 9/10 | Current commands and integration routes documented |
| **Total** | **39/100** | **87/100** | Main remaining gap is central ownership and Functions behavior coverage |

## Flow Analysis

### Agent Context Flow

`AGENTS.md` / `CLAUDE.md` → scoped rules → `CONTEXT.md` and integration context →
source inspection → implementation.

### Discovery Flow

Filesystem and configuration → `scan-project` → generated `PROJECT_MAP.md` →
features, providers, routes, backends, tests, and hotspots.

### Validation Flow

Changed files → recurring-risk detector → `PROJECT_RISKS.md` → Dart formatting →
Flutter analyze → Flutter tests when present → Functions/Rules check → Worker
syntax/tests → final report.

### Bug-Learning Flow

Bug symptom → full boundary trace → root cause → focused fix → regression test or
documented test gap → recurring-pattern update in known issues.

## Prioritized Next Actions

1. Add focused `SessionProvider` tests for auth-state publication, cleanup
   ordering, and Session/Tracker ownership boundaries.
2. Add Functions domain tests for idempotent rewards, reminders, and cross-document writes.
3. Expand Firestore Rules emulator scenarios whenever roles/status transitions change.
4. Extract testable services from the two central providers before adding major features.
5. Backfill regression-test references for the resolved bugs already recorded.

## Keep

- Feature-first domain/data/presentation boundaries.
- Root domain language in `CONTEXT.md`.
- Historical known-issue root-cause records.
- Worker domain tests and server-authoritative mutation model.

## Change in a Rebuild

- Start with ownership and contract tests before UI growth.
- Keep provider classes as orchestration facades over smaller services.
- Treat Firestore Rules, Functions/Worker handlers, and Dart models as one versioned schema.
- Generate navigation context, but keep durable project knowledge outside generated files.
