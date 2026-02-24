resource "google_service_account" "nodes" {
  account_id   = substr(replace(var.name, "_", "-"), 0, 28)
  display_name = "GKE node SA (${var.name})"
}

locals {
  base_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
  ]

  optional_roles = var.enable_artifact_registry_reader ? ["roles/artifactregistry.reader"] : []
  roles          = concat(local.base_roles, local.optional_roles)
}

resource "google_project_iam_member" "node_roles" {
  for_each = toset(local.roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.nodes.email}"
}
