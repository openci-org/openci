# Orchard Controller on GCP (G-1580)

The controller runs on a single Compute Engine VM. macOS builds run on the
separate Orchard workers. The controller's Badger database needs a persistent
filesystem; this deployment does not use Cloud Run for the controller.

| Resource             | Configuration                                                |
| -------------------- | ------------------------------------------------------------ |
| Project              | `openci-b1b91`                                               |
| Instance             | `orchard-controller`                                         |
| Zone                 | `asia-northeast1-a`                                          |
| Machine              | `e2-small` (2 GiB RAM, shared CPU)                           |
| OS                   | Debian 12, image `debian-12-bookworm-v20261027`              |
| Orchard              | `0.58.0`, release binary verified by SHA-256 in `startup.sh` |
| VPC endpoint         | `https://10.77.0.2:443`                                      |
| Tailnet endpoint     | `https://orchard-controller-gcp.tail4beb18.ts.net:443`       |
| Reserved address     | `orchard-controller-ip`                                      |
| Network / subnet     | `orchard` / `orchard-tokyo` (`10.77.0.0/24`)                 |
| Boot / data disk     | 10 GiB / 10 GiB, `pd-balanced`                               |
| Data disk            | `orchard-controller-data`, mounted at `/var/lib/orchard`     |
| GCP runtime identity | `orchard-controller@openci-b1b91.iam.gserviceaccount.com`    |

The VM has deletion protection. The data disk has `autoDelete=false` and must
remain attached to only one running controller. Daily backups are not configured.
Before upgrading Orchard, stop the controller and snapshot the data disk.

`startup.sh` installs the pinned binary, mounts the data disk, and enables
`orchard-tailnet-firewall.service`, `orchard-secrets.service` and
`orchard-controller.service`. systemd restarts the
controller after failure or host reboot. The service runs as the unprivileged
`orchard` user with only the capability needed to bind port 443.

## TLS and credentials

`controller-ca.crt` is the public certificate to trust. Its SAN includes the VPC IP, Tailnet IP/hostname,
loopback and the reserved public IP (for rollback only). HTTPS/WSS clients must verify this certificate; do not disable TLS
verification. Keep `:443` explicit in Orchard CLI URLs: its default port is 6120,
even when the scheme is HTTPS. VPC clients use the internal IP. Mac workers use the Tailnet hostname with MagicDNS.

Secret Manager holds these secrets in `asia-northeast1`:

| Secret                           | Purpose                                                                  |
| -------------------------------- | ------------------------------------------------------------------------ |
| `ORCHARD_CONTROLLER_CONFIG`      | JSON containing `bootstrap_token`, `certificate`, and `private_key`      |
| `ORCHARD_CA_CERT`                | Public PEM certificate for application configuration                     |
| `ORCHARD_SERVICE_ACCOUNT_TOKEN`  | Token for the Orchard `build-executor` account                           |
| `ORCHARD_WORKER_BOOTSTRAP_TOKEN` | Certificate-pinned bootstrap token for the Orchard `mac-workers` account |

Only `ORCHARD_CONTROLLER_CONFIG` is accessible to the controller's GCP service
account. It also has `roles/logging.logWriter` for GCE startup logs. The instance
metadata pins the config secret version through
`orchard-config-version=projects/openci-b1b91/secrets/ORCHARD_CONTROLLER_CONFIG/versions/2`.
The startup script contains no credentials. The root secret loader uses the VM's
identity and writes private files to `/run/orchard`, which is cleared on reboot.

The Orchard `build-executor` account has `compute:read`, `compute:write`, and
`compute:connect`. `mac-workers` has `compute:read` and `compute:write`. Neither
account has Orchard admin access. The bootstrap administrator is reserved for
controller administration and is not passed to builds or workers.

When rotating the controller certificate or bootstrap credentials, create a new
config secret version, update the pinned metadata version, and restart both
services. Update the public certificate and worker bootstrap token together.

## Connect the FSC runtimes

Configure the dispatcher, executor Job, and recovery Function with:

```text
ORCHARD_API_URL=https://10.77.0.2:443
ORCHARD_SERVICE_ACCOUNT_NAME=build-executor
ORCHARD_CA_CERT=<contents of controller-ca.crt>
ORCHARD_SERVICE_ACCOUNT_TOKEN=<Secret Manager binding>
```

The dispatcher and recovery Function use `orchard_network.ts`: Direct VPC
via `ORCHARD_VPC_NETWORK=orchard`, `ORCHARD_VPC_SUBNETWORK=orchard-tokyo`, the
`orchard-client` network tag, and `PRIVATE_RANGES_ONLY` egress. Keep GitHub and
Google API traffic on the normal serverless route; no VPC connector or Cloud NAT
is needed for this connection. Other Functions do not join the Orchard network.

When provisioning the executor Job, include these options:

```text
--network=orchard
--subnet=orchard-tokyo
--network-tags=orchard-client
--vpc-egress=private-ranges-only
```

The `orchard-allow-private-https` firewall rule permits TCP 443 from the dedicated
`orchard-tokyo` subnet (`10.77.0.0/24`) to the `orchard-controller` destination
tag. Cloud Run Direct VPC does not support source network tags in ingress
firewall rules; use the subnet range as required by the
[Direct VPC limitations](https://docs.cloud.google.com/run/docs/configuring/vpc-direct-vpc#limitations).
Keep this subnet dedicated to Orchard and its authorized runtimes. The
`orchard-client` tag is not an ingress authorization boundary. Retain token
authentication and TLS, and keep the public `orchard-allow-https` rule disabled.

The runtime identities need access to `ORCHARD_SERVICE_ACCOUNT_TOKEN`. Cloud Run
can bind `ORCHARD_CA_CERT` as a secret environment variable; the Firebase
dispatcher currently reads it as a string parameter. See
[`BUILD_DISPATCH.md`](../../firebase/functions/BUILD_DISPATCH.md) and
[`BUILD_EXECUTOR.md`](../../firebase/functions/BUILD_EXECUTOR.md).

To connect a Mac interactively, install Orchard/Tart and supply the bootstrap
token on stdin (not a command-line argument):

```sh
gcloud secrets versions access latest \
  --project=openci-b1b91 --secret=ORCHARD_WORKER_BOOTSTRAP_TOKEN |
  orchard worker run https://orchard-controller-gcp.tail4beb18.ts.net:443 --bootstrap-token-stdin --no-pki
```

Here `--no-pki` verifies the controller against the certificate embedded in the
bootstrap token. Use launchd for permanent workers, after draining any builds on
their old controller. Do not run two worker processes managing the same Mac.

## Tailnet access

Tailscale is installed from its signed Debian Bookworm repository (version
`1.104.4`). The approved node is `orchard-controller-gcp`, with address
`100.66.22.93`, in the `open-ci.io` Tailnet. It uses
`--accept-dns=false --accept-routes=false --ssh=false`; GCP DNS and IAP
administration remain available. No exit node, subnet route or Funnel is enabled.

`tailnet-firewall.nft` restricts traffic entering `tailscale0` to TCP 443 from
the listed Mac workers and operator Macs, for both IPv4 and IPv6. Other Tailnet
ingress, including SSH, is dropped. Replies to connections initiated by the
controller are allowed. GCP VPC and IAP traffic use a separate interface and are
controlled by the GCP firewall rules. This allowlist is enforced on the
controller; Tailnet-wide access policies are managed separately in Tailscale.

`orchard-tailnet-firewall.service` loads the rules before `tailscaled` starts.
Tailscale requires this service, so a policy-load failure prevents it from
starting. The node's shields-up setting is disabled after installing the rules.
Policy updates replace only the `orchard_tailnet` table, without flushing other
firewall rules. Reloading the service applies updates atomically.

When adding or replacing a Mac, update both addresses in
`tailnet-firewall.nft` and the VM metadata below. The current Tailscale node key
expires on **2027-04-28**; renew it or configure the controller as a tagged
infrastructure device in the Tailscale admin console before that date.

## Operations

`orchard-allow-https` is disabled: public TCP 443 is closed. TCP 22 is
restricted to the IAP TCP forwarding range
`35.235.240.0/20`. The VM uses OS Login; connect with:

```sh
gcloud compute ssh orchard-controller --project=openci-b1b91 \
  --zone=asia-northeast1-a --tunnel-through-iap
```

Useful checks on the VM:

```sh
sudo systemctl is-active orchard-tailnet-firewall tailscaled orchard-secrets orchard-controller
sudo systemctl show orchard-controller -p MemoryCurrent -p NRestarts
sudo journalctl -u orchard-controller --since '10 minutes ago'
sudo nft list table inet orchard_tailnet
sudo tailscale status
df -h /var/lib/orchard
```

Update the startup script from the repository root:

```sh
gcloud compute instances add-metadata orchard-controller \
  --project=openci-b1b91 --zone=asia-northeast1-a \
  --metadata-from-file=startup-script=infra/orchard/startup.sh,orchard-tailnet-firewall=infra/orchard/tailnet-firewall.nft
```

Apply it during a maintenance window using `sudo google_metadata_script_runner
startup` or a reboot. This restarts the controller and disconnects active exec
streams. Controller deployment alone does not deploy Functions/Cloud Run, migrate
FSC data, move production workers, or switch GitHub webhook traffic.

## Network rollout verification

`check-network.mjs` is a read-only Cloud Run Job probe. It verifies the internal
endpoint with the configured certificate, expects anonymous requests to return
401, and checks authenticated workers/VMs reads. Bind `ORCHARD_CA_CERT:2` and
`ORCHARD_SERVICE_ACCOUNT_TOKEN:1`, use the same Direct VPC settings as above,
and use a dedicated identity with access only to those two secrets. Remove the
temporary Job and its secret IAM bindings after verification.

The network probe only checks connectivity. The subsequent business runtime
deployment and build verification are recorded in
[FSC deployment](../../firebase/functions/DEPLOYMENT.md).

As of 2026-10-30, the VPC probe succeeded both before and after closing public 443. A second Job without the allowed network tag could not connect to the
private endpoint. External probes of ports 443, 22 and 6120 timed out; IAP SSH
still worked. Local validation passed: TypeScript build/lint, 88 Node tests,
format checks, Bash syntax, ShellCheck and diff checks.

After device approval, all six online Mac minis passed certificate-verified
HTTPS checks through the Tailnet IP and MagicDNS name. Anonymous requests
returned 401. Temporarily removing one Mac from the host allowlist caused its
connections to time out and incremented the firewall drop counter; restoring
the allowlist restored access. The other five Macs remained reachable throughout.
One Mac also verified authenticated worker/VM reads (200), IPv6 TLS validation,
and rejection of Tailnet SSH. The network check did not register a worker or
create a VM. Public ingress was closed while the new controller had no workers
or VMs.

Later on 2026-10-30, `genuineci-worker-dokyo` was drained, paused on the old
controller and connected to this controller through launchd. A controlled Cloud
Run build passed static analysis and 131 Dart tests, finalized its logs and usage,
updated GitHub Checks and deleted its VM. During the 2026-10-31 JST cutover, the
other five workers (`growth`, `hobbydevelop`, `kiai`, `nakama`, `origin`) moved to
this controller. All six old controller registrations are paused, and production
webhooks now use FSC. Their previous launchd configuration and bootstrap token
are backed up in root-only directories on each Mac. See the
[production cutover record](../../firebase/functions/DEPLOYMENT.md).

The old controller container and data volume were backed up and removed later
on 2026-10-31 JST. See [the retirement record](../../firebase/functions/LEGACY_RETIREMENT.md)
for backup locations and restore verification. This does not replace the pending
backup configuration for this GCP controller's data disk.

References: [Orchard deployment](https://tart.run/orchard/deploying-controller/),
[worker deployment](https://tart.run/orchard/deploying-workers/),
[Orchard 0.58.0](https://github.com/openai/orchard/releases/tag/0.58.0).
