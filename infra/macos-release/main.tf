resource "google_storage_bucket" "releases" {
  name                        = "openci-b1b91-releases"
  location                    = "ASIA-NORTHEAST1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
  force_destroy               = false
  encryption {
    customer_supplied_encryption_enforcement_config {
      restriction_mode = "FullyRestricted"
    }
  }
  soft_delete_policy {
    retention_duration_seconds = 604800
  }
  cors {
    origin          = ["https://openci.org", "https://dashboard.openci.org"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type", "Content-Length", "ETag"]
    max_age_seconds = 3600
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Only signed, public release files belong in this bucket. No credentials,
# build logs, source trees, or Terraform state may be uploaded here.
resource "google_storage_bucket_iam_member" "download" {
  bucket = google_storage_bucket.releases.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_service_account" "publisher" {
  account_id   = "macos-release"
  display_name = "OpenCI macOS release publisher"
}

resource "google_storage_bucket_iam_member" "publish" {
  bucket = google_storage_bucket.releases.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.publisher.email}"
}

output "feed_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.releases.name}/macos/stable/appcast.xml"
}

output "publisher" {
  value = google_service_account.publisher.email
}
