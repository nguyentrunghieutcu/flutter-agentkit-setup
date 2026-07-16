# Contributing to Flutter AgentKit

Thanks for helping improve Flutter AgentKit. Contributions to the setup script,
the generated example, and the documentation are all welcome.

## Before you start

- Keep each change focused on one problem or improvement.
- Preserve the two supported workflows: creating a new Flutter project and
  configuring an existing one.
- Do not overwrite user-owned project source files in the existing-project
  workflow.
- Discuss a substantial change before investing in a large pull request.

## Development workflow

1. Fork the repository and create a branch from `main`.
2. Make the smallest change that solves the problem.
3. Update documentation whenever behaviour, commands, or generated files
   change.
4. Run the checks below.
5. Open a pull request that explains the motivation and verification steps.

## Keep the scaffold and example aligned

`setup-agent-config.sh` is the source of truth for generated project files.
When changing the Clean Architecture scaffold or agent configuration, update
the corresponding files under [`example/`](example/) so contributors can
inspect the expected output without running the setup.

## Checks

Run these checks from the repository root before opening a pull request:

```bash
bash -n setup-agent-config.sh
bash setup-agent-config.sh --help
```

For changes to generated Flutter code, also run the relevant Flutter checks in
the generated project or in [`example/`](example/), such as:

```bash
cd example
flutter analyze
flutter test
```

## Pull request checklist

- [ ] The change is focused and documented.
- [ ] `bash -n setup-agent-config.sh` passes.
- [ ] `bash setup-agent-config.sh --help` passes.
- [ ] The `example/` output is updated when the scaffold changes.
- [ ] Generated configuration still supports Claude Code, Codex CLI, Cursor,
      and Windsurf.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
