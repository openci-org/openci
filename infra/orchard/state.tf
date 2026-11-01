resource "google_storage_bucket" "terraform_state" {
  name                        = "openci-b1b91-orchard-tfstate"
  location                    = local.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels = {
    app       = "orchard"
    component = "terraform-state"
  }

  versioning {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = 604800
  }

  lifecycle {
    prevent_destroy = true
  }
}
