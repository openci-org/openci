#!/bin/sh
set -eu
umask 077
mkdir -p "${DATA_DIR:-/data}"
exec flock --no-fork --nonblock "${DATA_DIR:-/data}/worker.lock" "$@"
