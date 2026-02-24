# Custom roles for CI identities (least privilege)

This repo supports an optional setup that assigns **custom roles** to the CI service accounts,
instead of broad predefined roles like `roles/resourcemanager.projectIamAdmin`.

> Important: any permission that can modify project IAM policy is sensitive.
> Prefer the "strict IAM separation" option (see below) if your org requires it.

## Setup

Run:

```bash
PROJECT_ID="my-project" GH_OWNER="myorg" GH_REPO="terraform-k8s-baseline" USE_CUSTOM_ROLES=1 ./scripts/setup_ci_gcp.sh
```

This will create (or update) two custom roles:

- `tfPlanGkeBaseline`  (read-only posture; may still use `roles/viewer` by default)
- `tfApplyGkeBaseline` (write permissions for GKE + VPC baseline)

### State bucket permissions

Remote state bucket permissions are granted at the bucket level:
- Plan SA: `roles/storage.objectViewer`
- Apply SA: `roles/storage.objectAdmin`

## Strict IAM separation (recommended)

To avoid granting any project IAM policy permissions to CI:
- disable Terraform-managed project IAM bindings (node SA roles), and
- grant node SA roles via a one-time bootstrap with a privileged account.

This reduces CI blast radius significantly.

See `modules/gcp/iam` and `docs/02-controls.md` for the rationale.
