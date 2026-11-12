terraform {
  required_version = "~> 1.17.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.9.0"
    }
  }
  backend "gcs" {
    bucket = "openci-b1b91-orchard-tfstate"
    prefix = "macos-release/production"
  }
}

provider "google" {
  project                         = "openci-b1b91"
  region                          = "asia-northeast1"
  add_terraform_attribution_label = false
}
