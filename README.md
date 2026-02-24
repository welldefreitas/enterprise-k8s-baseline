# 🏗️ Enterprise-grade Terraform Baseline for Kubernetes (GKE/EKS)

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D_1.6.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![Google Cloud](https://img.shields.io/badge/Google_Cloud-GKE-4285F4?logo=google-cloud)](https://cloud.google.com/)
[![AWS](https://img.shields.io/badge/AWS-EKS_(WIP)-232F3E?logo=amazon-aws)](https://aws.amazon.com/)
[![Security](https://img.shields.io/badge/Security-Zero--Trust-red)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Provision **secure-by-default**, private, and cloud-agnostic Kubernetes clusters using Terraform. **Stop ClickOps.**

This repository implements **Pillar 3 of a modern DevSecOps architecture: Immutable Infrastructure & IaC**. It provides a baseline that passes strict corporate audits, enforcing Zero-Trust networking, Workload Identity, and Policy-as-Code.

The design is strictly **cloud-agnostic**:
* **GCP (GKE)**: Production-ready baseline (Private nodes, locked-down VPC-native network, Least-privilege IAM, Workload Identity).
* **AWS (EKS)**: Scaffolded (Enforces the exact same interface and contract) — *Implementation WIP*.

---

## 🌟 Key Features (Consulting-Grade)

### 🔒 Security & Identity (Zero-Trust)
* **Workload Identity / IRSA:** No static, long-lived cloud keys inside pods. Native federation by default.
* **Least Privilege IAM:** Dedicated node Service Accounts with minimal roles (logs/metrics only). Artifact Registry access is strictly opt-in.
* **Private Nodes:** Nodes have no public IPs, eliminating direct internet exposure.
* **Control Plane Allowlist:** Public endpoints are protected by strictly enforced CIDR allowlists (Master Authorized Networks).

### 🌐 Network & Architecture
* **VPC-Native (GCP):** Custom VPC with dedicated subnets and secondary IP ranges for Pods and Services to prevent IP exhaustion.
* **Egress Control:** Cloud NAT configured for controlled outbound traffic with error-only logging.

### 🤖 DevSecOps & CI/CD Gates
* **Auditor-Grade Apply:** Uses a "Plan then Apply" workflow. Applies are strictly tied to manual approval via GitHub Environments.
* **OIDC Identity Split:** Separate read-only (`tf-plan`) and write (`tf-apply`) identities for GitHub Actions using Workload Identity Federation (no secrets stored in GitHub).
* **Policy-as-Code (OPA/Conftest):** Rego policies mathematically enforce security guardrails directly on the HCL code before any plan is generated.
* **Shift-Left Security:** Continuous scanning with `trivy config` (IaC misconfigurations) and `tflint`.

---

## 📂 Repository Architecture (Directory Tree)

This repository follows a modular, highly decoupled structure designed for scale and team collaboration:

```text
enterprise-k8s-baseline/
├── .github/workflows/    # 🛡️ Auditor-grade CI/CD pipelines (Plan/Apply with OIDC, Trivy, TFLint)
├── docs/                 # 📚 Architectural Decision Records (ADRs) and compliance docs
├── envs/                 # 🌍 Environment-specific configurations (vars and remote state config)
│   └── gcp/
│       ├── dev/          # Dev parameters (e.g., smaller nodes, no deletion protection)
│       └── prod/         # Prod parameters (e.g., HA, deletion protection enabled)
├── modules/              # 🧱 Reusable, secure-by-default Terraform modules
│   ├── gcp/
│   │   ├── gke/          # Engine: Hardened cluster, node pools, metadata security
│   │   ├── iam/          # Identity: Least privilege service accounts
│   │   └── network/      # Foundation: VPC, Subnets, Cloud NAT, Firewalls
│   └── aws/              # AWS specific modules (TODO)
├── policies/opa/         # 👮 Policy-as-Code (Rego) to enforce guardrails on Terraform HCL
├── scripts/              # 🛠️ Day-2 operations: WIF setup, state bootstrapping, doc generation
└── stacks/               # 🎛️ The "Mainboards" - Cloud-agnostic root modules orchestrating submodules
    ├── gcp-gke/          # GCP Stack implementation
    └── aws-eks/          # AWS Stack implementation (TODO)
```





## 🚀 Quickstart (GCP / GKE)

> **Security Guardrail:** If `enable_private_endpoint=false`, you *must* provide `allowed_admin_cidrs` (control plane allowlist) or the Terraform plan will fail validation.

### 0) Prerequisites
* Terraform `>= 1.6.0`
* `gcloud` CLI authenticated to your GCP Project
* GNU `make`

### 1) Bootstrap Remote State
This repository enforces remote state (GCS) by default. Create the highly secure state buckets (Versioning + UBLA + Public Access Prevention):
```bash
PROJECT_ID="my-project" REGION="us-central1" ENV=dev  ./scripts/bootstrap_state_gcp.sh
PROJECT_ID="my-project" REGION="us-central1" ENV=prod ./scripts/bootstrap_state_gcp.sh
```


### 2) Setup Workload Identity Federation for CI/CD (Optional but Recommended)
Avoid storing static service account keys in GitHub. Run the automated OIDC bootstrap:
```bash
PROJECT_ID="my-project" GH_OWNER="my-github-user" GH_REPO="enterprise-k8s-baseline" ./scripts/setup_ci_gcp.sh
```

### 3) Configure Environments
Copy the example variables and configure your specific CIDRs and cluster names:
```bash
cp envs/gcp/dev/terraform.tfvars.example envs/gcp/dev/terraform.tfvars
```

### 4) Plan & Apply via Makefile
The `Makefile` simplifies complex backend initializations:
```bash
make gcp-dev-init
make gcp-dev-plan
make gcp-dev-apply
```

## 🛡️ Security & Compliance Checks

Run the same checks locally that run in the CI pipeline:

```bash
# Validate syntax and module constraints
make validate

# Run Terraform Linter
make lint

# Run Trivy IaC Security Scanner
make scan

# Run OPA/Conftest Baseline Policies (HCL2)
make policy

# Auto-generate Markdown documentation for modules
make docs
```

## 📖 Deep Dive Documentation

For auditors and platform engineers, detailed decisions are documented in the `docs/` folder:
* [Security Controls Library (What/Why/How)](docs/02-controls.md)
* [Cloud-Agnostic Interface Contract](docs/03-interfaces.md)
* [GitHub Actions OIDC: Plan vs Apply Identities](docs/06-ci-identities.md)
* [Auditor-grade Apply Flow](docs/07-auditor-grade-apply.md)

---

<p align="center">
  <b>Developed by Wellington de Freitas</b> | <i>Cloud Security & AI Architect</i>
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

