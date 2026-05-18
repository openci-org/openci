#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <restore|save> <ios|macos>" >&2
}

if [ "$#" -ne 2 ]; then
  usage
  exit 2
fi

action="$1"
platform="$2"

case "$action" in
  restore|save) ;;
  *)
    usage
    exit 2
    ;;
esac

case "$platform" in
  ios|macos) ;;
  *)
    usage
    exit 2
    ;;
esac

if [ -z "${FIREBASE_SERVICE_ACCOUNT:-}" ]; then
  echo "FIREBASE_SERVICE_ACCOUNT is not set; skipping Xcode compilation cache ${action}"
  exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cache_dir="${HOME}/Library/Developer/Xcode/DerivedData/CompilationCache.noindex"

sanitize_component() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

storage_bucket() {
  sed -n "s/.*storageBucket: '\([^']*\)'.*/\1/p" apps/dashboard/lib/firebase_options.dart | head -n 1
}

urlencode() {
  python3 - "$1" <<'PY'
import sys
import urllib.parse

print(urllib.parse.quote(sys.argv[1], safe=""))
PY
}

json_object_metadata() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

print(json.dumps({"name": sys.argv[1], "contentType": sys.argv[2]}, separators=(",", ":")))
PY
}

file_size() {
  python3 - "$1" <<'PY'
import os
import sys

print(os.path.getsize(sys.argv[1]))
PY
}

compression_extension() {
  if command -v zstd >/dev/null 2>&1; then
    echo "tar.zst"
  else
    echo "tar.gz"
  fi
}

compression_content_type() {
  if command -v zstd >/dev/null 2>&1; then
    echo "application/zstd"
  else
    echo "application/gzip"
  fi
}

create_archive() {
  local archive_path="$1"

  if command -v zstd >/dev/null 2>&1; then
    tar -cf - -C "$(dirname "$cache_dir")" "$(basename "$cache_dir")" | zstd -T0 -1 -q -o "$archive_path"
  else
    tar -czf "$archive_path" -C "$(dirname "$cache_dir")" "$(basename "$cache_dir")"
  fi
}

extract_archive() {
  local archive_path="$1"

  if [ "${archive_path##*.}" = "zst" ]; then
    zstd -dc "$archive_path" | tar -xf - -C "$(dirname "$cache_dir")"
  else
    tar -xzf "$archive_path" -C "$(dirname "$cache_dir")"
  fi
}

access_token() {
  local service_account_file="$tmp_dir/firebase-service-account.json"
  local private_key_file="$tmp_dir/private-key.pem"
  local signing_input_file="$tmp_dir/signing-input.txt"
  local client_email
  local jwt_header
  local jwt_payload
  local jwt_signature
  local jwt_assertion

  printf '%s' "$FIREBASE_SERVICE_ACCOUNT" > "$service_account_file"
  client_email="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["client_email"])' "$service_account_file")"
  python3 -c 'import json, sys; open(sys.argv[2], "w").write(json.load(open(sys.argv[1]))["private_key"])' "$service_account_file" "$private_key_file"

  jwt_header="$(python3 -c 'import base64, json; print(base64.urlsafe_b64encode(json.dumps({"alg":"RS256","typ":"JWT"}, separators=(",", ":")).encode()).decode().rstrip("="))')"
  jwt_payload="$(python3 - "$client_email" <<'PY'
import base64
import json
import sys
import time

now = int(time.time())
payload = {
    "iss": sys.argv[1],
    "scope": "https://www.googleapis.com/auth/devstorage.full_control",
    "aud": "https://oauth2.googleapis.com/token",
    "iat": now,
    "exp": now + 3600,
}
print(base64.urlsafe_b64encode(json.dumps(payload, separators=(",", ":")).encode()).decode().rstrip("="))
PY
  )"
  printf '%s.%s' "$jwt_header" "$jwt_payload" > "$signing_input_file"
  jwt_signature="$(openssl dgst -sha256 -sign "$private_key_file" "$signing_input_file" | python3 -c 'import base64, sys; print(base64.urlsafe_b64encode(sys.stdin.buffer.read()).decode().rstrip("="))')"
  jwt_assertion="${jwt_header}.${jwt_payload}.${jwt_signature}"

  curl -fsS -X POST "https://oauth2.googleapis.com/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
    --data-urlencode "assertion=${jwt_assertion}" \
    | python3 -c 'import json, sys; print(json.load(sys.stdin)["access_token"])'
}

dependency_hash() {
  local input_file="$tmp_dir/dependency-hash-input.txt"
  local file
  : > "$input_file"

  for file in \
    "apps/dashboard/pubspec.lock" \
    "apps/dashboard/${platform}/Podfile.lock" \
    "apps/dashboard/${platform}/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved" \
    "apps/dashboard/${platform}/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"; do
    if [ -f "$file" ]; then
      printf '%s\n' "$file" >> "$input_file"
      shasum -a 256 "$file" >> "$input_file"
    fi
  done

  shasum -a 256 "$input_file" | awk '{ print substr($1, 1, 20) }'
}

xcode_cache_key_component() {
  local version
  version="$(xcodebuild -version 2>/dev/null | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/[[:space:]]+$//')"
  sanitize_component "${version:-unknown-xcode}"
}

flutter_cache_key_component() {
  local version_file="$tmp_dir/flutter-version.json"
  if flutter --version --machine > "$version_file" 2>/dev/null; then
    python3 - "$version_file" <<'PY'
import json
import re
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
value = "-".join(
    part
    for part in [
        data.get("frameworkVersion"),
        (data.get("frameworkRevision") or "")[:12],
    ]
    if part
)
print(re.sub(r"[^a-zA-Z0-9._-]+", "-", value or "unknown-flutter").strip("-").lower())
PY
  else
    echo "unknown-flutter"
  fi
}

cache_object_name() {
  local repo
  local xcode_component
  local flutter_component
  local deps_component
  local archive_extension

  repo="${GITHUB_REPOSITORY:-openci-org/openci}"
  xcode_component="$(xcode_cache_key_component)"
  flutter_component="$(flutter_cache_key_component)"
  deps_component="$(dependency_hash)"
  archive_extension="$(compression_extension)"

  printf 'caches/xcode-compilation/%s/apps-dashboard/%s/%s/%s/deps-%s.%s' \
    "$repo" \
    "$platform" \
    "$xcode_component" \
    "$flutter_component" \
    "$deps_component" \
    "$archive_extension"
}

restore_cache() {
  local bucket="$1"
  local token="$2"
  local object_name="$3"
  local encoded_object_name
  local archive_path
  local http_code

  archive_path="$tmp_dir/xcode-compilation-cache.$(compression_extension)"
  encoded_object_name="$(urlencode "$object_name")"
  echo "Restoring Xcode compilation cache from gs://${bucket}/${object_name}"

  http_code="$(curl -sS -L -w '%{http_code}' -o "$archive_path" \
    -H "Authorization: Bearer ${token}" \
    "https://storage.googleapis.com/storage/v1/b/${bucket}/o/${encoded_object_name}?alt=media")"

  if [ "$http_code" = "404" ]; then
    echo "Xcode compilation cache miss"
    return 0
  fi

  if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
    echo "Failed to download Xcode compilation cache (HTTP ${http_code})" >&2
    cat "$archive_path" >&2 || true
    return 1
  fi

  echo "Downloaded Xcode compilation cache archive:"
  du -sh "$archive_path"

  rm -rf "$cache_dir"
  mkdir -p "$(dirname "$cache_dir")"
  extract_archive "$archive_path"

  echo "Restored Xcode compilation cache:"
  du -sh "$cache_dir"
  find "$cache_dir" -type f | wc -l | awk '{ print "File count: " $1 }'
}

save_cache() {
  local bucket="$1"
  local token="$2"
  local object_name="$3"
  local archive_path
  local archive_size
  local content_type
  local headers_file="$tmp_dir/upload-headers.txt"
  local upload_url

  archive_path="$tmp_dir/xcode-compilation-cache.$(compression_extension)"
  if [ ! -d "$cache_dir" ]; then
    echo "Xcode compilation cache not found; nothing to save: $cache_dir"
    return 0
  fi

  echo "Creating Xcode compilation cache archive:"
  du -sh "$cache_dir"
  create_archive "$archive_path"
  du -sh "$archive_path"
  archive_size="$(file_size "$archive_path")"
  content_type="$(compression_content_type)"

  echo "Uploading Xcode compilation cache to gs://${bucket}/${object_name}"
  curl -fsS -X POST \
    -D "$headers_file" \
    -o /dev/null \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json; charset=UTF-8" \
    -H "X-Upload-Content-Type: ${content_type}" \
    -H "X-Upload-Content-Length: ${archive_size}" \
    --data "$(json_object_metadata "$object_name" "$content_type")" \
    "https://storage.googleapis.com/upload/storage/v1/b/${bucket}/o?uploadType=resumable"

  upload_url="$(python3 - "$headers_file" <<'PY'
import sys

with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
    for line in f:
        if line.lower().startswith("location:"):
            print(line.split(":", 1)[1].strip())
PY
  )"

  if [ -z "$upload_url" ]; then
    echo "Could not read resumable upload URL" >&2
    cat "$headers_file" >&2 || true
    return 1
  fi

  curl -fsS -X PUT \
    -H "Content-Type: ${content_type}" \
    --data-binary "@${archive_path}" \
    "$upload_url" \
    > /dev/null

  echo "Uploaded Xcode compilation cache"
}

bucket="$(storage_bucket)"
if [ -z "$bucket" ]; then
  echo "Could not read storageBucket from firebase_options.dart" >&2
  exit 1
fi

object_name="$(cache_object_name)"
token="$(access_token)"

case "$action" in
  restore)
    restore_cache "$bucket" "$token" "$object_name"
    ;;
  save)
    save_cache "$bucket" "$token" "$object_name"
    ;;
esac
