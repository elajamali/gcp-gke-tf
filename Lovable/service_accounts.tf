resource "google_service_account" "spacelift" {
  project      = var.project_id
  account_id   = "spacelift-deployer"
  display_name = "Service Account for Spacelift"
}

resource "google_project_iam_member" "spacelift_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.spacelift.email}"
}

resource "google_service_account" "mgmt_cluster" {
  project      = var.project_id
  account_id   = "gke-mgmt-cluster"
  display_name = "Service Account for MGMT GKE Cluster Nodes"
}

resource "google_service_account" "sandbox_cluster" {
  project      = var.project_id
  account_id   = "gke-sandbox-cluster"
  display_name = "Service Account for Sandbox GKE Cluster Nodes"
}

# Common roles for GKE node service accounts
locals {
  gke_node_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.viewer",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/cloudtrace.agent",
    "roles/container.admin", # Typically container.admin is for a user/admin SA, nodes need less.
    # More least-privilege roles for nodes:
    # "roles/container.nodeServiceAccount" # - This is a good starting point
  ]
}

resource "google_project_iam_member" "mgmt_cluster_roles" {
  for_each = toset(local.gke_node_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.mgmt_cluster.email}"
}

resource "google_project_iam_member" "sandbox_cluster_roles" {
  for_each = toset(local.gke_node_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.sandbox_cluster.email}"
}

# Enable APIs for OpenTelemetry, etc.
resource "google_project_service" "apis" {
  project            = var.project_id
  for_each           = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudtrace.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}
