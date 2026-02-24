# 🏗️ Enterprise-grade Terraform Baseline for Kubernetes (GKE/EKS)

[![CI](https://github.com/YOUR_GITHUB_OWNER/enterprise-k8s-baseline/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_GITHUB_OWNER/enterprise-k8s-baseline/actions/workflows/ci.yml)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D_1.6.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![Google Cloud](https://img.shields.io/badge/Google_Cloud-GKE-4285F4?logo=google-cloud)](https://cloud.google.com/)
[![AWS](https://img.shields.io/badge/AWS-EKS_(WIP)-232F3E?logo=amazon-aws)](https://aws.amazon.com/)
[![Security](https://img.shields.io/badge/Security-Secure--by--default-red)](#security--compliance)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Provision **secure-by-default**, **immutable**, and **cloud-agnostic** Kubernetes clusters using Terraform.  
**Stop ClickOps**: everything is versioned, reviewable, and reproducible.

This repository implements **Pillar 3 of a modern DevSecOps architecture: Immutable Infrastructure & IaC**. It is designed to align with common enterprise audit expectations by shipping:
- **guardrails** (Policy-as-Code),
- **least-privilege patterns** (Plan vs Apply identities),
- **evidence** (CI gates + artifacts),
- and **secure defaults** (private nodes, restricted control plane access, federation-first identity).

> **Status**
> - ✅ **GCP (GKE)**: production-ready baseline  
> - 🟡 **AWS (EKS)**: scaffolded to the same interface contract (*implementation WIP*)

---

## ✅ What you get (Consulting / Enterprise baseline)

### 🔒 Security & Identity (Zero-Trust)
- **Workload Identity / IRSA:** no static, long-lived cloud keys inside pods (federation-first).
- **Least privilege IAM:** dedicated service accounts; optional access (e.g., Artifact Registry) is explicit and opt-in.
- **Private nodes:** nodes have **no public IPs** by default.
- **Control plane restrictions:** endpoint exposure is controlled through enforceable guardrails (e.g., allowlist when public).

### 🌐 Network & Architecture
- **VPC-native networking (GCP):** dedicated VPC/subnets + secondary ranges for pods/services.
- **Controlled egress:** Cloud NAT (with log policy that avoids noisy logs by default).

### 🧰 DevSecOps / Auditability
- **Auditor-grade Apply:** “Plan → Manual approval → Apply the exact tfplan” via GitHub Environments.
- **OIDC identity split:** separate identities for `tf-plan` (read-only) and `tf-apply` (write) using Workload Identity Federation (no secrets stored in GitHub).
- **Policy-as-Code (OPA/Conftest):** baseline Rego policies enforce guardrails on Terraform HCL before plans are generated.
- **Shift-left security gates:** `tflint` + `trivy config` in CI.

---

## ☁️ Cloud parity (cloud-agnostic contract)

| Control / Capability | GKE (GCP) | EKS (AWS) |
|---|---:|---:|
| Private nodes (no public IPs) | ✅ | 🟡 WIP |
| Identity federation for workloads | ✅ Workload Identity | 🟡 IRSA scaffold |
| Control plane access restrictions | ✅ | 🟡 WIP |
| Policy-as-Code (OPA/Conftest) | ✅ | ✅ (shared) |
| CI gates (fmt/validate/tflint/trivy/policy) | ✅ | ✅ |

> The interface contract lives in **`docs/03-interfaces.md`**. The goal is “same inputs/outputs, different implementations”.

---

## 📂 Repository architecture (directory tree)

```text
enterprise-k8s-baseline/
├── .github/workflows/          # CI pipelines: quality gates + plan/apply with OIDC
├── docs/                       # ADRs and compliance documentation
├── envs/                       # Per-environment vars + backend config
│   └── gcp/
│       ├── dev/
│       └── prod/
├── modules/                    # Secure-by-default reusable modules
│   ├── gcp/
│   │   ├── gke/
│   │   ├── iam/
│   │   └── network/
│   └── aws/                    # Scaffold (WIP)
├── policies/opa/               # OPA/Conftest guardrails (Rego)
├── scripts/                    # Bootstrap, CI OIDC/WIF setup, docs generation
└── stacks/                     # Root stacks orchestrating modules (GKE ready, EKS scaffold)
    ├── gcp-gke/
    └── aws-eks/
```

---

## 🧪 CI gates and evidence

### Required gates (what fails the build)
- `terraform fmt -check -recursive`
- `terraform validate` (per stack)
- `tflint` (baseline lint rules)
- `trivy config` (**CRITICAL/HIGH**) for IaC misconfigurations
- `conftest` (OPA baseline policies)

### Evidence artifacts (what reviewers/auditors can inspect)
- Terraform **plan outputs** (text/JSON), when plan workflow is enabled
- Scan outputs (Trivy / TFLint / Conftest results) in workflow logs
- GitHub Environment approvals for production applies

> See: `docs/07-auditor-grade-apply.md` and `docs/09-branch-protection.md`.

---

## 🚀 Quickstart (GCP / GKE)

> **Guardrail:** if `enable_private_endpoint=false`, you **must** provide `allowed_admin_cidrs` (control plane allowlist). The policy gate will block unsafe configs.

### 0) Prerequisites
- Terraform `>= 1.6.0`
- `gcloud` authenticated to your GCP project
- GNU `make`

### 1) Bootstrap remote state (GCS)
This repo uses remote state by default. Create state buckets with **Versioning + UBLA + Public Access Prevention**:

```bash
PROJECT_ID="my-project" REGION="us-central1" ENV=dev  ./scripts/bootstrap_state_gcp.sh
PROJECT_ID="my-project" REGION="us-central1" ENV=prod ./scripts/bootstrap_state_gcp.sh
```

### 2) (Recommended) Setup Workload Identity Federation for CI
Avoid static service-account keys in GitHub:

```bash
PROJECT_ID="my-project" GH_OWNER="my-github-user-or-org" GH_REPO="enterprise-k8s-baseline" USE_CUSTOM_ROLES=1 ./scripts/setup_ci_gcp.sh
```

Then set repository variables (GitHub → Settings → Variables):
- `GCP_WIF_PROVIDER`
- `GCP_TF_PLAN_SA`
- `GCP_TF_APPLY_SA`

### 3) Configure environment variables
```bash
cp envs/gcp/dev/terraform.tfvars.example envs/gcp/dev/terraform.tfvars
```

### 4) Plan & Apply (local)
```bash
make gcp-dev-init
make gcp-dev-plan
make gcp-dev-apply
```

---

## 🏭 Production posture (recommended)

- **Dev posture:** public control plane endpoint + strict `allowed_admin_cidrs` (fast to operate)
- **Prod posture:** `enable_private_endpoint=true` (requires VPN/bastion for kubectl access)
- Enable `deletion_protection=true` in **prod** env vars to reduce accidental destroy risk

---

## 🛡️ Security & compliance checks (local)

Run the same checks locally that run in CI:

```bash
make validate   # terraform validate (stacks)
make lint       # tflint
make scan       # trivy config
make policy     # conftest (OPA guardrails)
make docs       # terraform-docs for modules
```

---

## 🔐 Branch protection (recommended settings)

Because branch protection is configured in GitHub (not via Terraform files), the repo includes a checklist:
- Require PRs + approvals
- Require status checks (CI jobs) before merging
- Enforce linear history (optional)
- Include administrators (recommended)

See: **`docs/09-branch-protection.md`**.

---

## 📖 Deep dive documentation

- [Security Controls Library (What/Why/How)](docs/02-controls.md)
- [Cloud-Agnostic Interface Contract](docs/03-interfaces.md)
- [GitHub Actions OIDC: Plan vs Apply Identities](docs/06-ci-identities.md)
- [Auditor-grade Apply Flow](docs/07-auditor-grade-apply.md)
- [Custom Roles (Least Privilege without projectIamAdmin)](docs/08-custom-roles.md)
- [Branch Protection Checklist](docs/09-branch-protection.md)

---

## 🧭 Roadmap
- ✅ GKE baseline (private nodes, WI, locked-down network)
- 🟡 EKS baseline implementation (IRSA + private nodegroups + parity with controls)

---

## 📜 License
MIT — see [LICENSE](LICENSE).

---

<p align="center">
  <b>Developed by Wellington de Freitas</b> | <i>Cloud Security & DevSecOps Architect</i>
  <br><br>
  <a href="https://linkedin.com/in/welldefreitas" target="_blank">
    <img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn">
  </a>
  <a href="https://github.com/welldefreitas" target="_blank">
    <img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub">
  </a>
  <a href="https://instagram.com/welldefreitas" target="_blank">
    <img src="https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white" alt="Instagram">
  </a>
</p>
