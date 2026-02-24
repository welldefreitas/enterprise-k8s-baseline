# Terraform Kubernetes Baseline (GKE ✅ / EKS 🚧)

Provision **secure-by-default** Kubernetes with Terraform — **no ClickOps**.

This repo is intentionally **cloud-agnostic**:
- **GCP (GKE)**: production-ready baseline (private nodes, locked-down VPC, least privilege IAM, Workload Identity).
- **AWS (EKS)**: scaffolded (same interface/contract) — TODO implementation.

## What you get (GKE baseline)
**Network**
- Custom VPC + dedicated subnet
- VPC-native (secondary ranges for Pods/Services)
- Cloud NAT for controlled egress (optional but recommended)

**GKE**
- Private nodes (no public IPs)
- Public or private control plane endpoint (configurable)
- Master Authorized Networks (allowlist) for the control plane (when public endpoint is enabled)
- Shielded nodes + secure metadata settings
- Logging/Monitoring enabled

**Identity & Access**
- Dedicated node Service Account (no Editor/Owner)
- Minimum roles for logs/metrics + optional Artifact Registry read
- **Workload Identity enabled** (recommended) — no static keys inside workloads

## Repo layout
```text
terraform-k8s-baseline/
├── stacks/
│   ├── gcp-gke/              # ✅ ready
│   └── aws-eks/              # 🚧 scaffold (same interface)
├── modules/
│   ├── gcp/{network,iam,gke}/
│   └── aws/...               # TODO
├── envs/
│   └── gcp/{dev,prod}/
├── docs/
└── .github/workflows/
```

## Quickstart (GCP / GKE)
### 0) Prereqs
- Terraform >= 1.6
- gcloud authenticated and set to your project
- GCP APIs enabled (see `scripts/bootstrap_gcp.sh`)

### 1) Configure tfvars
Copy an example and adjust:
```bash
cp envs/gcp/dev/terraform.tfvars.example envs/gcp/dev/terraform.tfvars
```

### 2) Plan / Apply (dev)
```bash
make gcp-dev-init
make gcp-dev-plan
make gcp-dev-apply
```

### 3) Get cluster credentials
If you kept `enable_private_endpoint = false` (default), you can fetch credentials from your workstation:
```bash
gcloud container clusters get-credentials <cluster_name> --region <region> --project <project_id>
```

If you set `enable_private_endpoint = true`, you must be on a private network path (VPN / bastion) to reach the endpoint.

## Controls mapping (auditor-friendly)
See:
- `docs/02-controls.md` (what/why/how)
- `docs/03-interfaces.md` (cloud-agnostic contract)
- `docs/04-gcp.md` (GKE-specific decisions)

## CI gates
GitHub Actions runs:
- `terraform fmt -check`
- `terraform init -backend=false`
- `terraform validate` (per stack)
- `tflint`
- `trivy config` (IaC misconfiguration scan)

---

**Why this is “consulting-grade”**: clear controls, consistent interfaces across clouds, and CI that enforces quality + security by default.
