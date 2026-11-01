locals {
  runtime_callers = {
    createbuildjobs      = "openci-functions"
    queuebuildjobs       = "openci-dispatch"
    process-webhook-task = "openci-functions"
    dispatchbuildjob     = "openci-dispatch"
  }
  dispatcher_email = "openci-dispatch@${local.project_id}.iam.gserviceaccount.com"
}

# Firebase CLI owns service revisions, Eventarc triggers, and the task queue.
# Only these individual invocation grants are Terraform-owned. Member resources
# preserve other principals and avoid replacing whole IAM policies.
resource "google_cloud_run_v2_service_iam_member" "runtime_caller" {
  for_each = local.runtime_callers
  project  = local.project_id
  location = local.region
  name     = each.key
  role     = "roles/run.invoker"
  member   = "serviceAccount:${each.value}@${local.project_id}.iam.gserviceaccount.com"
}

resource "google_cloud_tasks_queue_iam_member" "dispatcher" {
  project  = local.project_id
  location = local.region
  name     = "dispatchBuildJob"
  role     = "roles/cloudtasks.enqueuer"
  member   = "serviceAccount:${local.dispatcher_email}"
}

resource "google_service_account_iam_member" "dispatcher_self" {
  service_account_id = "projects/${local.project_id}/serviceAccounts/${local.dispatcher_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.dispatcher_email}"
}
