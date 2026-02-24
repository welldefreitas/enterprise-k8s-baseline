#!/usr/bin/env bash
set -euo pipefail

# Generate module documentation using terraform-docs.
# Requires docker OR terraform-docs binary in PATH.
#
# Usage:
#   ./scripts/generate_docs.sh
#   make docs

MODULES=(
  "modules/gcp/network"
  "modules/gcp/iam"
  "modules/gcp/gke"
)

if command -v terraform-docs >/dev/null 2>&1; then
  for m in "${MODULES[@]}"; do
    echo "[*] terraform-docs ${m}"
    terraform-docs markdown table --output-file README.md --output-mode inject "${m}"
  done
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  for m in "${MODULES[@]}"; do
    echo "[*] terraform-docs ${m} (docker)"
    docker run --rm -v "$(pwd)":/repo -w /repo quay.io/terraform-docs/terraform-docs:0.19.0       markdown table --output-file README.md --output-mode inject "${m}"
  done
  exit 0
fi

echo "ERROR: terraform-docs not found and docker not available."
echo "Install terraform-docs or docker, then re-run."
exit 1
