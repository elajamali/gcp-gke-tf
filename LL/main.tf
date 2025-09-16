# main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Specify a suitable version constraint
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# All other resources (VPC, GKE, Service Accounts, etc.) are defined
# in network.tf, gke.tf, service_accounts.tf, and outputs.tf.
# Terraform will load all .tf files in this directory.