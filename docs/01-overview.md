# Overview

This repository implements **Pillar 3: Immutable Infrastructure & IaC**:
- no ClickOps
- repeatable environments (dev/prod)
- secure-by-default Kubernetes baselines

The design is cloud-agnostic:
- Each cloud has a stack (`stacks/<cloud>-<platform>`) implementing the same interface (inputs/outputs).
- Cloud-specific modules live under `modules/<cloud>/...`.

Start with **GCP/GKE** (ready), then implement AWS/EKS with the same contract.
