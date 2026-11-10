#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
node_version=$(<.node-version)
if [[ $(node --version 2>/dev/null) != "v$node_version" ]]; then
  node_dir=$(mise where "node@$node_version")
  export PATH="$node_dir/bin:$PATH"
fi

node --version
npm_package=$(node -p 'require("./package.json").packageManager')
exec npm exec --yes --package="$npm_package" --call \
  'npm ci --workspace firebase --include-workspace-root &&
   npm run fmt:check --workspace firebase -- healthcheck.ts functions &&
   npm run check --workspace firebase &&
   npm test --workspace firebase'
