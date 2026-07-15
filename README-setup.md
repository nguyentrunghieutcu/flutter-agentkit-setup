# Flutter AgentKit - Setup Guide

`setup-agent-config.sh` supports two workflows from the start:

```text
1) New project
2) Existing project
```

- **New project** creates a Flutter application, installs baseline dependencies,
  scaffolds a feature-first Clean Architecture, and sets up Claude Code, Codex
  CLI, Cursor, and Windsurf instructions.
- **Existing project** preserves the source tree and only creates or updates
  agent configuration, including a `PROJECT_MAP.md` generated from the real
  project files.

New projects use the **Presentation**, **Domain**, and **Data** layers. The
structure follows separation of concerns and the dependency rule inspired by
[`guilherme-v/flutter-clean-architecture-example`](https://github.com/guilherme-v/flutter-clean-architecture-example), adapted to AgentKit's feature-first workflow.

## Requirements

- Flutter SDK available on `PATH` (required when creating a new project)
- Bash 4 or newer

## 1. Run interactively

```bash
bash setup-agent-config.sh
```

The script displays:

```text
Select project type:
1) New project
2) Existing project
```

## 2. Option 1 - New project

The script asks for:

- A `snake_case` project name
- A parent directory
- An organization, defaulting to `com.example`

It then runs the equivalent of:

```bash
flutter create --org com.example my_app
cd my_app
flutter pub add provider go_router dio dartz hive hive_flutter shared_preferences
```

Next, it replaces the default starter app with this scaffold:

```text
lib/
|- app.dart
|- main.dart
|- core/
|  |- constants/      # app constants and spacing tokens
|  |- error/
|  |- network/
|  |- router/
|  |- theme/
|  `- utils/
|- features/
|  `- home/
|     |- data/
|     |  |- models/
|     |  |- repositories/
|     |  `- sources/
|     |- domain/
|     |  |- entities/
|     |  |- repositories/
|     |  `- usecases/
|     `- presentation/
|        |- providers/
|        |- screens/
|        `- widgets/
`- shared/
   |- providers/
   `- widgets/
```

The scaffold contains a working `home` feature that demonstrates this flow:

```text
Presentation -> Use case -> Repository abstraction <- Repository implementation
```

Create a project without the interactive menu:

```bash
bash setup-agent-config.sh --new my_app
```

Specify a parent directory and organization:

```bash
bash setup-agent-config.sh \
  --new my_app \
  --path ~/Projects \
  --org com.mycompany
```

Skip automatic dependency installation:

```bash
bash setup-agent-config.sh --new my_app --skip-deps
```

> With `--skip-deps`, install the baseline packages yourself before running the app.

## 3. Option 2 - Existing project

Place the script in a Flutter project root or pass a project path:

```bash
bash setup-agent-config.sh
```

Or:

```bash
bash setup-agent-config.sh --existing /path/to/flutter-project
```

The target project must contain:

```text
pubspec.yaml
lib/
```

The existing source code is neither scaffolded nor restructured. The script only
adds agent configuration and scans the project.

## 4. Generated agent configuration

```text
your-project/
|- CLAUDE.md
|- AGENTS.md
|- lib/
|  `- AGENTS.md
|- .claude/
|  |- PROJECT_MAP.md
|  |- rules/
|  |- reference/
|  |- context/
|  |- skills/scan-project/
|  |- prompts/
|  |- snippets/
|  |- agents/
|  `- memory/
`- .codex/
   `- skills/scan-project/
```

- **Claude Code** reads `CLAUDE.md` and imports rules from `.claude/rules/`.
- **Codex CLI, Cursor, and Windsurf** read `AGENTS.md` and `lib/AGENTS.md`.
- `.claude/PROJECT_MAP.md` is generated from the actual filesystem with `find`,
  `grep`, and `pubspec.yaml`; it is never guessed by an agent.

## 5. Re-scan after source changes

```bash
bash .claude/skills/scan-project/scan.sh
```

There is no need to run the full setup again.

## 6. Overwrite agent configuration

```bash
bash setup-agent-config.sh --existing . --force
```

By default, the script does not overwrite existing agent configuration files.
Use `--force` to reset the files managed by the setup.

## 7. Run in CI

Use non-interactive mode:

```bash
bash setup-agent-config.sh --existing .
```

Refresh the project map after a checkout or merge:

```bash
bash .claude/skills/scan-project/scan.sh
```
