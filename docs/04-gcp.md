# GCP (GKE) Decisions

## Why private nodes by default?
Private nodes remove public IP exposure and reduce lateral movement from the Internet.

## Control plane endpoint: public vs private
- Default: `enable_private_endpoint=false` + `allowed_admin_cidrs` allowlist.
  - Practical for most teams while still “locked down”.
- Option: `enable_private_endpoint=true`.
  - Strongest posture, but requires VPN/bastion to manage.

## Workload Identity
Workload Identity is enabled by default (`enable_workload_identity=true`).
It avoids static keys in pods and makes access auditable.

## What we intentionally do NOT do in Terraform (by default)
- Kubernetes RBAC objects (Roles/RoleBindings): better managed via GitOps (Argo/Flux) using Kubernetes manifests.
- Policy enforcement (OPA/Gatekeeper/Kyverno): add as platform layer post-provisioning.


## Deletion protection
Set `deletion_protection=true` in prod to reduce accidental destroy/recreate risk.
