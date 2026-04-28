#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIREBASE_DIR="$ROOT_DIR/firebase"
DASHBOARD_DIR="$ROOT_DIR/apps/dashboard"
DART_DEFAULT="$DASHBOARD_DIR/lib/generated/dataconnect/default.dart"

echo "Generating Firebase Data Connect SDKs..."
(cd "$FIREBASE_DIR" && npx -y firebase-tools@latest dataconnect:sdk:generate)

echo "Patching generated Dart SDK for nullable BigInt serialization..."
python3 - "$DART_DEFAULT" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = """String bigIntToJson(BigInt value) {
  return value.toString();
}"""
new = """String? bigIntToJson(BigInt? value) {
  return value?.toString();
}"""

if new in text:
    print("bigIntToJson is already patched.")
elif old in text:
    path.write_text(text.replace(old, new, 1))
    print("Patched bigIntToJson.")
else:
    raise SystemExit(f"Could not find expected bigIntToJson implementation in {path}")
PY

(cd "$DASHBOARD_DIR" && dart format lib/generated/dataconnect/default.dart)

echo "Done."
