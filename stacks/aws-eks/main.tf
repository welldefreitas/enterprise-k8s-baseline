# AWS stack scaffold (WIP).
# Keep variable interface aligned with GKE so callers can switch providers with minimal changes.
locals {
  _wip_interface_contract = {
    region       = var.region
    cluster_name = var.cluster_name
  }
}

# AWS/EKS baseline scaffold (TODO)
# This stack intentionally exists to preserve the cloud-agnostic layout and interface.

terraform {
  backend "local" {}
}
