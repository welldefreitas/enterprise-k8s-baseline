#!/usr/bin/env bash
set -euo pipefail

# Setup GitHub Actions OIDC (Workload Identity Federation) + split Service Accounts:
# - tf-plan  (read-only)
# - tf-apply (write)
#
# Usage:
#   PROJECT_ID="my-project" GH_OWNER="myorg" GH_REPO="terraform-k8s-baseline" ./scripts/setup_ci_gcp.sh
#
# Optional overrides:
#   WIF_POOL_ID="github-actions"
#   WIF_PROVIDER_ID="github"
#   TF_PLAN_SA_NAME="tf-plan"
#   TF_APPLY_SA_NAME="tf-apply"
#
# Least-privilege option (recommended):
#   USE_CUSTOM_ROLES=1
#
# Notes:
# - If your Terraform manages project-level IAM bindings (e.g., google_project_iam_member),
#   the Apply identity needs permission to set IAM policy on the project (very sensitive).
#   Using a *custom role* avoids granting the broad predefined role projectIamAdmin, but
#   still implies high privilege. For stricter separation, move project IAM bootstrapping
#   out of Terraform and keep CI identities away from project IAM policy updates.

: "${PROJECT_ID:?Must set PROJECT_ID}"
: "${GH_OWNER:?Must set GH_OWNER}"
: "${GH_REPO:?Must set GH_REPO}"

: "${WIF_POOL_ID:=github-actions}"
: "${WIF_PROVIDER_ID:=github}"
: "${TF_PLAN_SA_NAME:=tf-plan}"
: "${TF_APPLY_SA_NAME:=tf-apply}"

: "${USE_CUSTOM_ROLES:=0}"
: "${TF_PLAN_ROLE_ID:=tfPlanGkeBaseline}"
: "${TF_APPLY_ROLE_ID:=tfApplyGkeBaseline}"

echo "[*] Setting project: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}" >/dev/null

PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
POOL_RESOURCE="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL_ID}"
PROVIDER_RESOURCE="${POOL_RESOURCE}/providers/${WIF_PROVIDER_ID}"

echo "[*] Ensuring Workload Identity Pool: ${WIF_POOL_ID}"
if gcloud iam workload-identity-pools describe "${WIF_POOL_ID}" --location="global" >/dev/null 2>&1; then
  echo "    - Pool exists"
else
  gcloud iam workload-identity-pools create "${WIF_POOL_ID}" \
    --location="global" \
    --display-name="GitHub Actions OIDC"
fi

echo "[*] Ensuring OIDC Provider: ${WIF_PROVIDER_ID}"
if gcloud iam workload-identity-pools providers describe "${WIF_PROVIDER_ID}" --workload-identity-pool="${WIF_POOL_ID}" --location="global" >/dev/null 2>&1; then
  echo "    - Provider exists"
else
  gcloud iam workload-identity-pools providers create-oidc "${WIF_PROVIDER_ID}" \
    --location="global" \
    --workload-identity-pool="${WIF_POOL_ID}" \
    --display-name="GitHub OIDC" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref,attribute.actor=assertion.actor" \
    --attribute-condition="attribute.repository == '${GH_OWNER}/${GH_REPO}'"
fi

PLAN_SA_EMAIL="${TF_PLAN_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
APPLY_SA_EMAIL="${TF_APPLY_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "[*] Ensuring Service Accounts"
if gcloud iam service-accounts describe "${PLAN_SA_EMAIL}" >/dev/null 2>&1; then
  echo "    - Plan SA exists"
else
  gcloud iam service-accounts create "${TF_PLAN_SA_NAME}" \
    --display-name="Terraform Plan (read-only) - ${GH_OWNER}/${GH_REPO}"
fi

if gcloud iam service-accounts describe "${APPLY_SA_EMAIL}" >/dev/null 2>&1; then
  echo "    - Apply SA exists"
else
  gcloud iam service-accounts create "${TF_APPLY_SA_NAME}" \
    --display-name="Terraform Apply (write) - ${GH_OWNER}/${GH_REPO}"
fi

PRINCIPAL="principalSet://iam.googleapis.com/${POOL_RESOURCE}/attribute.repository/${GH_OWNER}/${GH_REPO}"

echo "[*] Binding workloadIdentityUser to SAs"
gcloud iam service-accounts add-iam-policy-binding "${PLAN_SA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="${PRINCIPAL}" >/dev/null

gcloud iam service-accounts add-iam-policy-binding "${APPLY_SA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="${PRINCIPAL}" >/dev/null

create_or_update_custom_role () {
  local role_id="$1"
  local title="$2"
  local description="$3"
  local permissions_csv="$4"

  if gcloud iam roles describe "${role_id}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    echo "    - Updating custom role: ${role_id}"
    gcloud iam roles update "${role_id}" \
      --project="${PROJECT_ID}" \
      --title="${title}" \
      --description="${description}" \
      --permissions="${permissions_csv}" \
      --stage="GA" >/dev/null
  else
    echo "    - Creating custom role: ${role_id}"
    gcloud iam roles create "${role_id}" \
      --project="${PROJECT_ID}" \
      --title="${title}" \
      --description="${description}" \
      --permissions="${permissions_csv}" \
      --stage="GA" >/dev/null
  fi
}

grant_state_bucket_roles () {
  local env_name="$1"
  local backend_file="envs/gcp/${env_name}/backend.hcl"
  if [ ! -f "${backend_file}" ]; then
    echo "    - No ${backend_file}; skipping bucket IAM for ${env_name}"
    return 0
  fi

  local bucket
  bucket="$(grep -E '^\s*bucket\s*=' "${backend_file}" | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')"
  if [ -z "${bucket}" ]; then
    echo "    - Could not parse bucket from ${backend_file}; skipping"
    return 0
  fi

  local uri="gs://${bucket}"
  echo "    - Granting state bucket IAM on ${uri} (${env_name})"
  # Plan: read-only
  gcloud storage buckets add-iam-policy-binding "${uri}" \
    --member="serviceAccount:${PLAN_SA_EMAIL}" \
    --role="roles/storage.objectViewer" >/dev/null || true

  # Apply: write
  gcloud storage buckets add-iam-policy-binding "${uri}" \
    --member="serviceAccount:${APPLY_SA_EMAIL}" \
    --role="roles/storage.objectAdmin" >/dev/null || true
}

echo "[*] Assigning roles..."
# Plan SA: keep reliable read-only posture
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:${PLAN_SA_EMAIL}" --role="roles/viewer" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:${PLAN_SA_EMAIL}" --role="roles/iam.securityReviewer" >/dev/null || true

if [ "${USE_CUSTOM_ROLES}" = "1" ]; then
  echo "[*] Using custom roles for Apply SA (least privilege option)"
  # NOTE: includes sensitive permissions if Terraform manages project IAM bindings.
  # Tighten further by moving project IAM bootstrapping out of Terraform.
  APPLY_PERMS="container.clusters.create,container.clusters.delete,container.clusters.get,container.clusters.list,container.clusters.update,container.locations.get,container.locations.list,container.nodePools.create,container.nodePools.delete,container.nodePools.get,container.nodePools.list,container.nodePools.update,container.operations.get,container.operations.list,compute.addresses.create,compute.addresses.delete,compute.addresses.get,compute.addresses.list,compute.firewalls.create,compute.firewalls.delete,compute.firewalls.get,compute.firewalls.list,compute.firewalls.update,compute.networks.create,compute.networks.delete,compute.networks.get,compute.networks.list,compute.networks.update,compute.networks.use,compute.networks.useExternalIp,compute.regionOperations.get,compute.regionOperations.list,compute.routers.create,compute.routers.delete,compute.routers.get,compute.routers.list,compute.routers.update,compute.routes.create,compute.routes.delete,compute.routes.get,compute.routes.list,compute.subnetworks.create,compute.subnetworks.delete,compute.subnetworks.get,compute.subnetworks.list,compute.subnetworks.update,compute.subnetworks.use,iam.serviceAccounts.create,iam.serviceAccounts.delete,iam.serviceAccounts.get,iam.serviceAccounts.list,iam.serviceAccounts.update,iam.serviceAccounts.getIamPolicy,iam.serviceAccounts.setIamPolicy,iam.serviceAccounts.actAs,resourcemanager.projects.getIamPolicy,resourcemanager.projects.setIamPolicy,serviceusage.services.get,serviceusage.services.list"
  create_or_update_custom_role "${TF_APPLY_ROLE_ID}" \
    "Terraform Apply - GKE Baseline" \
    "Least privilege role for provisioning the GKE baseline in this repo. Review before use." \
    "${APPLY_PERMS}"

  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${APPLY_SA_EMAIL}" \
    --role="projects/${PROJECT_ID}/roles/${TF_APPLY_ROLE_ID}" >/dev/null
else
  echo "[*] Using predefined roles for Apply SA (convenience mode)"
  # NOTE: may not be acceptable in strict environments.
  for role in roles/container.admin roles/compute.networkAdmin roles/iam.serviceAccountAdmin roles/iam.serviceAccountUser roles/resourcemanager.projectIamAdmin; do
    gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:${APPLY_SA_EMAIL}" --role="${role}" >/dev/null
  done
fi

echo "[*] Granting remote state bucket IAM (dev/prod if backend.hcl exists)"
grant_state_bucket_roles "dev"
grant_state_bucket_roles "prod"

echo ""
echo "✅ Done. Set these GitHub Repository Variables:"
echo "  GCP_WIF_PROVIDER = ${PROVIDER_RESOURCE}"
echo "  GCP_TF_PLAN_SA   = ${PLAN_SA_EMAIL}"
echo "  GCP_TF_APPLY_SA  = ${APPLY_SA_EMAIL}"
echo ""
echo "Workflows:"
echo "  - CI:    .github/workflows/ci.yml"
echo "  - Plan:  .github/workflows/plan_gcp.yml"
echo "  - Apply: .github/workflows/apply_gcp.yml"
