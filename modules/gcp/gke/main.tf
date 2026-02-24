resource "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.region

  network    = var.network_self_link
  subnetwork = var.subnet_self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = var.deletion_protection

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = var.private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr
  }

  # Disable legacy client cert issuance to reduce long-lived credential risk.
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # When private endpoint is enabled, manage the cluster from inside the VPC (VPN/bastion).
  # Audit-grade: always enable Master Authorized Networks (even with private endpoint),
  # to keep an explicit allowlist and satisfy static misconfig scanners.
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.allowed_admin_cidrs
      content {
        cidr_block   = cidr_blocks.value
        display_name = "admin"
      }
    }
  }

      }
    }
  }

  enable_shielded_nodes = true

  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  resource_labels = var.labels
}

resource "google_container_node_pool" "primary" {
  name     = "${var.cluster_name}-np"
  cluster  = google_container_cluster.this.name
  location = var.region

  node_count = var.node_count

  node_config {
    machine_type    = var.machine_type
    service_account = var.node_service_account

    # Prevent legacy metadata endpoint credential theft patterns
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Standard: use GKE Metadata server
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = var.labels
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
