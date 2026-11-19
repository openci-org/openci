#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
node_version=$(<.node-version)
if [[ $(node --version 2>/dev/null || true) != "v$node_version" ]]; then
  exec bash openci/tool/with_node.sh bash firebase/scripts/ci.sh
fi

node --version
npm_package=$(node -p 'require("./package.json").packageManager')
exec npm exec --yes --package="$npm_package" --call \
  'npm ci --workspace firebase --include-workspace-root &&
   npm run fmt:check --workspace firebase -- healthcheck.ts functions scripts &&
   npm run check --workspace firebase &&
   npm test --workspace firebase &&
   npm run test:workflow-context --workspace firebase'
