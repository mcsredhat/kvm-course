#!/bin/bash
# lib.sh : tiny PASS/FAIL helper
PASS=0; FAIL=0
check() {                      # check "description" command [args...]
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "  [PASS] $d"; PASS=$((PASS+1))
  else echo "  [FAIL] $d"; FAIL=$((FAIL+1)); fi
}
summary() { echo "Result: $PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]; }
