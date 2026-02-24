output "network_id" {
  value = google_compute_network.this.id
}

output "network_self_link" {
  value = google_compute_network.this.self_link
}

output "subnet_id" {
  value = google_compute_subnetwork.this.id
}

output "subnet_self_link" {
  value = google_compute_subnetwork.this.self_link
}

output "pods_range_name" {
  value = "pods"
}

output "services_range_name" {
  value = "services"
}
