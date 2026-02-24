# Branch protection & required checks (GitHub settings)

Branch protection is configured in GitHub UI (repo admin required).

## Suggested rule for `main` / `master`

GitHub → Settings → Branches → Add rule

- Branch name pattern: `main` (and/or `master`)
- ✅ Require a pull request before merging
- ✅ Require approvals: 1–2
- ✅ Dismiss stale approvals on new commits
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Include administrators (recommended for audit posture)

### Required status checks (exact names)

After at least one PR run, GitHub will show the exact check names in the dropdown.
Select these (including matrix entries):

- `CI (Terraform Quality & Security Gates) / quality`
- `CI (Terraform Quality & Security Gates) / policy`
- `CI (Terraform Quality & Security Gates) / docs`
- `CI (Terraform Quality & Security Gates) / iac_scan`
- `CI (Terraform Quality & Security Gates) / validate (stacks/gcp-gke)`
- `CI (Terraform Quality & Security Gates) / validate (stacks/aws-eks)`

Tip: if you don't want AWS scaffolding to block merges yet, you can temporarily remove
`validate (stacks/aws-eks)` from required checks until EKS is implemented.
