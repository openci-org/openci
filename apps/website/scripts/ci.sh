#!/usr/bin/env bash
set -euo pipefail

website_dir="$(cd "$(dirname "$0")/.." && pwd)"
node_version="$(cat "$website_dir/../../.node-version")"
case "$(uname -s)" in
  Darwin) node_platform=darwin ;;
  Linux) node_platform=linux ;;
  *) printf '%s\n' 'Website CI requires macOS or Linux.' >&2; exit 1 ;;
esac
case "$(uname -m)" in
  arm64|aarch64) node_arch=arm64 ;;
  x86_64) node_arch=x64 ;;
  *) printf '%s\n' 'Unsupported Node.js architecture.' >&2; exit 1 ;;
esac

# CI VMs have Dart/Flutter but may not have Node.js or npm installed.
node_tmp="$(mktemp -d "${TMPDIR:-/tmp}/genuineci-website-node.XXXXXX")"
trap 'rm -rf "$node_tmp"' EXIT
node_archive="node-v$node_version-$node_platform-$node_arch"
node_origin="https://nodejs.org/dist/v$node_version"
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
export PATH="$node_tmp/$node_archive/bin:$PATH"
node --version

cd "$website_dir"
npm exec --yes --package=npm@11.14.1 --call \
  'npm ci --workspace genuineci-website --include-workspace-root && npm run verify'
