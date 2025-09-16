output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.main.name
}

output "mgmt_cluster_endpoint" {
  description = "Endpoint of the MGMT GKE cluster"
  value       = google_container_cluster.mgmt_cluster.endpoint
}

output "mgmt_cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for the MGMT GKE cluster"
  value       = google_container_cluster.mgmt_cluster.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "sandbox_cluster_endpoint" {
  description = "Endpoint of the Sandbox GKE cluster"
  value       = google_container_cluster.sandbox_cluster.endpoint
}

output "sandbox_cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for the Sandbox GKE cluster"
  value       = google_container_cluster.sandbox_cluster.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "spacelift_service_account_email" {
  description = "Email of the Spacelift service account"
  value       = google_service_account.spacelift.email
}
