# GitHub Actions OIDC: Plan vs Apply identities

Enterprise pattern:
- **Plan SA (read-only)**: used for PR `plan` (no write).
- **Apply SA (write)**: used for manual or protected applies to `main`.

Recommended approach:
1) Create a **Workload Identity Pool + Provider** in GCP for GitHub OIDC.
2) Create two service accounts:
   - `tf-plan@PROJECT.iam.gserviceaccount.com`
   - `tf-apply@PROJECT.iam.gserviceaccount.com`
3) Bind repository principals to each SA with `roles/iam.workloadIdentityUser`.
4) Assign least-privilege roles:
   - Plan SA: read-only roles
   - Apply SA: write roles needed by Terraform

See `scripts/wif_github_gcp.md` for the guided setup and role recommendations.


## Quick setup (script)
```bash
PROJECT_ID="my-project" GH_OWNER="myorg" GH_REPO="terraform-k8s-baseline" ./scripts/setup_ci_gcp.sh
```

Then set GitHub **Repository Variables** (Settings → Secrets and variables → Actions → Variables):
- `GCP_WIF_PROVIDER`
- `GCP_TF_PLAN_SA`
- `GCP_TF_APPLY_SA`


## Least privilege custom roles (optional)
Run setup with custom roles (avoids using the broad predefined role `projectIamAdmin`):
```bash
PROJECT_ID="my-project" GH_OWNER="myorg" GH_REPO="terraform-k8s-baseline" USE_CUSTOM_ROLES=1 ./scripts/setup_ci_gcp.sh
```
See `docs/08-custom-roles.md`.
