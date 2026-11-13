#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
node_version="$(cat "$repo_dir/.node-version")"
if [[ "$(node --version 2>/dev/null || true)" == "v$node_version" ]]; then
  exec "$@"
fi

case "$(uname -s)" in
  Darwin) node_platform=darwin ;;
  Linux) node_platform=linux ;;
  *) printf '%s\n' 'OpenCI requires macOS or Linux for Node.js.' >&2; exit 1 ;;
esac
case "$(uname -m)" in
  arm64|aarch64) node_arch=arm64 ;;
  x86_64) node_arch=x64 ;;
  *) printf '%s\n' 'Unsupported Node.js architecture.' >&2; exit 1 ;;
esac

node_tmp="$(mktemp -d "${TMPDIR:-/tmp}/openci-node.XXXXXX")"
trap 'rm -rf "$node_tmp"' EXIT
node_archive="node-v$node_version-$node_platform-$node_arch"
node_origin="https://nodejs.org/dist/v$node_version"
(
  cd "$node_tmp"
  curl --fail --silent --show-error --location --retry 3 \
    --output "$node_archive.tar.gz" "$node_origin/$node_archive.tar.gz"
  curl --fail --silent --show-error --location --retry 3 \
    --output SHASUMS256.txt "$node_origin/SHASUMS256.txt"
  awk -v archive="$node_archive.tar.gz" '$2 == archive { print }' \
    SHASUMS256.txt > node-checksum.txt
  test -s node-checksum.txt
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum --check node-checksum.txt
  else
    shasum -a 256 --check node-checksum.txt
  fi
  tar -xzf "$node_archive.tar.gz"
)
export PATH="$node_tmp/$node_archive/bin:$PATH"
"$@"
