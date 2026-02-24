# AWS/EKS baseline scaffold (TODO)
# This stack intentionally exists to preserve the cloud-agnostic layout and interface.

terraform {
  backend "local" {}
}

# Scaffold outputs so linters don't fail on unused declarations.
resource "terraform_data" "scaffold" {
  input = {
    region       = var.region
    cluster_name = var.cluster_name
  }
}
