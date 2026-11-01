#!/usr/bin/env bash
set -euo pipefail
# Run inside the manifest's worker image, with this package mounted read-only.
work="$(mktemp -d)"
server_pid=
cleanup() {
  if [[ -n "$server_pid" ]]; then kill "$server_pid" 2>/dev/null || true; fi
  rm -rf "$work"
}
trap cleanup EXIT
export GCLOUD_PROJECT=demo-stacked-pr
export FUNCTION_TARGET=stacked-pr-worker
export PORT=8080
./bin/server >"$work/server.log" 2>&1 &
server_pid=$!
for attempt in {1..50}; do
  if curl --silent --fail http://127.0.0.1:8080/ -o /dev/null; then break; fi
  # A 405 is also a healthy response from this POST-only endpoint.
  status="$(curl --silent --output /dev/null --write-out '%{http_code}' http://127.0.0.1:8080/ || true)"
  if [[ "$status" == 405 ]]; then break; fi
  sleep 0.1
done
status="$(curl --silent --output /dev/null --write-out '%{http_code}' -H 'Content-Type: application/json' -d '{}' http://127.0.0.1:8080/)"
[[ "$status" == 400 ]]
# Verify the exact rebase flags required by the app using a disposable repository.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com
git init --quiet --initial-branch=main "$work/git"
cd "$work/git"
git commit --quiet --allow-empty -m base
base="$(git rev-parse HEAD)"
git checkout --quiet -b child
printf 'child\n' >child.txt
git add child.txt
git commit --quiet -m child
git checkout --quiet main
printf 'parent\n' >parent.txt
git add parent.txt
git commit --quiet -m parent
git checkout --quiet child
git rebase --no-autostash --no-update-refs --reapply-cherry-picks --empty=keep --onto main "$base"
[[ "$(git rev-parse HEAD^)" == "$(git rev-parse main)" ]]
printf 'Linux worker HTTP and Git rebase smoke checks passed\n'
