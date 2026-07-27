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
