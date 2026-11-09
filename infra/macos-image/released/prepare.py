#!/usr/bin/env python3
"""Prepare checksum-verified installer inputs for the released macOS image."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent
lock = json.loads((root / "toolchain.json").read_text())
inputs = root.parent / "artifacts" / "release-0.1.7-inputs"

def digest(path):
    with path.open("rb") as f:
        h = hashlib.sha256()
        for chunk in iter(lambda: f.read(8 << 20), b""):
            h.update(chunk)
        return h.hexdigest()

def curl(url, *args, config=None):
    return subprocess.run(
        ["/usr/bin/curl", "--fail", "--silent", "--show-error", "--location",
         "--proto", "=https", "--proto-redir", "=https", "--retry", "3", *args, url],
        input=config, capture_output=True, check=True,
    ).stdout

def fetch(name, url, expected):
    path = inputs / name
    if path.exists() and digest(path) == expected:
        return
    with tempfile.NamedTemporaryFile(dir=inputs, delete=False) as tmp:
        temporary_path = Path(tmp.name)
    try:
        headers = []
        config = None
        if url.startswith("oci:"):
            repo = url[4:]
            auth = json.loads(curl(f"https://ghcr.io/token?service=ghcr.io&scope=repository:{repo}:pull"))
            config = ('header = "Authorization: Bearer ' + auth["token"] + '"\n').encode()
            headers = ["--config", "-"]
            url = f"https://ghcr.io/v2/{repo}/blobs/sha256:{expected}"
        curl(url, *headers, "--output", str(temporary_path), config=config)
        if digest(temporary_path) != expected:
            raise ValueError(f"Installer checksum mismatch: {name}")
        temporary_path.chmod(0o644)
        temporary_path.replace(path)
    finally:
        temporary_path.unlink(missing_ok=True)

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--local-foundation", action="store_true",
                    help="also verify the stopped local v0.1.0 input before building")
    args = ap.parse_args()
    inputs.mkdir(parents=True, exist_ok=True)
    if args.local_foundation:
        vms = json.loads(subprocess.check_output(["tart", "list", "--format", "json"]))
        if not any(vm["Name"] == "base-macos-release-v0.1.0" and vm["State"] == "stopped" for vm in vms):
            raise SystemExit("The original local v0.1.0 release must exist and be stopped")
        vm = Path(os.environ.get("TART_HOME", Path.home() / ".tart")) / "vms/base-macos-release-v0.1.0"
        if digest(vm / "disk.img") != lock["foundation_disk_sha256"]:
            raise SystemExit("Local v0.1.0 disk differs from the published foundation")
    for name, (url, expected) in lock["downloads"].items():
        fetch(name, url, expected)
    dmg = inputs / "iOS-26.5-23F73.dmg"
    if dmg.exists() and digest(dmg) != lock["runtime_dmg_sha256"]:
        raise SystemExit("iOS simulator installer checksum mismatch")
    print("Release inputs verified")
