terraform {
  required_version = "~> 1.17.1"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.9.0"
    }
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
  zone    = local.zone

  # Preserve existing labels without adding the provider's ownership label.
  add_terraform_attribution_label = false
}

locals {
  project_id = "openci-b1b91"
  region     = "asia-northeast1"
  zone       = "asia-northeast1-a"
}
