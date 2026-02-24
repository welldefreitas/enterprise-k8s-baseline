#!/usr/bin/env bash
set -euo pipefail

POLICY_DIR="${POLICY_DIR:-policies/opa}"
TARGET_DIR="${TARGET_DIR:-.}"

if command -v conftest >/dev/null 2>&1; then
  conftest test --parser hcl2 -p "${POLICY_DIR}" "${TARGET_DIR}"
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  docker run --rm     -v "$(pwd)":/repo     -w /repo     openpolicyagent/conftest:v0.56.0     test --parser hcl2 -p "${POLICY_DIR}" "${TARGET_DIR}"
  exit 0
fi

echo "ERROR: conftest not found and docker not available."
echo "Install conftest or docker, then re-run."
exit 1
