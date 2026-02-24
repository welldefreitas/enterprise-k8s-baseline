output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_endpoint" {
  value = module.gke.cluster_endpoint
}

output "cluster_ca_certificate" {
  value     = module.gke.cluster_ca_certificate
  sensitive = true
}

output "workload_identity_mode" {
  value = module.gke.workload_identity_mode
}

output "network_id" {
  value = module.network.network_id
}

output "subnet_id" {
  value = module.network.subnet_id
}
