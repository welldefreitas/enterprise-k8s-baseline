#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   PROJECT_ID="my-project" REGION="us-central1" ./scripts/bootstrap_gcp.sh
#
# This script enables required APIs and (optionally) creates a remote state bucket.
# It is safe to run multiple times.

: "${PROJECT_ID:?Must set PROJECT_ID}"
: "${REGION:=us-central1}"

echo "[*] Setting project: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"

echo "[*] Enabling APIs..."
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  artifactregistry.googleapis.com

echo "[*] Done."
echo "Next: configure tfvars in envs/gcp/dev and run: make gcp-dev-plan"


# Optional remote state bucket setup:
#   ENV=dev  ./scripts/bootstrap_state_gcp.sh
#   ENV=prod ./scripts/bootstrap_state_gcp.sh
