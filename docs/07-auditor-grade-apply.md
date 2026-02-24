# Auditor-grade Apply (GCP)

This repo supports an "auditor-grade" Terraform apply flow:

- **Plan** runs with a **read-only** identity and produces artifacts (`tfplan.txt`, `tfplan.json`).
- **Apply** runs **only after manual approval** via GitHub **Environments** and applies the previously generated plan.

## 1) Environment protection (manual approval)

Create two GitHub Environments:

- `dev` (no reviewers)
- `prod` (**Required reviewers enabled**, recommended)

GitHub UI:
- Settings → Environments → New environment
- Name: `prod`
- Configure:
  - ✅ Required reviewers (add your approvers)
  - ✅ Deployment branches: restrict to `main`/`master` (recommended)
  - Optional: wait timer / secrets

The workflow `.github/workflows/apply_gcp.yml` uses:
- `environment: ${{ inputs.env }}`

So a `prod` apply **always waits for approval**.

## 2) Branch protection + required checks

You can't enforce branch protection purely from this repo without GitHub admin/API access.
Configure it in GitHub:

Settings → Branches → Add rule

Recommended settings:
- ✅ Require a pull request before merging
- ✅ Require approvals (1–2)
- ✅ Dismiss stale approvals on new commits
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Include administrators (recommended for audit posture)

Required checks (names may include matrix suffixes):

- `CI (Terraform Quality & Security Gates) / quality`
- `CI (Terraform Quality & Security Gates) / policy`
- `CI (Terraform Quality & Security Gates) / docs`
- `CI (Terraform Quality & Security Gates) / iac_scan`
- `CI (Terraform Quality & Security Gates) / validate (stacks/gcp-gke)`
- `CI (Terraform Quality & Security Gates) / validate (stacks/aws-eks)`

Tip: after one successful PR run, GitHub will show the exact check names in the dropdown.

## 3) Identity split: Plan SA vs Apply SA

Repo Variables (GitHub → Settings → Secrets and variables → Actions → Variables):

- `GCP_WIF_PROVIDER`
- `GCP_TF_PLAN_SA`
- `GCP_TF_APPLY_SA`

Plan uses `GCP_TF_PLAN_SA` and **must be read-only**.
Apply uses `GCP_TF_APPLY_SA` and should have only the minimum write permissions.

## 4) Custom roles (least privilege) — option

You can use custom roles instead of broad predefined roles.

See:
- `scripts/setup_ci_gcp.sh` (supports `USE_CUSTOM_ROLES=1`)
- `docs/08-custom-roles.md`
