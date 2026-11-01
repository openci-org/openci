# Terraform operations

This root module manages the existing production Orchard infrastructure in
`openci-b1b91`, `asia-northeast1`. Its fixed project and backend are intentional;
it is not a template for deploying another environment.

## Ownership

Terraform owns:

- The `orchard` VPC, `orchard-tokyo` subnet, reserved public address and three
  `orchard-allow-*` GCP firewall rules. Public HTTPS remains disabled.
- The controller instance, boot disk, persistent data disk and controller
  service account. The data disk remains attached with auto-delete disabled.
- The four `ORCHARD_*` Secret Manager containers and five existing secret-reader
  grants, plus the controller's Logging writer grant. Secret values and secret
  versions are managed separately and are never read into this module's state.
- Four service invocation grants, the dispatch queue's enqueuer grant and the
  dispatcher's self act-as grant, previously set by `grant-runtime-callers.sh`.
- The private, versioned GCS bucket that stores this module's state.

Firebase CLI continues to own Functions, their underlying Run services, Eventarc
triggers and the task queue. The Executor Job's application deployment and
configuration are also outside this module. Terraform uses individual IAM member
resources, not authoritative policy/binding resources, so it preserves other
principals. This is not a migration of all project IAM or all FSC resources.

`startup.sh` and `tailnet-firewall.nft` are VM metadata inputs. They remain the
source for guest provisioning and the controller's Tailnet ingress policy.
Tailscale device enrollment and tailnet-wide access policies remain separate.
Mac worker configuration and build guest network isolation are outside this
module.

The Google provider is the GCP plugin. Repeated secret, caller and firewall
definitions use Terraform's built-in `for_each`. Individual resources keep
production settings and deletion guards visible without additional module
dependencies.

## Toolchain and authentication

Use Terraform 1.17.1 or a newer 1.17.x patch. The Google provider is pinned to
8.9.x and `.terraform.lock.hcl` records the selected package/checksums.
Review provider upgrades separately from infrastructure changes; ordinary
initialization should not use `-upgrade`.

For local administration, use user Application Default Credentials:

```sh
gcloud auth application-default login --project=openci-b1b91 --quiet
```

This creates/refreshes the local ADC login. Do not put service-account JSON keys,
OAuth tokens or secret payloads in `.tf`, `.tfvars`, backend files or Git. The
initial migration used the existing operator login with a short-lived access
token in the process environment; it did not create a service-account key or
grant permissions to build runtime identities. CI integration, if added later,
should use a dedicated federated identity rather than build-VM credentials.

## Normal workflow

Run from the repository root:

```sh
umask 077
terraform -chdir=infra/orchard init
terraform -chdir=infra/orchard fmt -check
terraform -chdir=infra/orchard validate
terraform -chdir=infra/orchard plan -out=orchard.tfplan
terraform -chdir=infra/orchard apply orchard.tfplan
```

Inspect the entire plan before applying it. The normal baseline is **no
changes**. The instance, disks, network, subnet, address, controller account,
secret containers and state bucket have `prevent_destroy` protection. The
instance also retains GCE deletion protection. Do not bypass these protections
to resolve an unexpected replacement plan.

After Firebase Functions deployments, run the same plan/apply workflow to
reconcile invocation grants. Firebase can reset the private Dart service's
invoker policy. Its service is not managed by Terraform; only the specific
caller grant is. The dispatcher omits `invoker: "private"` to avoid Firebase
replacing its queue/invoker grants. Do not restore the removed imperative IAM
script alongside this module.

## Controller and firewall changes

Edit the scripts or Terraform definition, then review/apply the plan. The
instance uses `metadata["startup-script"]`, **not** the provider's
`metadata_startup_script` argument: the latter can force instance replacement
when changed or added during import.

Updating metadata does not immediately rerun the script or load new nftables
rules. After builds have drained, use the existing IAP access described in
`README.md` and run `sudo google_metadata_script_runner startup` on the
controller, or reboot during a maintenance window. This restarts the controller
and disconnects active exec streams. Check systemd status, TLS/authentication,
worker heartbeats and the effective firewall afterwards.

Changing the pinned `orchard-config-version` metadata reference follows the same
rollout process. Store the new secret payload directly in Secret Manager through
the credential-rotation procedure, not in Terraform.

## State and recovery

- Backend bucket: `gs://openci-b1b91-orchard-tfstate` in `asia-northeast1`.
- Object: `orchard/production/default.tfstate`; use the default workspace only.
- The GCS backend provides state locking. Bucket uniform access and public
  access prevention are enabled, object versioning is enabled, and soft-delete
  retention is seven days. No additional bucket access is granted to the
  application/runtime service accounts. Existing project IAM and the bucket's
  default project-role grants still apply, including read access for project
  viewers.
- Plans, state, local backend metadata and local variable overrides are ignored
  by Git. Commit `.terraform.lock.hcl`.

The state bucket is itself tracked by this state. Initial adoption used a
private local backend to create the bucket and import existing resources, then
migrated that state to GCS. Normal operators only need `terraform init`; do not
repeat the bootstrap or initialize a second independent state for these same
resources.

If state is damaged, stop all Terraform writers and recover a known-good GCS
object generation before planning. Preserve the current object as evidence.
`migrations/2026-10-31-imports.tf.example` preserves the original 26 import
addresses/IDs as a historical record, outside the active configuration. Do not
replay it as a deployment. `moved.tf` maps the original firewall addresses to
their current `for_each` instances; retain these mappings for older state.
Consult both files if deliberate state reconstruction becomes necessary.
A state backup is **not** a backup of the controller's Badger database or disk
contents. Disk snapshot scheduling remains a separate task.

References: [GCS backend](https://developer.hashicorp.com/terraform/language/backend/gcs),
[existing-resource imports](https://docs.cloud.google.com/docs/terraform/resource-management/import),
[Compute instance metadata](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#metadata).
