#!/usr/bin/env bash
set -euo pipefail

# Explicit setup only; never run as a Firebase predeploy hook.
project="${1:?Usage: scripts/provision.sh PROJECT_ID}"
region=asia-northeast1
runtime="stacked-pr-runtime@${project}.iam.gserviceaccount.com"
tasks="stacked-pr-tasks@${project}.iam.gserviceaccount.com"

gcloud services enable run.googleapis.com cloudtasks.googleapis.com secretmanager.googleapis.com iamcredentials.googleapis.com --project "$project"
for name in stacked-pr-runtime stacked-pr-tasks; do
  if ! gcloud iam service-accounts describe "$name@$project.iam.gserviceaccount.com" --project "$project" >/dev/null 2>&1; then
    gcloud iam service-accounts create "$name" --project "$project"
  fi
done

gcloud projects add-iam-policy-binding "$project" --member="serviceAccount:$runtime" --role=roles/cloudtasks.enqueuer --condition=None --format=none
gcloud iam service-accounts add-iam-policy-binding "$tasks" --project "$project" --member="serviceAccount:$runtime" --role=roles/iam.serviceAccountUser --format=none
project_number="$(gcloud projects describe "$project" --format='value(projectNumber)')"
# Enabling Cloud Tasks creates its Google-managed service agent. It is not a
# user-managed service account and cannot be queried with service-accounts describe.
gcloud iam service-accounts add-iam-policy-binding "$tasks" --project "$project" --member="serviceAccount:service-${project_number}@gcp-sa-cloudtasks.iam.gserviceaccount.com" --role=roles/iam.serviceAccountTokenCreator --format=none
for secret in STACKED_PR_GITHUB_PRIVATE_KEY STACKED_PR_WEBHOOK_SECRET; do
  gcloud secrets add-iam-policy-binding "$secret" --project "$project" --member="serviceAccount:$runtime" --role=roles/secretmanager.secretAccessor --format=none
done

if gcloud tasks queues describe stacked-pr --location "$region" --project "$project" >/dev/null 2>&1; then
  action=update
else
  action=create
fi
gcloud tasks queues "$action" stacked-pr --location "$region" --project "$project" \
  --max-concurrent-dispatches=1 --max-dispatches-per-second=1 \
  --max-attempts=8 --min-backoff=30s --max-backoff=300s \
  --max-doublings=4 --max-retry-duration=3600s
