#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DASHBOARD_DIR="$(dirname "$SCRIPT_DIR")"
FIREBASE_DIR="$DASHBOARD_DIR/../../firebase/openci"

rm -rf "$FIREBASE_DIR/public"
cp -r "$DASHBOARD_DIR/build/web" "$FIREBASE_DIR/public"

cd "$FIREBASE_DIR"
firebase use prod
firebase deploy --only hosting
firebase use default
