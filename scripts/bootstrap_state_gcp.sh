#!/usr/bin/env bash
set -euo pipefail

# Create a GCS bucket for Terraform remote state with:
# - versioning enabled
# - uniform bucket-level access (UBLA)
# - public access prevention
#
# Usage:
#   PROJECT_ID="my-project" REGION="us-central1" ENV=dev ./scripts/bootstrap_state_gcp.sh
#
# Optional:
#   TF_STATE_BUCKET="tfstate-my-project-dev"  (override default naming)

: "${PROJECT_ID:?Must set PROJECT_ID}"
: "${REGION:=us-central1}"
: "${ENV:=dev}"

DEFAULT_BUCKET="tfstate-${PROJECT_ID}-${ENV}"
TF_STATE_BUCKET="${TF_STATE_BUCKET:-$DEFAULT_BUCKET}"

echo "[*] Project: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}" >/dev/null

BUCKET_URI="gs://${TF_STATE_BUCKET}"

echo "[*] Checking bucket: ${BUCKET_URI}"
if gcloud storage buckets describe "${BUCKET_URI}" >/dev/null 2>&1; then
  echo "[*] Bucket exists. Ensuring security settings..."
else
  echo "[*] Creating bucket (${REGION}) with UBLA..."
  gcloud storage buckets create "${BUCKET_URI}"     --location="${REGION}"     --uniform-bucket-level-access
fi

echo "[*] Enabling versioning..."
gcloud storage buckets update "${BUCKET_URI}" --versioning

echo "[*] Enabling public access prevention..."
gcloud storage buckets update "${BUCKET_URI}" --public-access-prevention

echo "[*] Done."
echo "Next:"
echo "  - Update envs/gcp/${ENV}/backend.hcl bucket name to: ${TF_STATE_BUCKET}"
echo "  - Run: make gcp-${ENV}-init"
