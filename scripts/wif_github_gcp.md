# GitHub Actions -> GCP (Workload Identity Federation) Setup (OIDC, No Secrets)

This repo includes `.github/workflows/plan_gcp.yml` which authenticates to GCP using **GitHub OIDC** (Workload Identity Federation).
Result: Terraform can run in CI **without storing GCP keys**.

## 0) Prereqs
- `gcloud` installed and authenticated as a user who can create IAM/WIF resources.
- You know your:
  - `PROJECT_ID`
  - `GITHUB_ORG`
  - `GITHUB_REPO`
  - A dedicated CI service account name (e.g., `tf-ci`)

Set variables:
```bash
PROJECT_ID="my-project"
GITHUB_ORG="my-org"
GITHUB_REPO="terraform-k8s-baseline"
SA_NAME="tf-ci"
POOL_ID="github"
PROVIDER_ID="my-repo"
```

## 1) Create a Workload Identity Pool
```bash
gcloud iam workload-identity-pools create "${POOL_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"
```

Get the pool full name (you'll use it later for IAM bindings):
```bash
WORKLOAD_IDENTITY_POOL_ID="$(gcloud iam workload-identity-pools describe "${POOL_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)")"
echo "${WORKLOAD_IDENTITY_POOL_ID}"
```

## 2) Create a Workload Identity Provider (OIDC)
**Always** set an attribute condition to restrict entry into the pool (minimum: your GitHub org).
```bash
gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_ID}" \
  --display-name="GitHub OIDC Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'"
```

Extract the provider resource name (this becomes `GCP_WIF_PROVIDER`):
```bash
WIF_PROVIDER="$(gcloud iam workload-identity-pools providers describe "${PROVIDER_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_ID}" \
  --format="value(name)")"
echo "${WIF_PROVIDER}"
```

## 3) Create a CI Service Account (least privilege)
```bash
gcloud iam service-accounts create "${SA_NAME}" \
  --project="${PROJECT_ID}" \
  --display-name="Terraform CI (GitHub OIDC)"

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo "${SA_EMAIL}"
```

Grant the minimum permissions for your Terraform actions.
For `plan`, Terraform needs read access; for `apply`, it needs create/update/delete.
Start practical for a lab, then tighten.

Example baseline (cluster/network/iam):
```bash
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountAdmin"
```

## 4) Allow GitHub repo to impersonate the Service Account
```bash
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"
```

## 5) Set GitHub Repository Variables
In your GitHub repo:
**Settings → Secrets and variables → Actions → Variables**

Create:
- `GCP_WIF_PROVIDER` = `${WIF_PROVIDER}`
- `GCP_TERRAFORM_SA` = `${SA_EMAIL}`

> Note: `GCP_WIF_PROVIDER` uses **PROJECT_NUMBER** in the resource name. If you need it:
```bash
gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)"
```

## 6) Run the workflow
Actions → **Plan (GCP via OIDC) - Manual** → Run workflow.

If you later add remote state, run with `use_backend=true`.

## Hardening checklist (enterprise)
- Use a dedicated **Terraform SA per environment** (dev/prod).
- Restrict impersonation to protected branches/tags (additional attribute conditions).
- Use remote state (GCS with versioning + uniform access), separate buckets per env.


---

## Plan vs Apply (recommended)

Use two Service Accounts (SAs) bound to the same GitHub OIDC Provider:

- **Plan SA** (read-only): `tf-plan@PROJECT_ID.iam.gserviceaccount.com`
- **Apply SA** (write): `tf-apply@PROJECT_ID.iam.gserviceaccount.com`

### Suggested roles
**Plan SA (read-only)**
- `roles/viewer`
- `roles/iam.securityReviewer` (optional, read-only IAM visibility)

**Apply SA (write)**
- `roles/container.admin`
- `roles/compute.networkAdmin`
- `roles/iam.serviceAccountAdmin`
- `roles/iam.serviceAccountUser`
- `roles/resourcemanager.projectIamAdmin` *(only if Terraform manages project-level IAM bindings)*

> For strict least-privilege, create custom roles scoped to required APIs/resources.

### Repo Variables (recommended)
Set these as GitHub **Repository Variables** (not secrets):
- `GCP_WIF_PROVIDER`  (full resource name of the provider)
- `GCP_TF_PLAN_SA`    (service account email)
- `GCP_TF_APPLY_SA`   (service account email)

Workflows will skip OIDC auth if these variables are not set.
