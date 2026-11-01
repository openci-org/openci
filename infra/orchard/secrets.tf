locals {
  orchard_secrets = toset([
    "ORCHARD_CONTROLLER_CONFIG",
    "ORCHARD_CA_CERT",
    "ORCHARD_SERVICE_ACCOUNT_TOKEN",
    "ORCHARD_WORKER_BOOTSTRAP_TOKEN",
  ])

  secret_readers = {
    controller_config = {
      secret  = "ORCHARD_CONTROLLER_CONFIG"
      account = "orchard-controller"
    }
    executor_ca = {
      secret  = "ORCHARD_CA_CERT"
      account = "openci-executor"
    }
    dispatcher_token = {
      secret  = "ORCHARD_SERVICE_ACCOUNT_TOKEN"
      account = "openci-dispatch"
    }
    executor_token = {
      secret  = "ORCHARD_SERVICE_ACCOUNT_TOKEN"
      account = "openci-executor"
    }
    recovery_token = {
      secret  = "ORCHARD_SERVICE_ACCOUNT_TOKEN"
      account = "openci-recovery"
    }
  }
}

# Manage containers and access policies only. Secret payloads/versions never
# enter configuration, plans, or state through this module.
resource "google_secret_manager_secret" "orchard" {
  for_each  = local.orchard_secrets
  secret_id = each.key
  labels = {
    app       = "orchard"
    component = "controller"
  }

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_iam_member" "reader" {
  for_each  = local.secret_readers
  secret_id = google_secret_manager_secret.orchard[each.value.secret].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value.account}@${local.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "controller_logging" {
  project = local.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.controller.email}"
}
