# MGMT Cluster
resource "google_container_cluster" "mgmt_cluster" {
  project  = var.project_id
  name     = "mgmt-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.subnets["mgmt"].id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Enable Connect Gateway
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  maintenance_policy {
    recurring_window {
      start_time = "2025-09-17T02:00:00Z" # Example: Every Tuesday 2 AM UTC
      end_time   = "2025-09-17T06:00:00Z" # Example: Every Tuesday 6 AM UTC
      recurrence = "FREQ=WEEKLY;BYDAY=TU"
    }
  }

  cluster_autoscaling {
    autoscaling_profile = "BALANCED"
    enabled             = true
  }

  lifecycle {
    ignore_changes = [
      node_pool, # Managed separately
    ]
  }
}

resource "google_container_node_pool" "mgmt_primary" {
  project    = var.project_id
  name       = "mgmt-node-pool"
  location   = var.region
  cluster    = google_container_cluster.mgmt_cluster.name
  node_count = 1

  node_config {
    machine_type    = "e2-standard-4" # Or other suitable type
    disk_size_gb    = 250
    disk_type       = "pd-standard"
    service_account = google_service_account.mgmt_cluster.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Sandbox Cluster
resource "google_container_cluster" "sandbox_cluster" {
  project  = var.project_id
  name     = "sandbox-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.subnets["sandbox"].id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Enable Connect Gateway
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  maintenance_policy {
    recurring_window {
      start_time = "2025-09-18T02:00:00Z" # Example: Every Wednesday 2 AM UTC
      end_time   = "2025-09-18T06:00:00Z" # Example: Every Wednesday 6 AM UTC
      recurrence = "FREQ=WEEKLY;BYDAY=WE"
    }
  }

  # Node Auto Provisioning for Sandbox
  cluster_autoscaling {
    enabled             = true
    autoscaling_profile = "BALANCED"

    resource_limits {
      resource_type = "cpu"
      maximum       = var.nap_max_cpu
    }
    resource_limits {
      resource_type = "memory"
      maximum       = var.nap_max_memory
    }
    # Add other resource limits if needed (e.g., GPU)

    auto_provisioning_defaults {
      oauth_scopes = [
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/trace.append",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/servicecontrol",
      ]
      service_account = google_service_account.sandbox_cluster.email
      upgrade_settings {
        max_surge       = 1
        max_unavailable = 0
      }
      management {
        auto_repair  = true
        auto_upgrade = true
      }
    }
    # node_autoprovisioning_enabled = true
  }

  # Default NodePool settings for NAP
  node_pool_defaults {
    node_config_defaults {
      logging_variant = "DEFAULT" # or MAX_THROUGHPUT
      gcfs_config {
        enabled = true # Image streaming
      }
    }
  }

  # Enable GKE Sandbox on default for NAP
  # The block 'default_node_pool_config' is not supported in google_container_cluster.
  # To enable GKE Sandbox, configure it in node pools or NAP settings if supported.

  lifecycle {
    ignore_changes = [
      node_pool, # Managed by NAP
    ]
  }
}

# Optional: A small, initial node pool for the sandbox cluster if needed before NAP kicks in.
# Otherwise, NAP will create all node pools.
# resource "google_container_node_pool" "sandbox_initial" {
#   project    = var.project_id
#   name       = "sandbox-initial-pool"
#   location   = var.region
#   cluster    = google_container_cluster.sandbox_cluster.name
#   node_count = 1
#
#   node_config {
#     machine_type    = var.sandbox_machine_type
#     disk_size_gb    = 250
#     service_account = google_service_account.sandbox_cluster.email
#     sandbox_config {
#       sandbox_type = "GVISOR"
#     }
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#   }
# }
