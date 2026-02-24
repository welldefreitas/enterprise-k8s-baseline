# Security Controls Library (What / Why / How)

## 1) Network Segmentation + Egress Control
**What:** Dedicated VPC/subnet for the cluster; optional Cloud NAT (GCP) / NAT Gateway (AWS).  
**Why:** Reduce blast radius; avoid public IPs on nodes; control egress paths.  
**How:** `modules/gcp/network` provisions VPC, subnets, secondary ranges, and NAT.

## 2) Private Nodes
**What:** Nodes have no public IPs.  
**Why:** Eliminates direct Internet exposure and reduces attack surface.  
**How:** `google_container_cluster.private_cluster_config.enable_private_nodes = true`.

## 3) Control Plane Access Allowlist (when public endpoint)
**What:** Control plane endpoint is reachable only from an allowlist (Master Authorized Networks).  
**Why:** Prevents “open API server” posture.  
**How:** `allowed_admin_cidrs` variable.

## 4) Least Privilege IAM
**What:** Dedicated node service account with minimum roles.  
**Why:** Avoid broad permissions that turn container compromise into cloud compromise.  
**How:** `modules/gcp/iam` creates SA + binds minimal roles (logs/metrics), with optional Artifact Registry reader.

## 5) Workload Identity / IRSA
**What:** No static cloud keys inside pods.  
**Why:** Keys leak; federation is auditable and reduces long-lived secret risk.  
**How:** GCP: Workload Identity enabled in cluster; AWS: (planned) IRSA.

## 6) Secure-by-default Node Config
**What:** Disable legacy metadata endpoints, enable Shielded nodes.  
**Why:** Prevent metadata credential theft and improve node integrity.  
**How:** node pool `metadata.disable-legacy-endpoints=true`, Shielded instance config.

## 7) Continuous Controls (CI gates)
**What:** fmt/validate/lint + IaC misconfig scan on every PR/push.  
**Why:** Prevent drift and insecure changes from being merged.  
**How:** `.github/workflows/ci.yml`.


## 6) Deletion Protection (prod guardrail)
**What:** Prevent accidental cluster deletion.
**Why:** Reduces operational risk and change-control incidents.
**How:** `deletion_protection=true` (recommended in prod).


---

## Policy-as-Code
This repo includes minimal baseline policies in `policies/opa/` and runs them in CI using Conftest (HCL2 parser).

## CI Identities
Recommended split: `tf-plan` (read-only) vs `tf-apply` (write) using GitHub OIDC / WIF. See `docs/06-ci-identities.md`.
