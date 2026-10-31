#!/usr/bin/env bash
set -euo pipefail

# Run after deploying Functions. These bindings are scoped to their targets.
project="${OPENCI_PROJECT:-openci-b1b91}"
region="${OPENCI_REGION:-asia-northeast1}"
api_account="${OPENCI_API_SERVICE_ACCOUNT:-openci-functions@${project}.iam.gserviceaccount.com}"
dispatch_account="${OPENCI_DISPATCH_SERVICE_ACCOUNT:-openci-dispatch@${project}.iam.gserviceaccount.com}"

cloud() {
  env -u DEBUG gcloud "$@" --project="$project" --quiet --format='value(etag)'
}

invoke() {
  cloud run services add-iam-policy-binding "$1" --region="$region" \
    --member="serviceAccount:$2" --role=roles/run.invoker
}

# Eventarc uses each trigger's configured service account.
invoke createbuildjobs "$api_account"
invoke queuebuildjobs "$dispatch_account"
# The Node consumer invokes the private Dart Function.
invoke process-webhook-task "$api_account"
# Cloud Tasks signs requests as the dispatcher identity.
invoke dispatchbuildjob "$dispatch_account"
cloud tasks queues add-iam-policy-binding dispatchBuildJob --location="$region" \
  --member="serviceAccount:$dispatch_account" --role=roles/cloudtasks.enqueuer
cloud iam service-accounts add-iam-policy-binding "$dispatch_account" \
  --member="serviceAccount:$dispatch_account" --role=roles/iam.serviceAccountUser \
  --condition=None
