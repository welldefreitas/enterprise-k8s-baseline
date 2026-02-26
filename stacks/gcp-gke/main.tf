locals {
  # Placeholder allowlist used to satisfy static scanners without granting access.
  # When control plane is public (enable_private_endpoint=false), you MUST set a real allowlist.
  is_placeholder_allowlist = length(var.allowed_admin_cidrs) == 1 && var.allowed_admin_cidrs[0] == "0.0.0.0/32"
}

# Cross-variable security guardrail. Terraform variable validation cannot reference other variables,
# so we enforce this using a precondition that runs at plan time.
resource "terraform_data" "guardrails" {
  input = {
    enable_private_endpoint = var.enable_private_endpoint
    allowed_admin_cidrs     = var.allowed_admin_cidrs
  }

  lifecycle {
    precondition {
      condition = var.enable_private_endpoint || (!local.is_placeholder_allowlist && length(var.allowed_admin_cidrs) > 0)
      error_message = "Security guardrail: when enable_private_endpoint=false (public control plane), set allowed_admin_cidrs to your office/VPN/bastion CIDRs (not the placeholder 0.0.0.0/32)."
    }
  }
}


module "network" {
  source              = "../../modules/gcp/network"
  project_id          = var.project_id
  region              = var.region
  network_name        = var.network_name
  subnet_name         = "${var.network_name}-subnet"
  subnet_cidr         = var.subnet_cidr
  pods_secondary_cidr = var.pods_secondary_cidr
  svcs_secondary_cidr = var.svcs_secondary_cidr
  enable_cloud_nat    = true
  labels              = var.labels
}

module "iam" {
  source                         = "../../modules/gcp/iam"
  project_id                      = var.project_id
  name                           = "${var.cluster_name}-nodes"
  enable_artifact_registry_reader = var.enable_artifact_registry_reader
  labels                          = var.labels
}

module "gke" {
  source                   = "../../modules/gcp/gke"
  project_id               = var.project_id
  region                   = var.region
  cluster_name             = var.cluster_name

  network_self_link        = module.network.network_self_link
  subnet_self_link         = module.network.subnet_self_link
  pods_range_name          = module.network.pods_range_name
  services_range_name      = module.network.services_range_name

  node_service_account     = module.iam.node_service_account_email
  allowed_admin_cidrs      = var.allowed_admin_cidrs

  private_nodes            = var.private_nodes
  enable_private_endpoint  = var.enable_private_endpoint
  enable_workload_identity = var.enable_workload_identity
  deletion_protection     = var.deletion_protection

  node_count               = var.node_count
  machine_type             = var.machine_type

  labels                   = var.labels
}
