# Flutter AgentKit

Bootstrap Flutter projects with a feature-first Clean Architecture and consistent
instructions for Claude Code, Codex CLI, Cursor, and Windsurf.

## Quick start

Create a Flutter project:

```bash
bash setup-agent-config.sh --new my_app
```

Configure an existing Flutter project:

```bash
bash setup-agent-config.sh --existing /path/to/flutter-project
```

For requirements, command options, generated files, and CI usage, see the
[complete setup guide](README-setup.md).

## What it creates

- A working Provider, go_router, Dio, Hive, and dartz baseline
- A feature-first `presentation`, `domain`, and `data` structure
- `CLAUDE.md` and `AGENTS.md` instruction files
- A generated `.claude/PROJECT_MAP.md` based on the real project structure

## License

No license has been specified for this project yet.
