variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
  # Example: default = "my-gcp-project"
}

variable "region" {
  description = "The Google Cloud region"
  type        = string
  default     = "europe-west2"
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "main-network"
}

variable "subnets" {
  description = "Subnetwork configurations"
  type        = map(object({
    ip_cidr_range = string
    log_config = object({
      flow_sampling      = number
      metadata           = string
      aggregation_interval = string
    })
  }))
  default = {
    "mgmt" = {
      ip_cidr_range = "10.10.0.0/19"
      log_config = {
        flow_sampling      = 0.25
        metadata           = "INCLUDE_ALL_METADATA"
        aggregation_interval = "INTERVAL_15_MIN"
      }
    },
    "sandbox" = {
      ip_cidr_range = "10.13.0.0/19"
      log_config = {
        flow_sampling      = 0.25
        metadata           = "INCLUDE_ALL_METADATA"
        aggregation_interval = "INTERVAL_15_MIN"
      }
    }
  }
}

variable "gke_secondary_ranges" {
  description = "Secondary ranges for GKE clusters"
  type        = map(object({
    pods     = string
    services = string
  }))
  default = {
    "mgmt" = {
      pods     = "10.12.0.0/17"
      services = "10.11.0.0/20"
    },
    "sandbox" = {
      pods     = "10.15.0.0/16"
      services = "10.14.0.0/20"
    }
  }
}

variable "nat_router_log_config" {
  description = "Logging configuration for Cloud NAT"
  type        = object({
    enable = bool
    filter = string
  })
  default = {
    enable = true
    filter = "ALL" # Can be "ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"
  }
}

variable "sandbox_machine_type" {
  description = "Machine type for Sandbox nodes"
  type        = string
  default     = "n4-highmem-16"
}

# Define max resources for NAP, adjust as needed for cost and quota
variable "nap_max_cpu" {
  description = "Maximum total CPU cores for Node Auto Provisioning"
  type        = number
  default     = 10000 # Example value
}

variable "nap_max_memory" {
  description = "Maximum total memory (GB) for Node Auto Provisioning"
  type        = number
  default     = 40000 # Example value
}
