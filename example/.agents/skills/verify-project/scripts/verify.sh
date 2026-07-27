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
