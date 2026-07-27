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
#   --force            Refreshes managed instructions; preserves project-owned context
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
  --force            Refreshes managed instructions; preserves project context/reference
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

# write_seed_file <path> — creates project-owned context once and never
# overwrites it, including with --force.
write_seed_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
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
    test/features/home/domain/usecases \
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

  cat > test/features/home/domain/usecases/get_app_info_use_case_test.dart <<GET_APP_INFO_TEST_EOF
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:${package_name}/core/error/failure.dart';
import 'package:${package_name}/features/home/domain/entities/app_info.dart';
import 'package:${package_name}/features/home/domain/repositories/app_info_repository.dart';
import 'package:${package_name}/features/home/domain/usecases/get_app_info_use_case.dart';

class _FakeAppInfoRepository implements AppInfoRepository {
  @override
  Future<Either<Failure, AppInfo>> getAppInfo() async {
    return const Right(
      AppInfo(title: 'Ready', description: 'AgentKit is configured'),
    );
  }
}

void main() {
  test('returns app info from the repository', () async {
    final useCase = GetAppInfoUseCase(_FakeAppInfoRepository());

    final result = await useCase();

    result.fold(
      (failure) => fail('Expected app info, got: \${failure.message}'),
      (info) {
        expect(info.title, 'Ready');
        expect(info.description, 'AgentKit is configured');
      },
    );
  });
}
GET_APP_INFO_TEST_EOF

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
         .claude/skills/scan-project .claude/skills/verify-project .claude/prompts \
         .claude/snippets .claude/agents .claude/memory \
         .agents/skills .codex/skills .codex/agents
ok ".claude/{rules,reference,context,skills,prompts,snippets,agents,memory}"
ok ".agents/skills (Codex project skills)"
ok ".codex/{skills,agents}"

# ─────────────────────────────────────────────────────────────
step "📄 CLAUDE.md (root)"
write_file "CLAUDE.md" << 'CLAUDE_EOF'
# Flutter Project

## Stack
- Flutter / Dart. Treat `pubspec.yaml`, bootstrap code, and
  `.claude/PROJECT_MAP.md` as the current stack inventory.
- New AgentKit projects start with Provider, go_router, Dio, and Hive.
- Existing projects may use different auth, storage, and backend services;
  inspect the actual implementation before changing an integration.

## Commands
- `flutter run` — dev
- `flutter run --release` — release
- `flutter analyze` — required static analysis
- `dart format --output=none --set-exit-if-changed lib test` — formatting check
- `flutter test` — run targeted or full tests when tests exist
- `flutter pub get` — install deps
- `flutter gen-l10n` — regen i18n
- `bash .agents/skills/verify-project/scripts/detect-recurring-risks.sh` — refresh risk signals
- `bash .agents/skills/verify-project/scripts/verify.sh` — safe project checks
- Run release builds only when the task requires release validation.

## Git
If `docs/git-flow-release.md` exists, read it before branch, merge, or release work.

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
| `.claude/PROJECT_RISKS.md` | Before every task; refresh when missing or after risky changes |
| `.claude/context/sprint.md` | Starting a new session or task scope is ambiguous |
| `.claude/context/known-issues.md` | Before fixing a bug or editing a fragile area |
| `.claude/context/changelog.md` | Need to know what changed recently |

---

## skills/ — Invoked by name

| Skill | Invoke when |
|---|---|
| `/scan-project` | `PROJECT_MAP.md` missing or > 7 days old |
| `/verify-project` | Before finishing a code change or after fixing a bug |

Re-run scan manually anytime: `bash .claude/skills/scan-project/scan.sh`

---

## prompts/ — User-invoked only

| Prompt | Invoke when |
|---|---|
| `/review-code <file>` | Reviewing a file or diff against project standards |
| `/add-feature <name>` | Starting a new feature end-to-end |
| `/debug <description>` | Structured bug investigation |

---

## snippets/ — Project-specific examples only

| File | Use for |
|---|---|
| `.claude/snippets/README.md` | Rules for adding verified, project-specific snippets |

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
   - Exists → use it as a navigation index, then verify relevant files directly.
2. Read `.claude/PROJECT_RISKS.md` before editing. If it is missing, run
   `bash .agents/skills/verify-project/scripts/detect-recurring-risks.sh`.
   - Errors are blockers.
   - Warnings are heuristic review prompts, not proof of a defect.
3. Read only the rules file relevant to the task type:
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
- Run `bash .agents/skills/verify-project/scripts/verify.sh`.
- For a bug fix, add a regression test when a stable test seam exists. If it
  does not, record the exact manual verification and the missing test seam.
- Append completion summary:

```
## Completed
- [x] <what was done>
- [x] PROJECT_MAP.md updated (if structure changed)
- [x] No unrelated files changed
```

## Never do
- Make an architectural, dependency, or data-migration change without stating it.
- Run destructive migration, deploy, release, or credential commands unless asked.
- Use `print()` — use `debugPrint()` only, remove before finishing.
WORKFLOW_EOF

write_file ".claude/rules/structure.md" << 'STRUCTURE_EOF'
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
STRUCTURE_EOF

write_file ".claude/rules/flutter.md" << 'FLUTTER_EOF'
---
paths:
  - "lib/**/*.dart"
---

# Flutter / Dart Coding Rules

## Provider
- Extend `ChangeNotifier` for shared presentation state. Notify only after the
  observable state is internally consistent.
- Keep `_isLoading`, `_error`, and domain state as private fields with public getters.
- Use `Consumer<T>` or `Selector<T, R>` for scoped rebuilds.
- Use `context.read<T>()` for one-time access; do not trigger mutations during build.
- Register in `main.dart` `MultiProvider`. Use `ChangeNotifierProxyProvider` when dependent.

## Widgets
- Prefer `StatelessWidget` + Provider over `StatefulWidget`.
- Always use `const` constructors where possible.
- Break `build` methods longer than ~40 lines into private `_build*` methods.
- Keep ephemeral UI state local with `setState`; move shared or domain state to Provider.

## Lifecycle
- Dispose every `TextEditingController`, `AnimationController`, `StreamSubscription`.
- After an `await`, check `mounted` before touching `State`, `context`, or controllers.

## Navigation
- Use `context.go()` for root/tab navigation (replaces stack).
- Use `context.push()` when back navigation is needed.
- Never use `Navigator.push` or `MaterialPageRoute` directly.

## Style
- Feature widgets use theme/tokens; literal colors and typography belong in theme files.
- Never install new icon packages — use `Icons.*` or existing assets.

## Lists
- Always use `ListView.builder` or `SliverList` for dynamic lists.
- Never build lists with `.map().toList()` inside `ListView` children.

## API
- Use the project's existing integration boundary. Do not instantiate network,
  Firebase, database, or storage clients inside widgets.
- Repositories return `Either<Failure, T>`. Catch exceptions inside the repository.
- Use `FormData` + `MultipartFile` for file uploads — never embed base64 in JSON.

## Code hygiene
- Remove all `debugPrint`, unused imports, dead code before finishing.
- Never use `print()`.
- Run formatting and static analysis checks before considering a task complete.
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
- Add or update a regression test when the behavior is testable.
- Record repeated root causes and prevention in `.claude/context/known-issues.md`.
- Run `bash .agents/skills/verify-project/scripts/verify.sh`.
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
- [ ] Source: uses the project's existing HTTP/Firebase/storage boundary
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
- [ ] Targeted tests added or updated
- [ ] `bash .agents/skills/verify-project/scripts/verify.sh` passes
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

write_seed_file ".claude/reference/patterns.md" << 'PATTERNS_EOF'
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

write_seed_file ".claude/reference/api.md" << 'API_EOF'
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
API_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/context/"

write_seed_file ".claude/context/sprint.md" << 'SPRINT_EOF'
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

write_seed_file ".claude/context/known-issues.md" << 'KNOWNISSUES_EOF'
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
KNOWNISSUES_EOF

write_seed_file ".claude/context/changelog.md" << 'CHANGELOG_EOF'
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

write_seed_file ".claude/snippets/README.md" << 'SNIPPETSREADME_EOF'
# Project Snippets

Add snippets only after extracting a pattern from production code in this
project and validating it with the normal analysis/tests.

Do not keep generic auth, retry, Provider base-class, or API envelope snippets:
those patterns depend on the project's actual client construction, state
ownership, error contract, and backend authentication.
SNIPPETSREADME_EOF

# ─────────────────────────────────────────────────────────────
step "📄 .claude/agents/"

write_file ".claude/agents/code-reviewer.md" << 'CODEREVIEWER_EOF'
---
name: code-reviewer
description: Reviews Flutter/Dart and connected backend changes for correctness, state ownership, lifecycle, cross-system contracts, security, idempotency, performance, and regression coverage. Invoke for PR review or before finishing significant changes.
tools: Read, Grep, Glob
---

You are a senior Flutter/backend engineer reviewing code in this project.

Review for:
1. **Correctness and lifecycle** — logic, null/default handling, cleanup, async ordering
2. **State ownership** — one mutable owner, no stale mirrors or mutations during build
3. **Cross-system contracts** — client models, backend handlers, rules, defaults, migrations
4. **Security and concurrency** — auth/role checks, transactions, retry idempotency
5. **Performance and structure** — scoped rebuilds, lazy lists, hotspot growth, layer boundaries
6. **Regression coverage** — tests for changed behavior or a clearly stated missing seam

Order findings by severity. For each finding state file/line, impact, root cause,
concrete fix, and the regression test or verification needed.
Do not suggest changes outside the files you were asked to review.
Do not propose switching to a different state management solution.
CODEREVIEWER_EOF

write_file ".codex/agents/code-reviewer.toml" << 'CODEXREVIEWER_EOF'
name = "code-reviewer"
description = "Reviews Flutter/Dart and connected backend changes for correctness, state ownership, lifecycle, cross-system contracts, security, idempotency, performance, and regression coverage."
developer_instructions = """
Review findings first, ordered by severity.

Check correctness and lifecycle; single-source state ownership; client/backend/rules/schema parity; authentication and role validation; transactions and retry idempotency; hotspot growth and performance; and regression coverage.

For every finding include file and line, impact, root cause, concrete fix, and the test or verification needed. Keep the review scoped and do not propose replacing the project's state-management stack.
"""
CODEXREVIEWER_EOF

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
name: scan-project
description: Regenerate the Flutter project navigation map from the real filesystem and configuration. Use when PROJECT_MAP.md is missing or stale, after structural changes, or when an agent needs a reliable inventory of features, backends, tests, routes, providers, and large files.
---

# Scan Project

Run the scanner and treat its output as a generated navigation index. Verify
implementation details in the source before editing them.

## Run it directly (fastest — no LLM tokens needed)
```bash
bash .claude/skills/scan-project/scan.sh
```

## If asked to do it manually instead, follow these steps

**1. Scan source tree and backends**
```bash
find lib functions worker -type f 2>/dev/null | sort
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

**7. Write `.claude/PROJECT_MAP.md`** — generated content only. Keep manual
notes in `.claude/context/known-issues.md` and `.claude/context/changelog.md`.
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
  DEPS="$(printf '%s\n' "$DEPS" | sed 's/| flutter |  |/| flutter | sdk: flutter |/')"
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

SCREENS="$(find lib -type f \( -iname '*_screen.dart' -o -iname '*_page.dart' \) 2>/dev/null | sort || true)"
if [[ -n "$SCREENS" ]]; then
  SCREENS_TABLE="$(echo "$SCREENS" | while read -r f; do
    name=$(basename "$f" .dart)
    echo "| \`$name\` | \`$f\` |"
  done)"
else
  SCREENS_TABLE="| _(none found yet)_ | |"
fi

ROUTES="$(grep -rEn "path:[[:space:]]*['\"]" lib/core/router 2>/dev/null | sed -E "s/^([^:]+):([0-9]+):.*path:[[:space:]]*['\"]([^'\"]+)['\"].*/| \3 | \1:\2 |/" || true)"
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

DART_COUNT="$(find lib -name '*.dart' 2>/dev/null | grep -Evc '\.g\.dart$|\.freezed\.dart$|\.mocks\.dart$' || true)"
[[ -n "$DART_COUNT" ]] || DART_COUNT="0"
PROVIDER_COUNT="$(printf '%s\n' "$PROVIDERS" | sed '/^$/d' | wc -l | tr -d ' ')"
FEATURE_COUNT="0"
if [[ -d lib/features ]]; then
  FEATURE_COUNT="$(find lib/features -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')"
fi

BACKENDS_TABLE=""
[[ -f firebase.json ]] && BACKENDS_TABLE+="| Firebase | \`firebase.json\` | App/backend configuration |"$'\n'
[[ -f firestore.rules ]] && BACKENDS_TABLE+="| Firestore Rules | \`firestore.rules\` | Authorization and write invariants |"$'\n'
[[ -f functions/package.json ]] && BACKENDS_TABLE+="| Cloud Functions | \`functions/\` | Server-authoritative operations |"$'\n'
[[ -f worker/package.json ]] && BACKENDS_TABLE+="| Worker/API | \`worker/\` | External API surface |"$'\n'
[[ -z "$BACKENDS_TABLE" ]] && BACKENDS_TABLE="| _(none detected)_ | | |"

TEST_COUNT="0"
if [[ -d test ]]; then
  TEST_COUNT="$(find test -type f -name '*_test.dart' | wc -l | tr -d ' ')"
fi

HOTSPOTS="$(find lib -type f -name '*.dart' | while IFS= read -r file; do
  lines=$(wc -l < "$file" | tr -d ' ')
  printf '%s\t%s\n' "$lines" "$file"
done | sort -nr | awk -F '\t' '$1 >= 600 {printf "| %s | `%s` |\n", $1, $2; count++; if (count == 10) exit}')"
[[ -z "$HOTSPOTS" ]] && HOTSPOTS="| _(none at or above 600 lines)_ | |"

cat > "$OUT" << MAPEOF
# PROJECT_MAP.md
> Generated: $DATE
> Generated navigation index. The filesystem and runtime configuration remain authoritative.
> Regenerate anytime:
> \`bash .claude/skills/scan-project/scan.sh\`
> Do not hand-edit this file. Keep manual notes in \`.claude/context/\`.

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

## Backend Surfaces

| System | Path | Responsibility |
|---|---|---|
$BACKENDS_TABLE

---

## Tests ($TEST_COUNT Flutter test files)

| Suite | Path | Status |
|---|---|---|
| Flutter | \`test/\` | $TEST_COUNT test files detected |

---

## Large Dart Files

| Lines | File |
|---|---|
$HOTSPOTS
MAPEOF

echo "✓ .claude/PROJECT_MAP.md regenerated"
echo "  Dart files: $DART_COUNT"
echo "  Features:   $FEATURE_COUNT"
echo "  Providers:  $PROVIDER_COUNT"
echo "  Tests:      $TEST_COUNT"
SCANSCRIPT_EOF
chmod +x .claude/skills/scan-project/scan.sh 2>/dev/null || true

# ─────────────────────────────────────────────────────────────
step "📄 verify-project skill"

write_file ".claude/skills/verify-project/SKILL.md" << 'VERIFYSKILL_EOF'
---
name: verify-project
description: Detect recurring Flutter/Firebase architecture risks and run safe local validation for Flutter plus optional Node backends. Use before finishing code changes, after bug fixes, or when repeated regressions suggest ownership, async ordering, schema parity, idempotency, layout, tests, analysis, or backend checks may have been skipped.
---

# Verify Project

Run the bundled script from the repository root:

```bash
bash .agents/skills/verify-project/scripts/verify.sh
```

The script does not auto-fix, deploy, migrate, or build releases. It runs
the recurring-risk detector, formatting checks, `flutter analyze`, Flutter
tests when present, and existing `check` scripts in `functions/` or `worker/`.
The detector writes `.claude/PROJECT_RISKS.md`; errors fail verification while
heuristic warnings stay visible for review. Report skipped checks as gaps.
VERIFYSKILL_EOF

write_file ".claude/skills/verify-project/scripts/detect-recurring-risks.sh" << 'RISKDETECTOR_EOF'
#!/usr/bin/env bash
set -o pipefail

ROOT="."
REPORT=""
HOTSPOT_LINES="${RISK_HOTSPOT_LINES:-600}"

usage() {
  cat <<'USAGE_EOF'
Detect recurring Flutter project risks without modifying application code.

Usage:
  bash detect-recurring-risks.sh [--root PATH] [--report PATH]

Options:
  --root PATH       Project root to inspect (default: current directory)
  --report PATH     Report path (default: <root>/.claude/PROJECT_RISKS.md)
  --hotspot-lines N Large Dart file threshold (default: 600)
  -h, --help        Show this help
USAGE_EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -gt 1 ]] || { printf 'Missing value for --root\n' >&2; exit 2; }
      ROOT="$2"
      shift
      ;;
    --report)
      [[ $# -gt 1 ]] || { printf 'Missing value for --report\n' >&2; exit 2; }
      REPORT="$2"
      shift
      ;;
    --hotspot-lines)
      [[ $# -gt 1 ]] || { printf 'Missing value for --hotspot-lines\n' >&2; exit 2; }
      HOTSPOT_LINES="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

[[ "$HOTSPOT_LINES" =~ ^[0-9]+$ ]] || {
  printf 'Invalid --hotspot-lines value: %s\n' "$HOTSPOT_LINES" >&2
  exit 2
}

ROOT="$(cd "$ROOT" 2>/dev/null && pwd -P)" || {
  printf 'Project root does not exist: %s\n' "$ROOT" >&2
  exit 2
}

if [[ -z "$REPORT" ]]; then
  REPORT="$ROOT/.claude/PROJECT_RISKS.md"
elif [[ "$REPORT" != /* ]]; then
  REPORT="$ROOT/$REPORT"
fi

TMP_DIR="${TMPDIR:-/tmp}/flutter-agentkit-risks.$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

ERRORS=()
WARNINGS=()
CHECKLIST=()

add_error() {
  ERRORS[${#ERRORS[@]}]="$1"
}

add_warning() {
  WARNINGS[${#WARNINGS[@]}]="$1"
}

add_checklist() {
  CHECKLIST[${#CHECKLIST[@]}]="$1"
}

relative_path() {
  local path="$1"
  case "$path" in
    "$ROOT"/*) printf '%s' "${path#"$ROOT"/}" ;;
    *) printf '%s' "$path" ;;
  esac
}

append_grep_hits() {
  local output="$1"
  local pattern="$2"
  shift 2
  local file=""
  local line=""
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    while IFS=: read -r line _; do
      [[ -n "$line" ]] || continue
      printf '%s:%s\n' "$(relative_path "$file")" "$line" >> "$output"
    done < <(grep -nE "$pattern" "$file" 2>/dev/null || true)
  done
}

append_code_grep_hits() {
  local output="$1"
  local pattern="$2"
  shift 2
  local file=""
  local line=""
  local source=""
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    while IFS=: read -r line source; do
      [[ -n "$line" ]] || continue
      if printf '%s\n' "$source" | grep -Eq '^[[:space:]]*(//|/\*|\*|#)'; then
        continue
      fi
      printf '%s:%s\n' "$(relative_path "$file")" "$line" >> "$output"
    done < <(grep -nE "$pattern" "$file" 2>/dev/null || true)
  done
}

format_hits() {
  local file="$1"
  local total=0
  local shown=0
  local hit=""
  local output=""
  total="$(wc -l < "$file" | tr -d ' ')"
  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    shown=$((shown + 1))
    if [[ -n "$output" ]]; then
      output="$output, "
    fi
    output="${output}\`${hit}\`"
    [[ "$shown" -ge 5 ]] && break
  done < "$file"
  if [[ "$total" -gt "$shown" ]]; then
    output="$output, and $((total - shown)) more"
  fi
  printf '%s' "$output"
}

DART_FILES=()
if [[ -d "$ROOT/lib" ]]; then
  while IFS= read -r file; do
    DART_FILES[${#DART_FILES[@]}]="$file"
  done < <(find "$ROOT/lib" -type f -name '*.dart' -not -path '*/build/*' | sort)
fi

CONFIG_FILES=()
for config_path in \
  "$ROOT/CLAUDE.md" \
  "$ROOT/AGENTS.md" \
  "$ROOT/lib/AGENTS.md"; do
  [[ -f "$config_path" ]] && CONFIG_FILES[${#CONFIG_FILES[@]}]="$config_path"
done
for config_dir in \
  "$ROOT/.claude/rules" \
  "$ROOT/.claude/skills" \
  "$ROOT/.claude/agents" \
  "$ROOT/.agents" \
  "$ROOT/.codex"; do
  [[ -d "$config_dir" ]] || continue
  while IFS= read -r file; do
    CONFIG_FILES[${#CONFIG_FILES[@]}]="$file"
  done < <(find "$config_dir" -type f \( -name '*.md' -o -name '*.toml' \) | sort)
done

STALE_HITS="$TMP_DIR/stale.txt"
: > "$STALE_HITS"
append_grep_hits "$STALE_HITS" 'custom JWT|Never run flutter test|dart fix --apply|\.Codex|AuthInterceptor' "${CONFIG_FILES[@]}"
if [[ -s "$STALE_HITS" ]]; then
  add_error "**CFG001 stale agent instructions:** unsafe or obsolete setup markers remain at $(format_hits "$STALE_HITS")."
fi

if [[ -f "$ROOT/pubspec.yaml" ]] && grep -Eq '^[[:space:]]*go_router:' "$ROOT/pubspec.yaml"; then
  NAV_HITS="$TMP_DIR/navigation.txt"
  : > "$NAV_HITS"
  append_code_grep_hits "$NAV_HITS" 'Navigator\.(push|pushNamed)|MaterialPageRoute[[:space:]]*\(' "${DART_FILES[@]}"
  if [[ -s "$NAV_HITS" ]]; then
    add_error "**NAV001 navigation boundary:** direct Navigator/MaterialPageRoute calls bypass the configured go_router boundary at $(format_hits "$NAV_HITS")."
  fi
fi

PRINT_HITS="$TMP_DIR/print.txt"
: > "$PRINT_HITS"
append_code_grep_hits "$PRINT_HITS" '(^|[^[:alnum:]_])print[[:space:]]*\(' "${DART_FILES[@]}"
if [[ -s "$PRINT_HITS" ]]; then
  add_error "**LOG001 production logging:** \`print()\` remains in Dart source at $(format_hits "$PRINT_HITS")."
fi

PRESENTATION_FILES=()
for file in "${DART_FILES[@]}"; do
  relative="$(relative_path "$file")"
  case "$relative" in
    */presentation/*|lib/shared/widgets/*)
      PRESENTATION_FILES[${#PRESENTATION_FILES[@]}]="$file"
      ;;
  esac
done

CLIENT_HITS="$TMP_DIR/direct-clients.txt"
: > "$CLIENT_HITS"
append_code_grep_hits "$CLIENT_HITS" '(^|[^[:alnum:]_])Dio[[:space:]]*\(|Firebase(Auth|Firestore)\.instance|Hive\.(openBox|box)[[:space:]]*\(|http\.Client[[:space:]]*\(' "${PRESENTATION_FILES[@]}"
if [[ -s "$CLIENT_HITS" ]]; then
  add_warning "**ARCH001 presentation integration boundary (heuristic):** widgets/screens construct network, Firebase, or storage clients at $(format_hits "$CLIENT_HITS"). Move construction to the existing data/infrastructure boundary."
fi

ASYNC_HITS="$TMP_DIR/async-cleanup.txt"
: > "$ASYNC_HITS"
append_code_grep_hits "$ASYNC_HITS" 'await[[:space:]]+_[[:alnum:]_]*(cancel|cleanup|cleanUp|close|dispose)[[:alnum:]_]*[[:space:]]*\(' "${DART_FILES[@]}"
if [[ -s "$ASYNC_HITS" ]]; then
  add_warning "**ASYNC001 visible-state ordering (heuristic):** awaited cleanup helpers appear at $(format_hits "$ASYNC_HITS"). In sign-out/reset flows, publish visible state before slow cleanup when safe."
fi

SAFE_AREA_HITS="$TMP_DIR/safe-area.txt"
: > "$SAFE_AREA_HITS"
for file in "${PRESENTATION_FILES[@]}"; do
  base="$(basename "$file")"
  case "$base" in
    *screen*.dart|*page*.dart)
      append_code_grep_hits "$SAFE_AREA_HITS" 'top[[:space:]]*:[[:space:]]*false' "$file"
      ;;
  esac
done
if [[ -s "$SAFE_AREA_HITS" ]]; then
  add_warning "**UI001 system inset boundary (heuristic):** page/screen files contain \`SafeArea(top: false)\` at $(format_hits "$SAFE_AREA_HITS"). Confirm each use is modal-only and test full-page routes with top/bottom insets."
fi

HOTSPOTS="$TMP_DIR/hotspots.txt"
: > "$HOTSPOTS"
for file in "${DART_FILES[@]}"; do
  lines="$(wc -l < "$file" | tr -d ' ')"
  if [[ "$lines" -ge "$HOTSPOT_LINES" ]]; then
    printf '%s\t%s\n' "$lines" "$(relative_path "$file")" >> "$HOTSPOTS"
  fi
done
sort -nr "$HOTSPOTS" -o "$HOTSPOTS"
if [[ -s "$HOTSPOTS" ]]; then
  hotspot_count="$(wc -l < "$HOTSPOTS" | tr -d ' ')"
  hotspot_summary=""
  shown=0
  while IFS=$'\t' read -r lines path; do
    shown=$((shown + 1))
    [[ -n "$hotspot_summary" ]] && hotspot_summary="$hotspot_summary, "
    hotspot_summary="${hotspot_summary}\`${path}\` (${lines})"
    [[ "$shown" -ge 8 ]] && break
  done < "$HOTSPOTS"
  [[ "$hotspot_count" -gt "$shown" ]] && hotspot_summary="$hotspot_summary, and $((hotspot_count - shown)) more"
  add_warning "**SIZE001 large Dart hotspots:** $hotspot_count files are at or above $HOTSPOT_LINES lines: $hotspot_summary. Avoid adding responsibilities without extracting a testable seam."
fi

PROVIDER_HOTSPOTS="$TMP_DIR/provider-hotspots.txt"
: > "$PROVIDER_HOTSPOTS"
while IFS=$'\t' read -r lines path; do
  case "$path" in
    *provider*.dart|*/providers/*) printf '%s\t%s\n' "$lines" "$path" >> "$PROVIDER_HOTSPOTS" ;;
  esac
done < "$HOTSPOTS"
provider_hotspot_count="$(wc -l < "$PROVIDER_HOTSPOTS" | tr -d ' ')"
if [[ "$provider_hotspot_count" -ge 2 ]]; then
  provider_names=""
  while IFS=$'\t' read -r _ path; do
    [[ -n "$provider_names" ]] && provider_names="$provider_names, "
    provider_names="${provider_names}\`${path}\`"
  done < "$PROVIDER_HOTSPOTS"
  add_warning "**STATE001 duplicate/stale ownership risk:** multiple large providers coordinate shared state ($provider_names). Name one authoritative owner per field and test derived mirrors in both update directions."
fi

PROVIDER_TEST_GAPS="$TMP_DIR/provider-test-gaps.txt"
: > "$PROVIDER_TEST_GAPS"
while IFS=$'\t' read -r _ path; do
  provider_base="$(basename "$path" .dart)"
  provider_test_found=0
  for test_dir in "$ROOT/test" "$ROOT/integration_test"; do
    [[ -d "$test_dir" ]] || continue
    if find "$test_dir" -type f -name "${provider_base}*_test.dart" -print -quit | grep -q .; then
      provider_test_found=1
      break
    fi
  done
  if [[ "$provider_test_found" -eq 0 ]]; then
    printf '%s\n' "$path" >> "$PROVIDER_TEST_GAPS"
  fi
done < "$PROVIDER_HOTSPOTS"
if [[ -s "$PROVIDER_TEST_GAPS" ]]; then
  add_warning "**STATE002 provider hotspot test gap (heuristic):** no focused filename-matching test was found for $(format_hits "$PROVIDER_TEST_GAPS"). Add ownership/lifecycle tests before extending these coordinators, or document the existing differently named coverage."
fi

flutter_test_count=0
for test_dir in "$ROOT/test" "$ROOT/integration_test"; do
  [[ -d "$test_dir" ]] || continue
  count="$(find "$test_dir" -type f -name '*_test.dart' | wc -l | tr -d ' ')"
  flutter_test_count=$((flutter_test_count + count))
done
if [[ -f "$ROOT/pubspec.yaml" && "$flutter_test_count" -eq 0 ]]; then
  add_warning "**TEST001 missing Flutter regression suite:** no \`*_test.dart\` files were found under \`test/\` or \`integration_test/\`. Repeated state, compatibility, and layout fixes have no automated Flutter gate."
fi

if [[ -f "$ROOT/firestore.rules" ]]; then
  RULE_TEST_SIGNAL="$TMP_DIR/rules-test-signal.txt"
  : > "$RULE_TEST_SIGNAL"
  for search_root in "$ROOT/functions" "$ROOT/test" "$ROOT/integration_test"; do
    [[ -d "$search_root" ]] || continue
    while IFS= read -r file; do
      if grep -Eiq '@firebase/rules-unit-testing|RulesTestEnvironment|emulators:exec.*firestore|firestore[_-]?rules' "$file" 2>/dev/null; then
        printf '%s\n' "$file" >> "$RULE_TEST_SIGNAL"
      fi
    done < <(find "$search_root" -type f \
      -not -path '*/node_modules/*' \
      \( -name 'package.json' -o -name '*.js' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.ts' \))
  done
  if [[ ! -s "$RULE_TEST_SIGNAL" ]]; then
    add_warning "**RULES001 missing Firestore Rules regression suite:** \`firestore.rules\` exists, but no emulator/rules test signal was found. Cover role, ownership, status, and multi-document write scenarios."
  fi
fi

for package_dir in functions worker; do
  package_json="$ROOT/$package_dir/package.json"
  [[ -f "$package_json" ]] || continue
  check_script=""
  test_script=""
  if command -v node >/dev/null 2>&1; then
    check_script="$(node -e 'const fs=require("fs"); const p=JSON.parse(fs.readFileSync(process.argv[1], "utf8")); process.stdout.write(p.scripts?.check || "")' "$package_json" 2>/dev/null || true)"
    test_script="$(node -e 'const fs=require("fs"); const p=JSON.parse(fs.readFileSync(process.argv[1], "utf8")); process.stdout.write(p.scripts?.test || "")' "$package_json" 2>/dev/null || true)"
  else
    check_script="$(grep -E '"'"'check'"'"[[:space:]]*:' "$package_json" 2>/dev/null | head -n 1 || true)"
    test_script="$(grep -E '"'"'test'"'"[[:space:]]*:' "$package_json" 2>/dev/null | head -n 1 || true)"
  fi
  if [[ -z "$check_script" ]]; then
    add_warning "**BACKEND001 missing backend check:** \`$package_dir/package.json\` has no \`check\` script, so verify-project cannot validate this backend."
  elif ! printf '%s' "$check_script" | grep -Eiq '(^|[[:space:]&])(test|jest|vitest|mocha|tap)([[:space:]&:]|$)|node[[:space:]]+--test|emulators:exec'; then
    add_warning "**BACKEND002 syntax-only backend check:** \`$package_dir\` check is \`$check_script\` and has no behavioral test signal."
  fi
  if [[ "$package_dir" == "functions" ]] \
    && printf '%s' "$check_script" | grep -Eiq 'test:rules|emulators:exec' \
    && ! printf '%s %s' "$check_script" "$test_script" | grep -Eiq 'node[[:space:]]+--test|jest|vitest|mocha|tap|test:(unit|functions|handlers|domain)|npm[[:space:]]+(run[[:space:]]+)?test([[:space:]&]|$)'; then
    add_warning "**BACKEND003 Functions handler test gap:** the check covers Rules/emulator behavior but no callable, trigger, or scheduled-handler test signal was found."
  fi
done

BATCH_HITS="$TMP_DIR/batch-without-transaction.txt"
: > "$BATCH_HITS"
for source_root in "$ROOT/lib" "$ROOT/functions" "$ROOT/worker/src"; do
  [[ -d "$source_root" ]] || continue
  while IFS= read -r file; do
    if grep -Eq '\.batch[[:space:]]*\(|writeBatch[[:space:]]*\(' "$file" 2>/dev/null \
      && ! grep -Eq 'runTransaction|\.transaction[[:space:]]*\(' "$file" 2>/dev/null; then
      printf '%s\n' "$(relative_path "$file")" >> "$BATCH_HITS"
    fi
  done < <(find "$source_root" -type f \
    -not -path '*/node_modules/*' \
    -not -path '*/test/*' \
    \( -name '*.dart' -o -name '*.js' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.ts' \))
done
if [[ -s "$BATCH_HITS" ]]; then
  add_warning "**TXN001 read-dependent write risk (heuristic):** batch writes without a visible transaction occur in $(format_hits "$BATCH_HITS"). Verify status/ownership preconditions are not read-dependent or move the invariant into a transaction/server boundary."
fi

AUTO_ID_HITS="$TMP_DIR/retry-auto-id.txt"
: > "$AUTO_ID_HITS"
for source_root in "$ROOT/functions" "$ROOT/worker/src"; do
  [[ -d "$source_root" ]] || continue
  while IFS= read -r file; do
    if grep -Eiq 'schedule|retry|reminder|queue' "$file" 2>/dev/null \
      && grep -Eq 'collection[[:space:]]*\([^)]*\)[[:space:]]*\.add[[:space:]]*\(' "$file" 2>/dev/null; then
      printf '%s\n' "$(relative_path "$file")" >> "$AUTO_ID_HITS"
    fi
  done < <(find "$source_root" -type f \
    -not -path '*/node_modules/*' \
    -not -path '*/test/*' \
    \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.ts' \))
done
if [[ -s "$AUTO_ID_HITS" ]]; then
  add_warning "**IDEMP001 retry/idempotency risk (heuristic):** scheduled/retry code appears to create auto-ID documents in $(format_hits "$AUTO_ID_HITS"). Prefer deterministic IDs and status preconditions."
fi

if [[ -f "$ROOT/firestore.rules" || -d "$ROOT/functions" || -d "$ROOT/worker" ]]; then
  add_checklist "**Cross-system contracts:** when a persisted field or role changes, update Dart models/entities, backend validation, Firestore Rules, tolerant defaults, migrations, and contract/emulator tests together."
fi
if [[ "${#DART_FILES[@]}" -gt 0 ]]; then
  add_checklist "**State/lifecycle:** name one authoritative owner for shared state; publish user-visible auth/navigation state before optional cleanup; cover slow or failing cleanup."
  add_checklist "**Legacy compatibility:** test older Firestore/Hive/in-memory objects when adding required fields; use tolerant reads/defaults plus an explicit migration path."
  add_checklist "**Mobile layout:** for changed full-page UI, verify compact widths, dense content, keyboard insets, and both system bars; reserve \`SafeArea(top: false)\` for intentional modal behavior."
fi
if [[ -d "$ROOT/functions" || -d "$ROOT/worker" ]]; then
  add_checklist "**Cloud mutations:** protect multi-document invariants with transactions/status preconditions and make scheduled/retryable work idempotent with deterministic keys."
fi

mkdir -p "$(dirname "$REPORT")"
REPORT_TMP="$TMP_DIR/report.md"
{
  printf '# PROJECT_RISKS.md\n\n'
  printf '> Generated: %s by `detect-recurring-risks.sh`\n' "$(date +%Y-%m-%d)"
  printf '> Machine-owned heuristic report; regenerate instead of hand-editing.\n'
  printf '> Errors are deterministic project-rule violations. Warnings require human/agent review and may be intentional.\n\n'
  printf '## Summary\n\n'
  printf -- '- Errors: %s\n' "${#ERRORS[@]}"
  printf -- '- Warnings: %s\n' "${#WARNINGS[@]}"
  printf -- '- Flutter tests detected: %s\n' "$flutter_test_count"
  printf -- '- Large-file threshold: %s lines\n\n' "$HOTSPOT_LINES"
  printf '## Errors\n\n'
  if [[ "${#ERRORS[@]}" -eq 0 ]]; then
    printf -- '- None.\n'
  else
    for finding in "${ERRORS[@]}"; do
      printf -- '- %s\n' "$finding"
    done
  fi
  printf '\n## Warnings\n\n'
  if [[ "${#WARNINGS[@]}" -eq 0 ]]; then
    printf -- '- None.\n'
  else
    for finding in "${WARNINGS[@]}"; do
      printf -- '- %s\n' "$finding"
    done
  fi
  printf '\n## Prevention Checklist\n\n'
  if [[ "${#CHECKLIST[@]}" -eq 0 ]]; then
    printf -- '- No optional integration surfaces detected.\n'
  else
    for item in "${CHECKLIST[@]}"; do
      printf -- '- %s\n' "$item"
    done
  fi
  printf '\n## Required Agent Response\n\n'
  printf -- '- Read this report before editing a flagged area.\n'
  printf -- '- For each relevant warning, state why it is safe or add a regression guard.\n'
  printf -- '- Re-run `bash .agents/skills/verify-project/scripts/verify.sh` before finishing.\n'
} > "$REPORT_TMP"
mv "$REPORT_TMP" "$REPORT"

printf 'Recurring-risk scan: %s error(s), %s warning(s).\n' "${#ERRORS[@]}" "${#WARNINGS[@]}"
printf 'Report: %s\n' "$REPORT"

if [[ "${#ERRORS[@]}" -gt 0 ]]; then
  exit 1
fi
RISKDETECTOR_EOF
chmod +x .claude/skills/verify-project/scripts/detect-recurring-risks.sh 2>/dev/null || true

write_file ".claude/skills/verify-project/scripts/verify.sh" << 'VERIFYSCRIPT_EOF'
#!/usr/bin/env bash
set -uo pipefail

FAILED=0

run_check() {
  local label="$1"
  shift
  printf '\n▶ %s\n' "$label"
  if "$@"; then
    printf '✓ %s\n' "$label"
  else
    printf '✗ %s\n' "$label"
    FAILED=1
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -f "$SCRIPT_DIR/detect-recurring-risks.sh" ]]; then
  run_check "Recurring-risk detector" bash "$SCRIPT_DIR/detect-recurring-risks.sh"
else
  printf '\n✗ Recurring-risk detector is missing. Re-run AgentKit setup with --force.\n'
  FAILED=1
fi

if command -v dart >/dev/null 2>&1 && [[ -d lib ]]; then
  format_paths=(lib)
  [[ -d test ]] && format_paths+=(test)
  run_check "Dart formatting" dart format --output=none --set-exit-if-changed "${format_paths[@]}"
fi

if command -v flutter >/dev/null 2>&1 && [[ -f pubspec.yaml ]]; then
  run_check "Flutter analyze" flutter analyze
  if [[ -d test ]] && find test -type f -name '*_test.dart' -print -quit | grep -q .; then
    run_check "Flutter tests" flutter test
  else
    printf '\n! Flutter tests skipped: no *_test.dart files found.\n'
  fi
fi

for package_dir in functions worker; do
  if [[ -f "$package_dir/package.json" ]] && command -v npm >/dev/null 2>&1; then
    if node -e 'const fs=require("fs"); const p=JSON.parse(fs.readFileSync(process.argv[1], "utf8")); process.exit(p.scripts?.check ? 0 : 1)' "$package_dir/package.json"; then
      run_check "$package_dir check" npm --prefix "$package_dir" run check
    fi
  fi
done

if [[ "$FAILED" -ne 0 ]]; then
  printf '\nProject verification failed.\n'
  exit 1
fi

printf '\nProject verification passed.\n'
VERIFYSCRIPT_EOF
chmod +x .claude/skills/verify-project/scripts/*.sh 2>/dev/null || true

# Mirror project skills to the current Codex location and the legacy location.
for skill_name in scan-project verify-project; do
  for skills_root in .agents/skills .codex/skills; do
    target="$skills_root/$skill_name"
    if [[ "$FORCE" -eq 1 || ! -d "$target" ]]; then
      rm -rf "$target"
      mkdir -p "$target"
      cp -R ".claude/skills/$skill_name/." "$target/"
      find "$target" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
      ok "$target/"
    else
      skip "$target/"
    fi
  done
done

# ─────────────────────────────────────────────────────────────
step "📄 AGENTS.md (Codex CLI / Cursor / Windsurf compatible)"

write_file "AGENTS.md" << 'AGENTSMD_EOF'
# Flutter Project — Agent Instructions

## Stack
- Flutter / Dart. `pubspec.yaml`, bootstrap code, and `.claude/PROJECT_MAP.md`
  describe the current stack; do not assume auth, storage, or backend choices.
- New AgentKit projects use Provider + ChangeNotifier and go_router by default.

## Commands
- `flutter run` / `flutter run --release`
- `flutter analyze` — lint (must be clean before finishing any task)
- `dart format --output=none --set-exit-if-changed lib test`
- `flutter test` — run when tests exist or behavior changed
- `flutter pub get`
- `bash .agents/skills/verify-project/scripts/detect-recurring-risks.sh` — refresh risk signals
- `bash .agents/skills/verify-project/scripts/verify.sh` — safe validation suite
- Run release builds only when the task requires them.

## Before every task
1. Read `.claude/PROJECT_MAP.md` for the actual current structure.
   If missing or stale, run: `bash .claude/skills/scan-project/scan.sh`
2. Read `.claude/PROJECT_RISKS.md`. If missing, run:
   `bash .agents/skills/verify-project/scripts/detect-recurring-risks.sh`
   Treat errors as blockers and warnings as required heuristic review.
3. For deeper detail read `.claude/reference/patterns.md` (code patterns) or
   `.claude/reference/api.md` (endpoints) as needed — these are shared,
   tool-agnostic docs, not Claude-specific.
4. Check `.claude/context/known-issues.md` before touching a fragile area.

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
- Follow the existing structure; ask before broad architecture or migration changes.
- Do not add packages to `pubspec.yaml` without explicit approval.
- Do not introduce Riverpod, BLoC, or GetX — Provider only.
- Do not use `Navigator.push` — use `context.go()` / `context.push()` (go_router only).
- Feature UI uses theme/tokens; literal visual tokens belong in theme files.
- Dispose every controller/subscription in `dispose()`.
- No `print()` — `debugPrint()` only, removed before finishing.
- Keep widgets away from direct network/Firebase/storage client construction.
- Name one authoritative owner for shared state; derive mirrors instead of
  maintaining duplicate mutable copies across providers.
- When persisted fields or roles change, update client models, backend checks,
  database Rules, tolerant defaults/migrations, and tests as one contract.
- Full-page routes preserve both system insets; `SafeArea(top: false)` is only
  for an intentional modal boundary and requires compact/inset verification.

Full Flutter/Dart coding rules (Provider patterns, lifecycle, navigation,
style, API conventions): see `lib/AGENTS.md`, scoped automatically to the
`lib/` subtree.

## After completing a task
- Re-run `bash .claude/skills/scan-project/scan.sh` if structure changed.
- Run `bash .agents/skills/verify-project/scripts/verify.sh`.
- Add a regression test for bug fixes when a stable seam exists; otherwise
  document the exact manual verification and missing seam.
- State root cause explicitly for bug fixes.
- Keep changes minimal and scoped to the request.
AGENTSMD_EOF

if [[ -d lib ]]; then
  write_file "lib/AGENTS.md" << 'LIBAGENTS_EOF'
# Flutter / Dart Coding Rules
> Scoped to lib/ — merged after root AGENTS.md for any work inside this tree.

## Provider
- Use `ChangeNotifier` for shared presentation state and notify only after the
  observable state is internally consistent.
- Name one authoritative owner for each shared field. Other providers expose
  derived/read-only views instead of stale mutable mirrors.
- Keep `_isLoading`, `_error`, and domain state as private fields with public getters.
- Use `Consumer<T>` or `Selector<T, R>` for scoped rebuilds.
- Use `context.read<T>()` for one-time access; do not mutate providers during build.

## Widgets
- Prefer `StatelessWidget` + Provider over `StatefulWidget`.
- Always use `const` constructors where possible.
- Break `build` methods longer than ~40 lines into private `_build*` methods.
- Keep ephemeral UI state local; move shared or domain state to Provider.
- Full-page routes preserve top and bottom system insets. Use
  `SafeArea(top: false)` only for intentional modal content and verify compact widths.

## Lifecycle
- Dispose every `TextEditingController`, `AnimationController`, `StreamSubscription`.
- After `await`, check `mounted` before using `State`, `context`, or controllers.
- In sign-out/reset flows, publish visible state before awaiting optional slow
  cleanup when detaching cleanup is safe.

## Persistence compatibility
- Treat Flutter models, backend validation, database Rules, defaults, and
  migrations as one contract when persisted fields or roles change.
- Keep reads tolerant of older Firestore/Hive/in-memory objects and cover an
  old-data fixture before making a field required.

## Navigation
- `context.go()` for root/tab navigation. `context.push()` when back is needed.
- Never use `Navigator.push` or `MaterialPageRoute` directly.

## Lists
- Always `ListView.builder` or `SliverList` for dynamic lists.

## API
- Use the existing integration boundary. Never instantiate HTTP, Firebase,
  database, or storage clients in widgets.
- `FormData` + `MultipartFile` for uploads — never base64 in JSON.

## Bug fix protocol
Diagnose layer first: widget → provider → usecase → repository → network.
Trace the full data path before editing. Check duplicate sources of truth,
async ordering, retry/idempotency, schema/rules drift, and lifecycle safety.
Keep the fix focused and add a regression test when feasible.

## Code hygiene
No `print()`. Remove temporary `debugPrint`. Run the project verification skill.
LIBAGENTS_EOF
else
  warn "No lib/ directory — skipping lib/AGENTS.md (run setup again after creating a Flutter project)"
fi

if [[ -d functions ]]; then
  write_file "functions/AGENTS.md" << 'FUNCTIONSAGENTS_EOF'
# Backend Function Rules

- Treat backend functions as server-authoritative for privileged mutations.
- Validate authentication, role, ownership, membership, and current status server-side.
- Use transactions plus status/ownership preconditions for read-dependent,
  multi-document invariants; use batches only when no read precondition exists.
- Make scheduled and retryable work idempotent, preferably with deterministic IDs.
- Keep backend validation, client models, and database security rules aligned.
- Preserve compatibility for existing documents when adding required fields.
- Run the package `check` script when present.
- Never deploy functions or mutate production data unless explicitly asked.
FUNCTIONSAGENTS_EOF
fi

if [[ -d worker ]]; then
  write_file "worker/AGENTS.md" << 'WORKERAGENTS_EOF'
# Worker / API Rules

- Treat the Worker and its client as one versioned request/response contract.
- Validate and normalize input at the boundary; return stable error codes/messages.
- Do not expose secrets, upstream payloads, or internal errors.
- Keep retries, rate limits, and upstream failures explicit and user-safe.
- Protect read-dependent multi-write state transitions with explicit status
  preconditions, and make retryable work idempotent with deterministic keys.
- Update client parsing and Worker response shapes together.
- Run the package `check` script when present.
- Never deploy or change production secrets unless explicitly asked.
WORKERAGENTS_EOF
fi

# ─────────────────────────────────────────────────────────────
step "🔍 Scanning the project (automatically, now)"

if [[ -d lib ]]; then
  bash .claude/skills/scan-project/scan.sh
else
  warn "No lib/ directory — skipping scan. Run 'bash .claude/skills/scan-project/scan.sh' after source code exists."
fi

step "🛡️ Detecting recurring project risks (automatically, now)"
if [[ -f .agents/skills/verify-project/scripts/detect-recurring-risks.sh ]]; then
  if bash .agents/skills/verify-project/scripts/detect-recurring-risks.sh; then
    ok ".claude/PROJECT_RISKS.md regenerated"
  else
    warn "Blocking project-rule violations detected. Review .claude/PROJECT_RISKS.md."
  fi
else
  warn "Risk detector missing — run setup again with --force."
fi

# ─────────────────────────────────────────────────────────────
step "✅ Setup complete"
TOTAL_FILES=$(find .claude .agents .codex AGENTS.md CLAUDE.md -type f 2>/dev/null | wc -l | tr -d ' ')
log "Created or checked $TOTAL_FILES files."
log ""
log "Claude Code  → reads CLAUDE.md (automatically @imports .claude/rules/*)"
log "Codex         → reads AGENTS.md + lib/AGENTS.md + .agents/skills/*"
log ""
log "Re-scan anytime:      bash .claude/skills/scan-project/scan.sh"
log "Refresh risk report:   bash .agents/skills/verify-project/scripts/detect-recurring-risks.sh"
log "Verify changes:        bash .agents/skills/verify-project/scripts/verify.sh"
log "Overwrite agent config: bash setup-agent-config.sh --existing . --force"
