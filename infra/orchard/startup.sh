#!/usr/bin/env bash
set -euo pipefail
umask 077

# GCE startup script for Debian 12. Keep secrets out of instance metadata/logs.
readonly orchard_version=0.58.0
readonly orchard_sha256=aab11b6ffa704eab04f43c34e0b8765f671afc09824b334ee80e03bd9791192c
readonly tailscale_version=1.104.4
readonly data_device=/dev/disk/by-id/google-orchard-data
readonly data_mount=/var/lib/orchard

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends ca-certificates curl python3 nftables

# Enforce a host allowlist as well as the Tailnet policy. Load it before
# tailscaled, so a reboot or a failed policy load cannot expose other services.
install -d -m 0750 /etc/orchard
curl --fail --silent --show-error --retry 5 -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/orchard-tailnet-firewall \
  --output /etc/orchard/tailnet-firewall.nft.new
nft --check --file /etc/orchard/tailnet-firewall.nft.new
mv /etc/orchard/tailnet-firewall.nft.new /etc/orchard/tailnet-firewall.nft
cat >/etc/systemd/system/orchard-tailnet-firewall.service <<'UNIT'
[Unit]
Description=Restrict Orchard Tailnet ingress to approved build hosts and operators
After=nftables.service
Before=tailscaled.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/nft --file /etc/orchard/tailnet-firewall.nft
ExecReload=/usr/sbin/nft --file /etc/orchard/tailnet-firewall.nft
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
install -d -m 0755 /etc/systemd/system/tailscaled.service.d
cat >/etc/systemd/system/tailscaled.service.d/orchard-firewall.conf <<'UNIT'
[Unit]
Requires=orchard-tailnet-firewall.service
After=orchard-tailnet-firewall.service
UNIT
systemctl daemon-reload
systemctl enable orchard-tailnet-firewall.service
systemctl reload-or-restart orchard-tailnet-firewall.service

# Enrollment is a separate admin-approved step; never put Tailscale auth keys
# in instance metadata. Existing node state persists on the boot disk.
install -d -m 0755 /usr/share/keyrings
curl --fail --silent --show-error --location --retry 5 \
  https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg \
  --output /usr/share/keyrings/tailscale-archive-keyring.gpg
curl --fail --silent --show-error --location --retry 5 \
  https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list \
  --output /etc/apt/sources.list.d/tailscale.list
chmod 0644 /usr/share/keyrings/tailscale-archive-keyring.gpg /etc/apt/sources.list.d/tailscale.list
apt-get update -qq
apt-get install -y --no-install-recommends "tailscale=$tailscale_version"
systemctl enable --now tailscaled

id orchard >/dev/null 2>&1 || useradd --system --home-dir "$data_mount" --shell /usr/sbin/nologin orchard
install -d -m 0750 -o orchard -g orchard "$data_mount"
test -b "$data_device"
filesystem=$(blkid -s TYPE -o value "$data_device" || true)
if [[ -z "$filesystem" ]]; then
  # Refuse to format any disk with an existing filesystem/partition signature.
  test -z "$(wipefs --noheadings --output TYPE "$data_device")"
  mkfs.ext4 -F -L orchard-data "$data_device"
elif [[ "$filesystem" != ext4 ]]; then
  echo 'Expected an ext4 Orchard data disk' >&2
  exit 1
fi
disk_uuid=$(blkid -s UUID -o value "$data_device")
if ! grep -q "^UUID=$disk_uuid " /etc/fstab; then
  printf 'UUID=%s %s ext4 defaults 0 2\n' "$disk_uuid" "$data_mount" >>/etc/fstab
fi
mountpoint -q "$data_mount" || mount "$data_mount"
chown orchard:orchard "$data_mount"

if ! test -x /usr/local/bin/orchard || ! printf '%s  %s\n' "$orchard_sha256" /usr/local/bin/orchard | sha256sum --check --status; then
  curl --fail --silent --show-error --location --retry 5 \
    "https://github.com/openai/orchard/releases/download/$orchard_version/orchard-linux-amd64" \
    --output /usr/local/bin/orchard.new
  printf '%s  %s\n' "$orchard_sha256" /usr/local/bin/orchard.new | sha256sum --check --status
  chmod 0755 /usr/local/bin/orchard.new
  mv /usr/local/bin/orchard.new /usr/local/bin/orchard
fi

cat >/usr/local/sbin/orchard-load-secrets <<'PYTHON'
#!/usr/bin/python3
import base64
import json
import os
from pathlib import Path
import pwd
import re
import sys
import tempfile
import urllib.request


def request(url, headers):
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=30) as response:
        return response.read()


def main():
    metadata = "http://metadata.google.internal/computeMetadata/v1/"
    headers = {"Metadata-Flavor": "Google"}
    project = request(metadata + "project/project-id", headers).decode()
    version = request(metadata + "instance/attributes/orchard-config-version", headers).decode()
    if not re.fullmatch(r"projects/" + re.escape(project) + r"/secrets/ORCHARD_CONTROLLER_CONFIG/versions/[0-9]+", version):
        raise ValueError("Invalid controller secret reference")
    identity = json.loads(request(metadata + "instance/service-accounts/default/token", headers))
    payload = json.loads(request("https://secretmanager.googleapis.com/v1/" + version + ":access", {
        "Authorization": "Bearer " + identity["access_token"],
    }))
    config = json.loads(base64.b64decode(payload["payload"]["data"], validate=True))
    if not re.fullmatch(r"[0-9a-f]{64}", config["bootstrap_token"]):
        raise ValueError("Invalid controller bootstrap token")
    user = pwd.getpwnam("orchard")
    directory = Path("/run/orchard")
    directory.mkdir(mode=0o750, exist_ok=True)
    directory.chmod(0o750)
    os.chown(directory, 0, user.pw_gid)
    values = {
        "controller.env": "ORCHARD_BOOTSTRAP_ADMIN_TOKEN=" + config["bootstrap_token"] + "\n",
        "controller.crt": config["certificate"],
        "controller.key": config["private_key"],
    }
    for filename, value in values.items():
        with tempfile.NamedTemporaryFile(mode="w", dir=directory, delete=False) as temporary:
            temporary.write(value)
            os.fchmod(temporary.fileno(), 0o440)
            os.fchown(temporary.fileno(), 0, user.pw_gid)
        os.replace(temporary.name, directory / filename)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Request/SDK exceptions can contain secret payloads or access tokens.
        print("Orchard secret initialization failed", file=sys.stderr)
        sys.exit(1)
PYTHON
chmod 0755 /usr/local/sbin/orchard-load-secrets

cat >/etc/systemd/system/orchard-secrets.service <<'UNIT'
[Unit]
Description=Load Orchard Controller credentials from Secret Manager
Wants=network-online.target
After=network-online.target
Before=orchard-controller.service
StartLimitIntervalSec=0

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/orchard-load-secrets
RemainAfterExit=yes
Restart=on-failure
RestartSec=10
UMask=0077

[Install]
WantedBy=multi-user.target
UNIT

cat >/etc/systemd/system/orchard-controller.service <<'UNIT'
[Unit]
Description=Orchard Controller
Wants=network-online.target orchard-secrets.service
After=network-online.target orchard-secrets.service
RequiresMountsFor=/var/lib/orchard
StartLimitIntervalSec=0

[Service]
User=orchard
Group=orchard
Environment=ORCHARD_HOME=/var/lib/orchard
Environment=GOMEMLIMIT=1GiB
EnvironmentFile=/run/orchard/controller.env
ExecStart=/usr/local/bin/orchard controller run --listen :443 --data-dir /var/lib/orchard/controller --controller-cert /run/orchard/controller.crt --controller-key /run/orchard/controller.key
Restart=always
RestartSec=5
TimeoutStopSec=60
UMask=0077
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/orchard
PrivateTmp=yes
ProtectKernelTunables=yes
ProtectControlGroups=yes
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable orchard-secrets.service orchard-controller.service
systemctl restart orchard-secrets.service
systemctl restart orchard-controller.service
