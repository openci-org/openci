# Mac worker configuration

Ansible manages the six physical Mac minis connected to the GCP Orchard
Controller. Run it from an operator machine on the same Tailnet. The existing
SSH keys, worker names, launchd labels, runtime versions, VM slots and Tart data
directories are preserved.

| Managed here                | Mechanism                                                        |
| --------------------------- | ---------------------------------------------------------------- |
| Management SSH keys         | `ansible.posix.authorized_key`, additive                         |
| Key-only SSH                | Validated `sshd_config.d` file and fresh connection check        |
| Worker launchd definition   | Validated plist template                                         |
| Worker service              | `community.general.launchd`                                      |
| Worker bootstrap credential | Existing root-only file; optional seed for a missing file        |
| Runtime versions            | Checked against the inventory; unexpected versions stop the play |

The Controller's GCP resources belong to [infra/orchard](../orchard/README.md).
Packer builds guest VM images. This playbook configures running Mac hosts; it
does not create or reset macOS installations, upgrade Homebrew packages, install
guest SDKs, change Softnet/Tailscale policies, or change account passwords.

## Setup

The operator needs Python 3.12–3.14, SSH access and the Mac admin's sudo password.
The existing hosts use `/usr/bin/python3` 3.9.6, supported by the pinned
ansible-core. Passwords, private keys and token values do not belong in this
directory, inventory, command-line extra vars or Git.

```sh
cd infra/mac-workers
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml -p .ansible/collections
ansible-inventory --graph
```

If a python.org macOS Python installation cannot find the system CA certificates,
use `SSL_CERT_FILE=/etc/ssl/cert.pem` for the Galaxy install. Keep TLS verification
enabled. `ansible.cfg` enables SSH host key checking; verify each host's fingerprint
before adding it to the operator's `known_hosts`.

SSH uses `~/.ssh/id_ed25519`; `--private-key` can select another key. The default
management public key is read from `~/.ssh/id_ed25519.pub`. Override
`mac_admin_authorized_keys` in an ignored `local.yml` when using other management
keys, then add `-e @local.yml` to the commands below. Existing keys are retained;
this is not a key revocation playbook. No persistent agent runs on the Macs.

## Review and apply

```sh
ansible-playbook site.yml --syntax-check
ansible-lint --offline
ansible-playbook site.yml --limit hobbydevelop --check --diff --ask-become-pass
ansible-playbook site.yml --limit hobbydevelop --diff --ask-become-pass
ansible-playbook site.yml --check --diff --ask-become-pass
ansible-playbook site.yml --diff --ask-become-pass
```

`--ask-become-pass` asks for sudo, not an SSH password. All hosts are handled
serially, and any failure stops the rollout. Check mode reads live configuration
and predicts differences without changing it. A normal repeat should report
`changed=0`. Root owns the credential directory (`0700`) and file (`0600`).

The plist starts Orchard as root with `--user admin`, matching the existing
Orchard Local Network helper setup. Orchard drops worker privileges to `admin`;
Tart and cached images remain under `/Users/admin`. `StandardInPath` supplies the
bootstrap token, so it is absent from process arguments and the plist. With a
certificate-bearing bootstrap token, Orchard's `--no-pki` verifies the embedded
Controller certificate rather than the system CA set.

No worker restart occurs when its definition is unchanged and it is running.
If a service change is needed, normal apply stops before writing worker files.
Review the diff, pause that worker's scheduling in the Controller, and wait until
all assigned VMs have been deleted. Use the configured, certificate-pinned
operator Orchard context to manage scheduling; do not use a Controller admin
token on the worker.

Then supply `ORCHARD_SERVICE_ACCOUNT_TOKEN` securely in the operator environment
(the existing `build-executor` account has the required read access) and run:

```sh
ansible-playbook site.yml --limit hobbydevelop --diff --ask-become-pass \
  -e orchard_worker_allow_restart=true
```

Before changing the service, the play checks the Controller's
`scheduling_paused` flag, the absence of assigned VMs, and local Tart's running VM
list. A worker name not yet registered with the Controller is also allowed after
these checks. Controller requests verify `../orchard/controller-ca.crt`, do not
follow redirects, and hide authentication data from output. The play never
resumes scheduling automatically: verify a fresh Controller heartbeat and the
expected resources, then resume the worker. On failure it stays paused.
Operator-side API checks use the certificate's Tailnet IP (`100.66.22.93`) so
they also work without MagicDNS on the operator's machine. Worker registration
and launchd names cannot be changed through this maintenance path; a rename
needs an explicit migration of the old identity.

Changes to the plist and SSH configuration keep a timestamped backup on the
host. If a changed worker fails to connect, keep it paused, restore its previous
plist from that backup, and reload that launchd job. No restart is needed to
activate SSH settings for new connections. Recheck `sshd -t` and a new key login
when restoring SSH configuration.

## Inventory and future hosts

The inventory records the actual installation paths and versions adopted on
2026-11-01. Tart versions differ between existing hosts; package upgrades should
be reviewed and tested separately from this configuration adoption. Dokyo's
different service label, bootstrap filename, log paths and lack of a `host`
label are intentional. Changing its label would change VM scheduling behavior.

For a replacement Mac, first enroll it in the Tailnet, verify its SSH host key,
install the approved Orchard/Tart binaries and Apple Command Line Tools, and
prepare the `admin` account plus the `base-macos` image. Add its actual paths and
versions to inventory, and update the Controller network allowlist separately.
The play refuses missing or unexpected binaries instead of silently installing a
different release.

If the new Mac has no worker credential, provide an operator-local `0600` file
containing the certificate-pinned `ORCHARD_WORKER_BOOTSTRAP_TOKEN` for the
`mac-workers` Orchard account. Set `orchard_worker_bootstrap_source` to that file's
path in `local.yml`; it is copied with `no_log` and diff disabled. The source is
ignored when a host already has a credential, so adoption never rotates it.
Remove the local copy after provisioning. GCP service-account keys, Executor
credentials and the Controller admin token must not be used as this bootstrap
file or passed to build VMs.

Module references: [authorized_key](https://docs.ansible.com/projects/ansible/latest/collections/ansible/posix/authorized_key_module.html),
[launchd](https://docs.ansible.com/projects/ansible/latest/collections/community/general/launchd_module.html),
[check mode](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_checkmode.html).
