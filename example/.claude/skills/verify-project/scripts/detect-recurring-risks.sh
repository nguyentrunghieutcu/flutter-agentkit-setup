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
