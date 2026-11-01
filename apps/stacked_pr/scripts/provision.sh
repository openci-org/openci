#!/usr/bin/env bash
set -euo pipefail

# Explicit setup only; never run as a Firebase predeploy hook.
project="${1:?Usage: scripts/provision.sh PROJECT_ID}"
runtime="stacked-pr-runtime@${project}.iam.gserviceaccount.com"
tasks="stacked-pr-tasks@${project}.iam.gserviceaccount.com"

gcloud services enable cloudfunctions.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com cloudtasks.googleapis.com secretmanager.googleapis.com iamcredentials.googleapis.com --project "$project"
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

# Firebase CLI creates/updates the stackedPrWorker queue from onTaskDispatched.
# The explicit invoker in src/index.ts keeps the worker private across deployments.
