# VPC Network
resource "google_compute_network" "main" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  mtu                     = 1500
}

# Subnetworks
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets
  project  = var.project_id
  name     = "${var.network_name}-${each.key}"
  region   = var.region
  network  = google_compute_network.main.id

  ip_cidr_range = each.value.ip_cidr_range

  private_ip_google_access = true

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [1] : []
    content {
      flow_sampling      = each.value.log_config.flow_sampling
      metadata           = each.value.log_config.metadata
      aggregation_interval = each.value.log_config.aggregation_interval
    }
  }

  dynamic "secondary_ip_range" {
    for_each = var.gke_secondary_ranges[each.key] != null ? [1] : []
    content {
      range_name    = "pods"
      ip_cidr_range = var.gke_secondary_ranges[each.key].pods
    }
  }
  dynamic "secondary_ip_range" {
    for_each = var.gke_secondary_ranges[each.key] != null ? [1] : []
    content {
      range_name    = "services"
      ip_cidr_range = var.gke_secondary_ranges[each.key].services
    }
  }
}

# Cloud Router
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.main.id
}

# NAT IP Addresses
resource "google_compute_address" "nat" {
  project      = var.project_id
  name         = "${var.network_name}-nat-ip"
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
  count        = 2 # Adjust number of NAT IPs as needed
}

# Cloud NAT Gateway
resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = google_compute_address.nat.*.self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  enable_endpoint_independent_mapping = false
  enable_dynamic_port_allocation      = true
  min_ports_per_vm                    = 2048 # Example, tune as needed

  log_config {
    enable = var.nat_router_log_config.enable
    filter = var.nat_router_log_config.filter
  }
}

# Firewall Rules
resource "google_compute_firewall" "allow_healthcheck" {
  project = var.project_id
  name    = "${var.network_name}-allow-healthcheck"
  network = google_compute_network.main.name
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
  priority      = 30000
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_iap" {
  project = var.project_id
  name    = "${var.network_name}-allow-iap"
  network = google_compute_network.main.name
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["35.235.240.0/20"]
  priority      = 30000
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_icmp" {
  project = var.project_id
  name    = "${var.network_name}-allow-icmp"
  network = google_compute_network.main.name
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_internal_tcp" {
  project = var.project_id
  name    = "${var.network_name}-allow-internal-tcp"
  network = google_compute_network.main.name
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["10.0.0.0/8"]
  priority      = 65534
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
