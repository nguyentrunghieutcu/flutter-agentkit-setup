#!/usr/bin/env bash
# setup-agent-config.sh
# Creates multi-agent configuration for Flutter and supports two workflows:
#   1. New project      — creates a Flutter app and Clean Architecture scaffold
#   2. Existing project — installs agent configuration in an existing Flutter project
#
# Interactive usage:
#   bash setup-agent-config.sh
#
# Non-interactive usage:
#   bash setup-agent-config.sh --new my_app
#   bash setup-agent-config.sh --new my_app --path ./projects --org com.example
#   bash setup-agent-config.sh --existing /path/to/flutter-project
#   bash setup-agent-config.sh --existing . --force
#
# Options:
#   --new [name]       Creates a new Flutter project
#   --existing [path]  Sets up an existing Flutter project
#   --path <path>      Parent directory (new) or project path (existing)
#   --org <domain>     Organization for flutter create (default: com.example)
#   --skip-deps        Skips baseline dependency installation for a new project
#   --force            Overwrites all existing agent configuration
#   -h, --help         Shows help

set -euo pipefail

FORCE=0
MODE=""
PROJECT_NAME=""
PROJECT_PATH=""
ORG="com.example"
INSTALL_DEPS=1

log()   { printf '  %s\n' "$1"; }
step()  { printf '\n\033[1m%s\033[0m\n' "$1"; }
ok()    { printf '  \033[32m✓\033[0m %s\n' "$1"; }
skip()  { printf '  \033[33m·\033[0m %s (already exists, skipped)\n' "$1"; }
warn()  { printf '  \033[31m!\033[0m %s\n' "$1"; }
fatal() { warn "$1"; exit 1; }

usage() {
  cat <<'USAGE_EOF'
Flutter AgentKit setup

Interactive mode:
  bash setup-agent-config.sh

Run directly:
  bash setup-agent-config.sh --new my_app
  bash setup-agent-config.sh --new my_app --path ./projects --org com.company
  bash setup-agent-config.sh --existing /path/to/project
  bash setup-agent-config.sh --existing . --force

Options:
  --new [name]       Creates a Flutter project and Clean Architecture scaffold
  --existing [path]  Installs agent configuration in an existing Flutter project
  --path <path>      Parent directory for a new project or an existing project path
  --org <domain>     Organization for flutter create (default: com.example)
  --skip-deps        Skips flutter pub add for a new project
  --force            Overwrites existing agent configuration
  -h, --help         Shows this help
USAGE_EOF
}

require_value() {
  local option="$1"
  local value="${2:-}"
  [[ -n "$value" && "$value" != --* ]] || fatal "Missing value for $option"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --new)
      MODE="new"
      if [[ $# -gt 1 && "$2" != --* ]]; then
        PROJECT_NAME="$2"
        shift
      fi
      ;;
    --existing)
      MODE="existing"
      if [[ $# -gt 1 && "$2" != --* ]]; then
        PROJECT_PATH="$2"
        shift
      fi
      ;;
    --path)
      require_value "$1" "${2:-}"
      PROJECT_PATH="$2"
      shift
      ;;
    --org)
      require_value "$1" "${2:-}"
      ORG="$2"
      shift
      ;;
    --skip-deps)
      INSTALL_DEPS=0
      ;;
    --force)
      FORCE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fatal "Invalid option: $1. Use --help to view usage."
      ;;
  esac
  shift
done

choose_mode() {
  step "🚀 Flutter AgentKit"
  printf '  Select project type:\n'
  printf '  1) New project\n'
  printf '  2) Existing project\n\n'

  local choice=""
  while true; do
    read -r -p "  Enter choice [1-2]: " choice
    case "$choice" in
      1) MODE="new"; break ;;
      2) MODE="existing"; break ;;
      *) warn "Please enter 1 or 2." ;;
    esac
  done
}

# write_file <path> — content is read from stdin.
# Skips the file when it already exists and --force is not specified.
write_file() {
  local path="$1"
  if [[ -f "$path" && "$FORCE" -eq 0 ]]; then
    skip "$path"
    cat > /dev/null
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  ok "$path"
}

install_new_project_dependencies() {
  [[ "$INSTALL_DEPS" -eq 1 ]] || {
    warn "Skipped dependency installation (--skip-deps)."
    return 0
  }

  step "📦 Installing baseline dependencies"
  log "provider · go_router · dio · dartz · hive · hive_flutter · shared_preferences"
  flutter pub add provider go_router dio dartz hive hive_flutter shared_preferences
  ok "Dependencies added to pubspec.yaml"
}

scaffold_clean_architecture() {
  local package_name="$1"

  step "🏗️ Creating the Clean Architecture scaffold"
  log "Feature-first, three layers: presentation → domain ← data"

  rm -f lib/main.dart test/widget_test.dart

  mkdir -p \
    lib/core/constants \
    lib/core/error \
    lib/core/network \
    lib/core/router \
    lib/core/theme \
    lib/core/utils \
    lib/features/home/data/models \
    lib/features/home/data/repositories \
    lib/features/home/data/sources \
    lib/features/home/domain/entities \
    lib/features/home/domain/repositories \
    lib/features/home/domain/usecases \
    lib/features/home/presentation/providers \
    lib/features/home/presentation/screens \
    lib/features/home/presentation/widgets \
    lib/shared/providers \
    lib/shared/widgets \
    docs

  cat > lib/main.dart <<MAIN_EOF
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:${package_name}/app.dart';
import 'package:${package_name}/features/home/data/repositories/app_info_repository_impl.dart';
import 'package:${package_name}/features/home/data/sources/app_info_local_source.dart';
import 'package:${package_name}/features/home/domain/usecases/get_app_info_use_case.dart';
import 'package:${package_name}/features/home/presentation/providers/app_info_provider.dart';

void main() {
  final dataSource = AppInfoLocalSource();
  final repository = AppInfoRepositoryImpl(dataSource);
  final getAppInfo = GetAppInfoUseCase(repository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppInfoProvider(getAppInfo)..load(),
        ),
      ],
      child: const App(),
    ),
  );
}
MAIN_EOF

  cat > lib/app.dart <<APP_EOF
import 'package:flutter/material.dart';

import 'package:${package_name}/core/router/app_router.dart';
import 'package:${package_name}/core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter AgentKit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
APP_EOF

  cat > lib/core/constants/app_constants.dart <<'APP_CONSTANTS_EOF'
abstract final class AppConstants {
  static const appName = 'Flutter AgentKit';
  static const apiBaseUrl = 'https://api.example.com';
}
APP_CONSTANTS_EOF

  cat > lib/core/constants/app_spacing.dart <<'APP_SPACING_EOF'
abstract final class AppSpacing {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 24.0;
}
APP_SPACING_EOF

  cat > lib/core/error/failure.dart <<'FAILURE_EOF'
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}
FAILURE_EOF

  cat > lib/core/network/api_client.dart <<'API_CLIENT_EOF'
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl})
      : dio = Dio(BaseOptions(baseUrl: baseUrl));

  final Dio dio;
}
API_CLIENT_EOF

  cat > lib/core/router/app_router.dart <<APP_ROUTER_EOF
import 'package:go_router/go_router.dart';

import 'package:${package_name}/features/home/presentation/screens/home_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
APP_ROUTER_EOF

  cat > lib/core/theme/app_theme.dart <<'APP_THEME_EOF'
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      );

  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
APP_THEME_EOF

  cat > lib/core/utils/json_map.dart <<'JSON_MAP_EOF'
typedef JsonMap = Map<String, dynamic>;
JSON_MAP_EOF

  cat > lib/features/home/domain/entities/app_info.dart <<'APP_INFO_ENTITY_EOF'
class AppInfo {
  const AppInfo({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
APP_INFO_ENTITY_EOF

  cat > lib/features/home/domain/repositories/app_info_repository.dart <<APP_INFO_REPOSITORY_EOF
import 'package:dartz/dartz.dart';

import 'package:${package_name}/core/error/failure.dart';
import 'package:${package_name}/features/home/domain/entities/app_info.dart';

abstract interface class AppInfoRepository {
  Future<Either<Failure, AppInfo>> getAppInfo();
}
APP_INFO_REPOSITORY_EOF

  cat > lib/features/home/domain/usecases/get_app_info_use_case.dart <<GET_APP_INFO_EOF
import 'package:dartz/dartz.dart';

import 'package:${package_name}/core/error/failure.dart';
import 'package:${package_name}/features/home/domain/entities/app_info.dart';
import 'package:${package_name}/features/home/domain/repositories/app_info_repository.dart';

class GetAppInfoUseCase {
  const GetAppInfoUseCase(this._repository);

  final AppInfoRepository _repository;

  Future<Either<Failure, AppInfo>> call() => _repository.getAppInfo();
}
GET_APP_INFO_EOF

  cat > lib/features/home/data/models/app_info_model.dart <<APP_INFO_MODEL_EOF
import 'package:${package_name}/core/utils/json_map.dart';
import 'package:${package_name}/features/home/domain/entities/app_info.dart';

class AppInfoModel {
  const AppInfoModel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory AppInfoModel.fromJson(JsonMap json) => AppInfoModel(
        title: json['title'] as String,
        description: json['description'] as String,
      );

  JsonMap toJson() => {
        'title': title,
        'description': description,
      };

  AppInfo toEntity() => AppInfo(
        title: title,
        description: description,
      );
}
APP_INFO_MODEL_EOF

  cat > lib/features/home/data/sources/app_info_local_source.dart <<APP_INFO_SOURCE_EOF
import 'package:${package_name}/features/home/data/models/app_info_model.dart';

class AppInfoLocalSource {
  Future<AppInfoModel> load() async {
    return const AppInfoModel(
      title: 'Clean Architecture is ready',
      description: 'Presentation, Domain and Data are separated by feature.',
    );
  }
}
APP_INFO_SOURCE_EOF

  cat > lib/features/home/data/repositories/app_info_repository_impl.dart <<APP_INFO_REPOSITORY_IMPL_EOF
import 'package:dartz/dartz.dart';

import 'package:${package_name}/core/error/failure.dart';
import 'package:${package_name}/features/home/data/sources/app_info_local_source.dart';
import 'package:${package_name}/features/home/domain/entities/app_info.dart';
import 'package:${package_name}/features/home/domain/repositories/app_info_repository.dart';

class AppInfoRepositoryImpl implements AppInfoRepository {
  const AppInfoRepositoryImpl(this._source);

  final AppInfoLocalSource _source;

  @override
  Future<Either<Failure, AppInfo>> getAppInfo() async {
    try {
      final model = await _source.load();
      return Right(model.toEntity());
    } catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }
}
APP_INFO_REPOSITORY_IMPL_EOF

  cat > lib/features/home/presentation/providers/app_info_provider.dart <<APP_INFO_PROVIDER_EOF
import 'package:flutter/foundation.dart';

import 'package:${package_name}/features/home/domain/entities/app_info.dart';
import 'package:${package_name}/features/home/domain/usecases/get_app_info_use_case.dart';

class AppInfoProvider extends ChangeNotifier {
  AppInfoProvider(this._getAppInfo);

  final GetAppInfoUseCase _getAppInfo;

  AppInfo? _info;
  String? _error;
  bool _isLoading = false;

  AppInfo? get info => _info;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getAppInfo();
    result.fold(
      (failure) => _error = failure.message,
      (info) => _info = info,
    );

    _isLoading = false;
    notifyListeners();
  }
}
APP_INFO_PROVIDER_EOF

  cat > lib/features/home/presentation/widgets/architecture_card.dart <<APP_ARCHITECTURE_CARD_EOF
import 'package:flutter/material.dart';

import 'package:${package_name}/core/constants/app_spacing.dart';

class ArchitectureCard extends StatelessWidget {
  const ArchitectureCard({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
APP_ARCHITECTURE_CARD_EOF

  cat > lib/shared/widgets/app_loading_indicator.dart <<'APP_LOADING_EOF'
import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
APP_LOADING_EOF

  cat > lib/shared/widgets/app_error_view.dart <<APP_ERROR_EOF
import 'package:flutter/material.dart';

import 'package:${package_name}/core/constants/app_spacing.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
APP_ERROR_EOF

  cat > lib/features/home/presentation/screens/home_screen.dart <<HOME_SCREEN_EOF
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:${package_name}/core/constants/app_spacing.dart';
import 'package:${package_name}/features/home/presentation/providers/app_info_provider.dart';
import 'package:${package_name}/features/home/presentation/widgets/architecture_card.dart';
import 'package:${package_name}/shared/widgets/app_error_view.dart';
import 'package:${package_name}/shared/widgets/app_loading_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter AgentKit')),
      body: Consumer<AppInfoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const AppLoadingIndicator();
          if (provider.error != null) {
            return AppErrorView(
              message: provider.error!,
              onRetry: provider.load,
            );
          }

          final info = provider.info;
          if (info == null) return const SizedBox.shrink();

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ArchitectureCard(
                title: info.title,
                description: info.description,
              ),
            ),
          );
        },
      ),
    );
  }
}
HOME_SCREEN_EOF

  touch lib/shared/providers/.gitkeep

  cat > docs/architecture.md <<'ARCHITECTURE_EOF'
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
ARCHITECTURE_EOF

  if command -v dart >/dev/null 2>&1; then
    dart format lib >/dev/null
  fi

  ok "Clean Architecture scaffold created in lib/"
}

prepare_new_project() {
  command -v flutter >/dev/null 2>&1 || fatal "Flutter CLI was not found on PATH."

  if [[ -z "$PROJECT_NAME" ]]; then
    read -r -p "  Project name (snake_case): " PROJECT_NAME
  fi

  [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9_]*$ ]] || \
    fatal "Project name must be snake_case and begin with a lowercase letter. Example: my_app"

  local parent="${PROJECT_PATH:-$(pwd)}"
  if [[ -t 0 && -z "$PROJECT_PATH" ]]; then
    local input=""
    read -r -p "  Parent directory [${parent}]: " input
    [[ -z "$input" ]] || parent="$input"

    input=""
    read -r -p "  Organization [${ORG}]: " input
    [[ -z "$input" ]] || ORG="$input"
  fi

  mkdir -p "$parent"
  parent="$(cd "$parent" && pwd)"
  local target="$parent/$PROJECT_NAME"

  if [[ -e "$target" && -n "$(ls -A "$target" 2>/dev/null || true)" ]]; then
    fatal "Target directory already exists and is not empty: $target"
  fi

  step "✨ Creating a new Flutter project"
  log "Name: $PROJECT_NAME"
  log "Target: $target"
  log "Org:  $ORG"

  (cd "$parent" && flutter create --org "$ORG" "$PROJECT_NAME")
  cd "$target"

  install_new_project_dependencies
  scaffold_clean_architecture "$PROJECT_NAME"
}

prepare_existing_project() {
  local target="${PROJECT_PATH:-$(pwd)}"

  if [[ -t 0 && -z "$PROJECT_PATH" && ! -f "$target/pubspec.yaml" ]]; then
    local input=""
    read -r -p "  Flutter project path [${target}]: " input
    [[ -z "$input" ]] || target="$input"
  fi

  [[ -d "$target" ]] || fatal "Directory not found: $target"
  cd "$target"
  [[ -f pubspec.yaml ]] || fatal "pubspec.yaml was not found in $(pwd)"
  [[ -d lib ]] || fatal "lib/ directory was not found in $(pwd)"
}

if [[ -z "$MODE" ]]; then
  [[ -t 0 ]] || fatal "Project mode is required. Use --new or --existing."
  choose_mode
fi

case "$MODE" in
  new) prepare_new_project ;;
  existing) prepare_existing_project ;;
  *) fatal "Invalid mode: $MODE" ;;
esac

ROOT="$(pwd)"
DATE="$(date +%Y-%m-%d)"

step "🤖 Starting agent configuration setup"
log "Mode: $MODE"
log "Directory: $ROOT"

# ─────────────────────────────────────────────────────────────
step "📁 Creating directory structure"
mkdir -p .claude/rules .claude/reference .claude/context \
         .claude/skills/scan-project .claude/prompts \
         .claude/snippets .claude/agents .claude/memory \
         .codex/skills
ok ".claude/{rules,reference,context,skills,prompts,snippets,agents,memory}"
ok ".codex/skills"

# ─────────────────────────────────────────────────────────────
step "📄 CLAUDE.md (root)"
write_file "CLAUDE.md" << 'CLAUDE_EOF'
# Flutter Project

## Stack
- Flutter stable / Dart 3.x
- State: Provider + ChangeNotifier
- Navigation: go_router
- HTTP: Dio + interceptors
- Storage: Hive / shared_preferences
- Auth: custom JWT

## Commands
- `flutter run` — dev
- `flutter run --release` — release
- `flutter analyze` — lint
- `dart fix --apply` — auto fix
- `flutter pub get` — install deps
- `flutter gen-l10n` — regen i18n
- Never run `flutter build` or `flutter test` unless explicitly asked

## Git
Read `docs/git-flow-release.md` before any branch, merge, or release work.

## Cross-agent note
This project is configured for both Claude Code (`.claude/`) and Codex CLI
(`AGENTS.md` + `lib/AGENTS.md`). Content in `.claude/rules/` and root `AGENTS.md`
must stay equivalent — `.claude/reference/`, `.claude/context/`, and
`.claude/snippets/` are shared, tool-agnostic docs any agent can read on request.

---

## rules/ — Loaded every session (via @import)

@.claude/rules/workflow.md
@.claude/rules/structure.md
@.claude/rules/flutter.md

> `bugfix.md`, `new-feature.md`, `decisions.md` — read on demand per workflow.md.

---

## reference/ — Read for the specific task type

| File | Read when |
|---|---|
| `.claude/reference/patterns.md` | Writing provider / repo / usecase / form / navigation |
| `.claude/reference/api.md` | Writing API call, creating model, handling HTTP errors |

---

## context/ — Read at session start or when task scope is unclear

| File | Read when |
|---|---|
| `.claude/context/sprint.md` | Starting a new session or task scope is ambiguous |
| `.claude/context/known-issues.md` | Before fixing a bug or editing a fragile area |
| `.claude/context/changelog.md` | Need to know what changed recently |

---

## skills/ — Invoked by name

| Skill | Invoke when |
|---|---|
| `/scan-project` | `PROJECT_MAP.md` missing or > 7 days old |

Re-run scan manually anytime: `bash .claude/skills/scan-project/scan.sh`

---

## prompts/ — User-invoked only

| Prompt | Invoke when |
|---|---|
| `/review-code <file>` | Reviewing a file or diff against project standards |
| `/add-feature <name>` | Starting a new feature end-to-end |
| `/debug <description>` | Structured bug investigation |

---

## snippets/ — Copy directly into project

| File | Use for |
|---|---|
| `.claude/snippets/base_provider.dart` | Base class for feature providers |
| `.claude/snippets/api_interceptor.dart` | Auth + error Dio interceptors |

---

## memory/ — Written by MCP tool only, agent does not edit manually

| File | MCP tier | Written when |
|---|---|---|
| `.claude/memory/project_facts.md` | `semantic` | New convention or stack fact learned |
| `.claude/memory/decisions_log.md` | `episodic` | Specific decision made in a session |
| `.claude/memory/workflows.md` | `procedural` | Repeatable workflow optimized |
CLAUDE_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/rules/"

write_file ".claude/rules/workflow.md" << 'WORKFLOW_EOF'
# Workflow Rules

## Before every task
1. Check `.claude/PROJECT_MAP.md` exists and is recent.
   - Missing or stale (> 7 days) → run `bash .claude/skills/scan-project/scan.sh` first.
   - Exists → read "Structure" and "Features" sections before touching any file.
2. Read only the rules file relevant to the task type:
   - Bug fix → `.claude/rules/bugfix.md`
   - New feature → `.claude/rules/new-feature.md`
   - Architecture question → `.claude/rules/decisions.md`

## While working
- Read a file before editing it.
- Keep changes minimal and scoped to the stated task.
- Follow the pattern already in the file being edited — do not introduce new patterns.
- Do not add packages to `pubspec.yaml` without explicit user approval.
- Do not reformat, reorder imports, or touch unrelated code.

## After completing a task
- If a file or folder was created or moved → update `.claude/PROJECT_MAP.md`
  (or re-run `bash .claude/skills/scan-project/scan.sh`).
- If a new Provider was added → verify it appears after re-scan.
- Append completion summary:

```
## Completed
- [x] <what was done>
- [x] PROJECT_MAP.md updated (if structure changed)
- [x] No unrelated files changed
```

## Never do
- Add, move, or delete folders without user confirmation.
- Run `flutter build`, `flutter test`, or `dart compile` unless asked.
- Use `print()` — use `debugPrint()` only, remove before finishing.
- Create `*_test.dart` files unless tests are explicitly requested.
WORKFLOW_EOF

write_file ".claude/rules/structure.md" << 'STRUCTURE_EOF'
# Structure Rules

## Source of truth
`.claude/PROJECT_MAP.md` is the single source of truth for what exists in this project.
It is generated by `bash .claude/skills/scan-project/scan.sh` — do not hand-edit the
generated tables, only the "Sensitive Areas" and "Change Log" sections.
- Do not create files in locations not reflected in PROJECT_MAP.md without asking.
- Do not assume a folder exists — verify in PROJECT_MAP.md first.
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
STRUCTURE_EOF

write_file ".claude/rules/flutter.md" << 'FLUTTER_EOF'
---
paths:
  - "lib/**/*.dart"
---

# Flutter / Dart Coding Rules

## Provider
- Extend `ChangeNotifier`. Always call `notifyListeners()` after mutating state.
- Keep `_isLoading`, `_error`, and domain state as private fields with public getters.
- Use `Consumer<T>` for scoped rebuilds. Use `context.read<T>()` only in callbacks.
- Never call `context.watch` or `context.read` in a method called during `build`.
- Register in `main.dart` `MultiProvider`. Use `ChangeNotifierProxyProvider` when dependent.

## Widgets
- Prefer `StatelessWidget` + Provider over `StatefulWidget`.
- Always use `const` constructors where possible.
- Break `build` methods longer than ~40 lines into private `_build*` methods.
- Never call `setState` in a large widget — push state to the Provider layer.

## Lifecycle
- Dispose every `TextEditingController`, `AnimationController`, `StreamSubscription`.
- Add `if (!mounted) return;` after every `await` inside a `StatefulWidget`.

## Navigation
- Use `context.go()` for root/tab navigation (replaces stack).
- Use `context.push()` when back navigation is needed.
- Never use `Navigator.push` or `MaterialPageRoute` directly.

## Style
- Never hardcode colors: use `Theme.of(context).colorScheme.*`
- Never hardcode font sizes: use `Theme.of(context).textTheme.*`
- Never install new icon packages — use `Icons.*` or existing assets.

## Lists
- Always use `ListView.builder` or `SliverList` for dynamic lists.
- Never build lists with `.map().toList()` inside `ListView` children.

## API
- Use the shared Dio client from `lib/core/network/`. Never instantiate Dio in a feature.
- Repositories return `Either<Failure, T>`. Catch exceptions inside the repository.
- Use `FormData` + `MultipartFile` for file uploads — never embed base64 in JSON.

## Code hygiene
- Remove all `debugPrint`, unused imports, dead code before finishing.
- Never use `print()`.
- `dart fix --apply` before considering any task complete.
FLUTTER_EOF

write_file ".claude/rules/bugfix.md" << 'BUGFIX_EOF'
---
paths:
  - "lib/**/*.dart"
---

# Bug Fix Rules

## Diagnose before touching code
1. Identify which layer the bug lives in: widget → provider → usecase → repository → network.
2. Read the relevant screen, provider, and repository files before any change.
3. Do not assume the bug is where the symptom appears.

## Common Flutter/Provider bugs

**UI not updating**
Cause: `notifyListeners()` not called, or called before state mutation.
Fix: mutate state first, then `notifyListeners()`.

**`setState called after dispose`**
Cause: async completes after widget leaves tree.
Fix: `if (!mounted) return;` after every `await` in a `StatefulWidget`.

**`ProviderNotFoundException`**
Cause: widget is outside `MultiProvider` tree, or wrong `BuildContext`.
Fix: verify provider is registered in `main.dart`.

**Infinite rebuild**
Cause: `context.watch` inside a method called from `build`, or `notifyListeners()` in constructor.
Fix: move `watch` to `Consumer` builder.

**API result not shown in UI**
Trace: API response → model `fromJson` → repository → usecase → provider field →
`notifyListeners()` → `Consumer` rebuild. Find where the chain breaks.

**Memory leak / dispose error**
Fix: override `dispose()`, call `.dispose()` on every controller and `.cancel()` on subscriptions.

## After the fix
- Remove any `debugPrint` added during investigation.
- State root cause clearly in completion summary.
BUGFIX_EOF

write_file ".claude/rules/new-feature.md" << 'NEWFEATURE_EOF'
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
NEWFEATURE_EOF

write_file ".claude/rules/decisions.md" << 'DECISIONS_EOF'
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
DECISIONS_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/reference/"

write_file ".claude/reference/patterns.md" << 'PATTERNS_EOF'
# Patterns

> Read when writing a provider, repository, use case, form, or navigation call.

## Provider

```dart
class CartProvider extends ChangeNotifier {
  final FetchCartUseCase _fetchCart;
  CartProvider({required FetchCartUseCase fetchCart}) : _fetchCart = fetchCart;

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchCart();
    result.fold(
      (failure) => _error = failure.message,
      (items) => _items = items,
    );

    _isLoading = false;
    notifyListeners();
  }
}
```

## Consumer (scoped rebuild)

```dart
Consumer<CartProvider>(
  builder: (context, cart, _) {
    if (cart.isLoading) return const AppLoadingIndicator();
    if (cart.error != null) return AppErrorView(message: cart.error!);
    return CartList(items: cart.items);
  },
)

// One-time read in a callback only
onPressed: () => context.read<CartProvider>().fetchCart();
```

## Registering providers in main.dart

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
      create: (ctx) => CartProvider(
        fetchCart: FetchCartUseCase(ctx.read<CartRepository>()),
      ),
      update: (_, auth, previous) => previous!..onAuthChanged(auth),
    ),
  ],
  child: const MyApp(),
)
```

## Repository

```dart
// domain — abstract
abstract class CartRepository {
  Future<Either<Failure, List<CartItem>>> fetchCart();
}

// data — concrete
class CartRepositoryImpl implements CartRepository {
  final CartRemoteSource _remote;
  CartRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<CartItem>>> fetchCart() async {
    try {
      final models = await _remote.getCart();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

## Use case

```dart
class FetchCartUseCase {
  final CartRepository _repo;
  const FetchCartUseCase(this._repo);
  Future<Either<Failure, List<CartItem>>> call() => _repo.fetchCart();
}
```

## JSON model

```dart
class CartItemModel {
  final String id;
  final int quantity;

  const CartItemModel({required this.id, required this.quantity});

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    id: json['id'] as String,
    quantity: json['quantity'] as int,
  );

  Map<String, dynamic> toJson() => {'id': id, 'quantity': quantity};

  CartItem toEntity() => CartItem(id: id, quantity: quantity);
}
```

## Navigation

```dart
context.go('/cart');          // replaces stack — use for tabs/root
context.push('/product/$id'); // adds to stack — use when back is needed
context.pop();
```

## Form

```dart
class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }
}
```
PATTERNS_EOF

write_file ".claude/reference/api.md" << 'API_EOF'
# API Reference

> Read before writing any API call, creating a model, or handling HTTP errors.
> Update this file whenever a new endpoint is integrated.

## HTTP Client

File: `lib/core/network/api_client.dart`
Base URL: `AppConstants.baseUrl` in `lib/core/constants/app_constants.dart`
Auth: Bearer token injected by `AuthInterceptor` — do not add headers manually.
Errors: handled centrally in `ApiErrorInterceptor` — do not wrap calls in try/catch in providers.

```dart
class ProductRemoteSource {
  final ApiClient _client;
  ProductRemoteSource(this._client);

  Future<List<ProductModel>> getProducts() async {
    final response = await _client.get('/products');
    return (response.data['data'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
  }
}
```

## Response envelope

```json
{ "success": true, "data": {}, "message": "OK", "errors": null }
```

Paginated:
```json
{ "data": [], "meta": { "current_page": 1, "last_page": 5, "per_page": 20, "total": 98 } }
```

## File upload

```dart
final formData = FormData.fromMap({
  'avatar': await MultipartFile.fromFile(path, filename: 'avatar.jpg'),
  'user_id': userId,
});
await _client.post('/user/avatar', data: formData);
```

Never embed file bytes as base64 in a JSON body.

## Endpoint Registry

### Auth
| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/auth/login` | `{email, password}` | `{token, user}` |
| POST | `/auth/logout` | — | `{message}` |
| GET | `/auth/me` | — | `UserModel` |
| POST | `/auth/refresh` | `{refresh_token}` | `{token}` |

> Add feature endpoints below as they are integrated.

## HTTP Error Codes

| Status | Meaning | Handled by |
|---|---|---|
| 401 | Unauthenticated | Interceptor → redirect to login |
| 403 | Forbidden | Show error, do not redirect |
| 422 | Validation | Parse `errors` field, show per-field |
| 500 | Server error | Show generic message |
API_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/context/"

write_file ".claude/context/sprint.md" << 'SPRINT_EOF'
# Current Sprint

> Read at the start of a new session or when a task scope is unclear.
> Agent updates "Done" section after completing a task.

## In Progress
<!-- List tasks currently being worked on -->

## Blocked
<!-- Tasks waiting on something external -->

## Done This Sprint
<!-- Agent appends here after completing a task -->

## Notes
<!-- Anything the team needs to remember mid-sprint -->
SPRINT_EOF

write_file ".claude/context/known-issues.md" << 'KNOWNISSUES_EOF'
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
KNOWNISSUES_EOF

write_file ".claude/context/changelog.md" << 'CHANGELOG_EOF'
# Changelog

> Read when you need to know what changed recently to avoid redoing work.
> Agent appends here after any structural, dependency, or pattern change.

## Format
```
### YYYY-MM-DD
- **[type]** description — reason
```
Types: `structure` `dependency` `pattern` `breaking` `fix`

---
CHANGELOG_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/prompts/"

write_file ".claude/prompts/review-code.md" << 'REVIEWCODE_EOF'
---
description: Reviews a file or diff for Flutter/Provider correctness, patterns, and style. User-invoked only.
disable-model-invocation: true
argument-hint: <file-path or branch>
---

# Code Review

## Target
$ARGUMENTS

Read the target file(s). Cross-reference against `.claude/rules/flutter.md`
and `.claude/reference/patterns.md`.

## Review checklist

**Provider**
- [ ] `notifyListeners()` called after mutation, not before
- [ ] No business logic inside widget `build()`
- [ ] `Consumer` used for scoped rebuilds
- [ ] `context.read` only in callbacks, never in `build`

**Lifecycle**
- [ ] Every controller disposed in `dispose()`
- [ ] `if (!mounted) return;` after every `await` in StatefulWidget

**Style**
- [ ] No hardcoded colors or font sizes
- [ ] No `Navigator.push` — go_router only
- [ ] No `print()` — removed before finishing
- [ ] `const` constructors used where possible

**Structure**
- [ ] File is in correct layer per `.claude/rules/structure.md`
- [ ] No cross-layer imports

## Output format
For each finding: **File:line** — what is wrong — concrete fix.
End with: `✅ No issues` or `⚠️ N issues found`.
REVIEWCODE_EOF

write_file ".claude/prompts/add-feature.md" << 'ADDFEATURE_EOF'
---
description: Starts a new Flutter feature end-to-end following project patterns. User-invoked only.
disable-model-invocation: true
argument-hint: <feature-name>
---

# Add Feature: $ARGUMENTS

Before writing any code:
1. Read `.claude/PROJECT_MAP.md` — confirm `$ARGUMENTS` feature does not already exist.
2. Read `.claude/reference/api.md` — note any existing endpoints for this domain.
3. Read `.claude/reference/patterns.md` — use these exact patterns.
4. Follow `.claude/rules/new-feature.md` step by step.

## Folder to create
`lib/features/$ARGUMENTS/`

## Build order
Domain → Data → Presentation → Wire up → Re-run scan-project

## Done when
- [ ] All layers implemented per `new-feature.md` checklist
- [ ] Provider registered in `main.dart`
- [ ] Route added in `app_router.dart`
- [ ] `bash .claude/skills/scan-project/scan.sh` re-run
- [ ] `context/changelog.md` updated with new entry
ADDFEATURE_EOF

write_file ".claude/prompts/debug.md" << 'DEBUG_EOF'
---
description: Structured bug investigation with full context. User-invoked only.
disable-model-invocation: true
argument-hint: <description of the bug>
---

# Debug: $ARGUMENTS

## Step 1 — Gather context
Read `.claude/context/known-issues.md` — is this bug already documented?

## Step 2 — Locate the layer
- Widget rendering → start in the screen file
- State not updating → start in the provider
- Wrong data → start in repository / remote source
- Network error → start in `lib/core/network/`

## Step 3 — Trace the data path
API response → `fromJson` → repository → use case → provider field →
`notifyListeners()` → `Consumer` rebuild. Find where the chain breaks.

## Step 4 — Apply fix
Follow `.claude/rules/bugfix.md`. Minimal change only.

## Step 5 — After fix
- Remove all `debugPrint` added during investigation.
- If unknown bug, add it to `.claude/context/known-issues.md`.
- Completion summary must state root cause explicitly.
DEBUG_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/snippets/"

write_file ".claude/snippets/base_provider.dart" << 'BASEPROVIDER_EOF'
// snippets/base_provider.dart
// Copy to lib/shared/providers/ or use as base class for feature providers.
// Replace <State> with your actual state type.

import 'package:flutter/foundation.dart';

abstract class BaseProvider<T> extends ChangeNotifier {
  T? _data;
  bool _isLoading = false;
  String? _error;

  T? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _data != null;
  bool get hasError => _error != null;

  @protected
  void setLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  @protected
  void setData(T data) {
    _data = data;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @protected
  void setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _data = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
BASEPROVIDER_EOF

write_file ".claude/snippets/api_interceptor.dart" << 'APIINTERCEPTOR_EOF'
// snippets/api_interceptor.dart
// Copy to lib/core/network/interceptors/.
// Handles: auth header injection, 401 token refresh, error mapping.

import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final String? Function() getToken;
  final Future<String?> Function() refreshToken;
  final VoidCallback onAuthExpired;

  AuthInterceptor({
    required this.getToken,
    required this.refreshToken,
    required this.onAuthExpired,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await refreshToken();
        if (newToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await Dio().fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {
        onAuthExpired();
      }
    }
    handler.next(err);
  }
}

class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final message = switch (status) {
      400 => 'Bad request',
      403 => 'Access denied',
      404 => 'Not found',
      422 => _parse422(err.response?.data),
      500 => 'Server error, please try again',
      null => 'No internet connection',
      _ => 'Unexpected error ($status)',
    };
    err.requestOptions.extra['parsedError'] = message;
    handler.next(err);
  }

  String _parse422(dynamic data) {
    try {
      final errors = data['errors'] as Map<String, dynamic>;
      return errors.values.first is List
          ? (errors.values.first as List).first.toString()
          : errors.values.first.toString();
    } catch (_) {
      return 'Validation error';
    }
  }
}
APIINTERCEPTOR_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/agents/"

write_file ".claude/agents/code-reviewer.md" << 'CODEREVIEWER_EOF'
---
name: code-reviewer
description: Reviews Flutter/Dart code for correctness, Provider patterns, performance, and style compliance. Invoke for PR review or before committing significant changes.
tools: Read, Grep, Glob
---

You are a senior Flutter engineer reviewing code in this project.

Review for:
1. **Correctness** — logic errors, null safety gaps, missing `dispose()`, `setState after dispose`
2. **Provider patterns** — `notifyListeners()` after mutation, no business logic in widgets
3. **Performance** — `const` constructors, `ListView.builder`, no heavy work in `build()`
4. **Style** — no hardcoded colors/sizes, no `Navigator.push`, no `print()`
5. **Structure** — files in correct layer, no cross-layer violations

For every finding, state: file and line number, what is wrong, concrete fix.
Do not suggest changes outside the files you were asked to review.
Do not propose switching to a different state management solution.
CODEREVIEWER_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/memory/"

write_file ".claude/memory/README.md" << 'MEMORYREADME_EOF'
# memory/

> Written by MCP tool `memory_save`. Agent does not edit these by hand.
> Read via `memory_search` / `memory_inject` — not by opening the file directly.

| File | MCP Tier | Written when |
|---|---|---|
| `project_facts.md` | `semantic` | New convention or stack fact learned |
| `decisions_log.md` | `episodic` | Specific decision made in a session |
| `workflows.md` | `procedural` | Repeatable workflow optimized |

Do not duplicate content already covered in `rules/` or `reference/`.
MEMORYREADME_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/skills/scan-project/"

write_file ".claude/skills/scan-project/SKILL.md" << 'SCANSKILL_EOF'
---
description: Scans the Flutter project source and regenerates .claude/PROJECT_MAP.md. Invoke when PROJECT_MAP.md is missing or more than 7 days old.
user-invocable: true
---

# Scan Project

Runs a real filesystem scan and regenerates `.claude/PROJECT_MAP.md` from
actual source — never guess or hand-write this file.

## Run it directly (fastest — no LLM tokens needed)
```bash
bash .claude/skills/scan-project/scan.sh
```

## If asked to do it manually instead, follow these steps

**1. Scan source tree**
```bash
find lib/ -type f -name "*.dart" | grep -v ".g.dart\|.freezed.dart\|.mocks.dart" | sort
```

**2. Scan dependencies**
```bash
awk '/^dependencies:/,/^dev_dependencies:/' pubspec.yaml
```

**3. Find all Providers**
```bash
grep -rl "extends ChangeNotifier" lib/ --include="*.dart"
```

**4. Find all Screens**
```bash
find lib/ -iname "*screen*.dart" -o -iname "*page*.dart" | sort
```

**5. Find route definitions**
```bash
grep -rn "GoRoute" lib/core/router/ --include="*.dart"
```

**6. Find shared widgets**
```bash
find lib/shared/widgets/ -name "*.dart" | sort
```

**7. Write `.claude/PROJECT_MAP.md`** — fill every table with real data.
Never leave placeholder rows. Report: feature count, provider count, any
structural anomalies noticed.
SCANSKILL_EOF

write_file ".claude/skills/scan-project/scan.sh" << 'SCANSCRIPT_EOF'
#!/usr/bin/env bash
# Re-scans the Flutter project and regenerates .claude/PROJECT_MAP.md
# Run anytime: bash .claude/skills/scan-project/scan.sh
set -euo pipefail

DATE="$(date +%Y-%m-%d)"
OUT=".claude/PROJECT_MAP.md"

if [[ ! -d lib ]]; then
  echo "⚠️  No lib/ directory found. Run this from the Flutter project root."
  exit 1
fi

TREE="$(find lib -maxdepth 4 -type d | sort | tail -n +2 | awk -F/ '{
  indent="";
  for(i=2;i<NF;i++) indent = indent "  ";
  print indent "├── " $NF "/"
}')"

DEPS="(pubspec.yaml not found)"
if [[ -f pubspec.yaml ]]; then
  # Keep keys at exactly two spaces of indentation (top-level package names)
  # and ignore nested lines (for example, "  flutter:\n    sdk: flutter").
  DEPS="$(awk '/^dependencies:/{f=1;next}/^dev_dependencies:/{f=0}f' pubspec.yaml \
    | grep -E '^  [^ ]' \
    | sed -E 's/^  ([a-zA-Z0-9_.-]+):[[:space:]]*(.*)$/| \1 | \2 |/' || true)"
  [[ -z "$DEPS" ]] && DEPS="| _(none found)_ | |"
fi

PROVIDERS="$(grep -rl 'extends ChangeNotifier' lib --include='*.dart' 2>/dev/null | sort || true)"
if [[ -n "$PROVIDERS" ]]; then
  PROVIDERS_TABLE="$(echo "$PROVIDERS" | while read -r f; do
    name=$(grep -oE '[A-Za-z_]+ extends ChangeNotifier' "$f" | head -1 | awk '{print $1}')
    echo "| \`$name\` | \`$f\` |"
  done)"
else
  PROVIDERS_TABLE="| _(none found yet)_ | |"
fi

SCREENS="$(find lib \( -iname '*screen*.dart' -o -iname '*page*.dart' \) 2>/dev/null | sort || true)"
if [[ -n "$SCREENS" ]]; then
  SCREENS_TABLE="$(echo "$SCREENS" | while read -r f; do
    name=$(basename "$f" .dart)
    echo "| \`$name\` | \`$f\` |"
  done)"
else
  SCREENS_TABLE="| _(none found yet)_ | |"
fi

ROUTES="$(grep -rn "path:\s*['\"]" lib/core/router 2>/dev/null | sed -E "s/^([^:]+):([0-9]+):.*path:\s*['\"]([^'\"]+)['\"].*/| \3 | \1:\2 |/" || true)"
[[ -z "$ROUTES" ]] && ROUTES="| _(none found yet — check lib/core/router/)_ | |"

WIDGETS="$(find lib/shared/widgets -name '*.dart' 2>/dev/null | sort || true)"
if [[ -n "$WIDGETS" ]]; then
  WIDGETS_TABLE="$(echo "$WIDGETS" | while read -r f; do
    name=$(basename "$f" .dart)
    echo "| \`$name\` | \`$f\` |"
  done)"
else
  WIDGETS_TABLE="| _(none found yet)_ | |"
fi

FEATURES_TABLE="| _(none found yet)_ | | |"
if [[ -d lib/features ]]; then
  FEATURES_TABLE="$(find lib/features -maxdepth 1 -mindepth 1 -type d | sort | while read -r d; do
    name=$(basename "$d")
    has_domain=$([[ -d "$d/domain" ]] && echo "✓" || echo "—")
    has_data=$([[ -d "$d/data" ]] && echo "✓" || echo "—")
    has_pres=$([[ -d "$d/presentation" ]] && echo "✓" || echo "—")
    echo "| $name | \`$d\` | domain:$has_domain data:$has_data presentation:$has_pres |"
  done)"
fi

DART_COUNT="$(find lib -name '*.dart' 2>/dev/null | grep -vc '.g.dart\|.freezed.dart\|.mocks.dart' || true)"
[[ -n "$DART_COUNT" ]] || DART_COUNT="0"
PROVIDER_COUNT="$(printf '%s\n' "$PROVIDERS" | sed '/^$/d' | wc -l | tr -d ' ')"
FEATURE_COUNT="0"
if [[ -d lib/features ]]; then
  FEATURE_COUNT="$(find lib/features -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')"
fi

cat > "$OUT" << MAPEOF
# PROJECT_MAP.md
> Generated: $DATE
> Source of truth for project structure. Regenerate anytime:
> \`bash .claude/skills/scan-project/scan.sh\`
> Do not hand-edit the generated tables — edit "Sensitive Areas" and "Change Log" only.

---

## Structure

\`\`\`
lib/
$TREE
\`\`\`

---

## Dependencies

| Package | Version |
|---|---|
$DEPS

---

## Features ($FEATURE_COUNT found)

| Feature | Path | Layers present |
|---|---|---|
$FEATURES_TABLE

---

## Providers ($PROVIDER_COUNT found)

| Provider | File |
|---|---|
$PROVIDERS_TABLE

---

## Screens

| Screen | File |
|---|---|
$SCREENS_TABLE

---

## Routes

| Path | Defined in |
|---|---|
$ROUTES

---

## Shared Widgets

| Widget | File |
|---|---|
$WIDGETS_TABLE

---

## Sensitive Areas
_(edit by hand — not overwritten by re-scan)_

| File / Folder | Why |
|---|---|
| \`lib/core/network/\` | Singleton Dio client — changes affect all API calls |
| \`lib/main.dart\` | Provider registration order matters |
| \`lib/core/router/\` | Route changes affect deep links and navigation |

---

## Change Log
_(edit by hand — not overwritten by re-scan)_

| Date | Change | Reason |
|---|---|---|
| $DATE | Initial scan | Generated by scan.sh |
MAPEOF

echo "✓ .claude/PROJECT_MAP.md regenerated"
echo "  Dart files: $DART_COUNT"
echo "  Features:   $FEATURE_COUNT"
echo "  Providers:  $PROVIDER_COUNT"
SCANSCRIPT_EOF
chmod +x .claude/skills/scan-project/scan.sh 2>/dev/null || true

# Mirror skill into .codex/ (Codex CLI reads compatible SKILL.md format too)
if [[ "$FORCE" -eq 1 || ! -d .codex/skills/scan-project ]]; then
  mkdir -p .codex/skills/scan-project
  cp .claude/skills/scan-project/SKILL.md .codex/skills/scan-project/SKILL.md
  cp .claude/skills/scan-project/scan.sh .codex/skills/scan-project/scan.sh
  chmod +x .codex/skills/scan-project/scan.sh 2>/dev/null || true
  ok ".codex/skills/scan-project/ (mirrored for Codex CLI)"
else
  skip ".codex/skills/scan-project/"
fi

# ─────────────────────────────────────────────────────────────
step "📄 AGENTS.md (Codex CLI / Cursor / Windsurf compatible)"

write_file "AGENTS.md" << 'AGENTSMD_EOF'
# Flutter Project — Agent Instructions

## Stack
- Flutter stable / Dart 3.x · Provider + ChangeNotifier · go_router · Dio · Hive · custom JWT

## Commands
- `flutter run` / `flutter run --release`
- `flutter analyze` — lint (must be clean before finishing any task)
- `dart fix --apply` — auto fix
- `flutter pub get`
- Never run `flutter build` or `flutter test` unless explicitly asked

## Before every task
1. Read `.claude/PROJECT_MAP.md` for the actual current structure.
   If missing or stale, run: `bash .claude/skills/scan-project/scan.sh`
2. For deeper detail read `.claude/reference/patterns.md` (code patterns) or
   `.claude/reference/api.md` (endpoints) as needed — these are shared,
   tool-agnostic docs, not Claude-specific.
3. Check `.claude/context/known-issues.md` before touching a fragile area.

## Folder layout
```
lib/
├── core/{constants,network,router,theme,utils}/
├── features/<name>/{data,domain,presentation}/
├── shared/{providers,widgets}/
└── main.dart
```
Domain never imports data or presentation. Data never imports presentation.
See `.claude/rules/structure.md` for full naming conventions.

## Non-negotiable rules
- Do not add, move, or delete folders without asking the user first.
- Do not add packages to `pubspec.yaml` without explicit approval.
- Do not introduce Riverpod, BLoC, or GetX — Provider only.
- Do not use `Navigator.push` — use `context.go()` / `context.push()` (go_router only).
- Do not hardcode colors, font sizes, or spacing — use `Theme.of(context)`.
- Dispose every controller/subscription in `dispose()`.
- No `print()` — `debugPrint()` only, removed before finishing.
- Repositories return `Either<Failure, T>` — never throw to providers.

Full Flutter/Dart coding rules (Provider patterns, lifecycle, navigation,
style, API conventions): see `lib/AGENTS.md`, scoped automatically to the
`lib/` subtree.

## After completing a task
- Re-run `bash .claude/skills/scan-project/scan.sh` if structure changed.
- State root cause explicitly for bug fixes.
- Keep changes minimal and scoped to the request.
AGENTSMD_EOF

if [[ -d lib ]]; then
  write_file "lib/AGENTS.md" << 'LIBAGENTS_EOF'
# Flutter / Dart Coding Rules
> Scoped to lib/ — merged after root AGENTS.md for any work inside this tree.

## Provider
- Extend `ChangeNotifier`. Always call `notifyListeners()` after mutating state.
- Keep `_isLoading`, `_error`, and domain state as private fields with public getters.
- Use `Consumer<T>` for scoped rebuilds. Use `context.read<T>()` only in callbacks.
- Never call `context.watch` or `context.read` in a method called during `build`.

## Widgets
- Prefer `StatelessWidget` + Provider over `StatefulWidget`.
- Always use `const` constructors where possible.
- Break `build` methods longer than ~40 lines into private `_build*` methods.
- Never call `setState` in a large widget — push state to the Provider layer.

## Lifecycle
- Dispose every `TextEditingController`, `AnimationController`, `StreamSubscription`.
- Add `if (!mounted) return;` after every `await` inside a `StatefulWidget`.

## Navigation
- `context.go()` for root/tab navigation. `context.push()` when back is needed.
- Never use `Navigator.push` or `MaterialPageRoute` directly.

## Lists
- Always `ListView.builder` or `SliverList` for dynamic lists.

## API
- Use the shared Dio client from `lib/core/network/`. Never instantiate Dio in a feature.
- `FormData` + `MultipartFile` for uploads — never base64 in JSON.

## Bug fix protocol
Diagnose layer first: widget → provider → usecase → repository → network.
Common causes: missing `notifyListeners()`, missing `mounted` check, provider
outside `MultiProvider` tree, `notifyListeners()` called during build phase.
Trace data path fully before editing. Minimal fix only — no surrounding refactors.

## Code hygiene
No `print()`. Remove `debugPrint` before finishing. `dart fix --apply` clean.
LIBAGENTS_EOF
else
  warn "No lib/ directory — skipping lib/AGENTS.md (run setup again after creating a Flutter project)"
fi

# ─────────────────────────────────────────────────────────────
step "🔍 Scanning the project (automatically, now)"

if [[ -d lib ]]; then
  bash .claude/skills/scan-project/scan.sh
else
  warn "No lib/ directory — skipping scan. Run 'bash .claude/skills/scan-project/scan.sh' after source code exists."
fi

# ─────────────────────────────────────────────────────────────
step "✅ Setup complete"
TOTAL_FILES=$(find .claude AGENTS.md CLAUDE.md -type f 2>/dev/null | wc -l | tr -d ' ')
log "Created or checked $TOTAL_FILES files."
log ""
log "Claude Code  → reads CLAUDE.md (automatically @imports .claude/rules/*)"
log "Codex CLI    → reads AGENTS.md (root) + lib/AGENTS.md (scoped)"
log ""
log "Re-scan anytime:      bash .claude/skills/scan-project/scan.sh"
log "Overwrite agent config: bash setup-agent-config.sh --existing . --force"
