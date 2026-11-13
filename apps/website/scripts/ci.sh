#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
exec bash ../../openci/tool/with_node.sh npm exec --yes --package=npm@11.14.1 --call \
  'npm ci --workspace openci-website --workspace landing-page --include-workspace-root && npm run build:hosting'
