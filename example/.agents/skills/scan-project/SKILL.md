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
