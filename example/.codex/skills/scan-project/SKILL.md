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
