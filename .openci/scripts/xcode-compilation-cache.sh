#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <restore|save|report>" >&2
}

if [ "$#" -ne 1 ]; then
  usage
  exit 2
fi

action="$1"

case "$action" in
  restore|save|report) ;;
  *)
    usage
    exit 2
    ;;
esac

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cache_dir="${XCODE_COMPILATION_CACHE_DIR:-${HOME}/Library/Developer/Xcode/DerivedData/CompilationCache.noindex}"

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

cache_key_hash() {
  python3 - "$1" <<'PY'
import hashlib
import sys

print(hashlib.sha256(sys.argv[1].encode()).hexdigest())
PY
}

sha256_digest() {
  python3 - "$1" <<'PY'
import hashlib
import sys

digest = hashlib.sha256()
with open(sys.argv[1], "rb") as f:
    for chunk in iter(lambda: f.read(1024 * 1024), b""):
        digest.update(chunk)
print(digest.hexdigest())
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
  local cache_parent
  local cache_name

  cache_parent="$(dirname "$cache_dir")"
  cache_name="$(basename "$cache_dir")"

  if command -v zstd >/dev/null 2>&1; then
    tar -cf - -C "$cache_parent" "$cache_name" \
      | zstd -T0 -1 -q -o "$archive_path"
  else
    tar -czf "$archive_path" -C "$cache_parent" "$cache_name"
  fi
}

extract_archive() {
  local archive_path="$1"

  rm -rf "$cache_dir"
  mkdir -p "$(dirname "$cache_dir")"
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
  local platform="$1"
  local input_file="$tmp_dir/dependency-hash-input.txt"
  local file
  local files=(
    "pubspec.yaml"
    "pubspec.lock"
    "apps/dashboard/pubspec.yaml"
    "packages/macos_updater/pubspec.yaml"
    "packages/macos_updater/example/pubspec.yaml"
    "packages/macos_updater/example/pubspec.lock"
  )

  case "$platform" in
    ios)
      files+=(
        "apps/dashboard/ios/Podfile"
        "apps/dashboard/ios/Podfile.lock"
        "apps/dashboard/ios/Runner.xcodeproj/project.pbxproj"
        "apps/dashboard/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        "apps/dashboard/ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"
      )
      ;;
    macos)
      files+=(
        "apps/dashboard/macos/Podfile"
        "apps/dashboard/macos/Podfile.lock"
        "apps/dashboard/macos/Runner.xcodeproj/project.pbxproj"
        "apps/dashboard/macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        "apps/dashboard/macos/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        "packages/macos_updater/example/macos/Runner.xcodeproj/project.pbxproj"
      )
      ;;
  esac

  : > "$input_file"
  for file in "${files[@]}"; do
    if [ -f "$file" ]; then
      printf '%s\n' "$file" >> "$input_file"
      printf '%s  %s\n' "$(sha256_digest "$file")" "$file" >> "$input_file"
    fi
  done

  sha256_digest "$input_file" | cut -c 1-20
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
        data.get("dartSdkVersion"),
    ]
    if part
)
print(re.sub(r"[^a-zA-Z0-9._-]+", "-", value or "unknown-flutter").strip("-").lower())
PY
  else
    echo "unknown-flutter"
  fi
}

host_cache_key_component() {
  sanitize_component "$(uname -s)-$(uname -m)"
}

platform_cache_key_component() {
  sanitize_component "${OPENCI_XCODE_CACHE_PLATFORM:-all}"
}

xcode_cache_key_component() {
  if command -v xcodebuild >/dev/null 2>&1; then
    sanitize_component "$(xcodebuild -version | tr '\n' '-')"
  else
    echo "unknown-xcode"
  fi
}

sdk_cache_key_component() {
  local platform="$1"
  local sdk

  case "$platform" in
    ios) sdk="iphoneos" ;;
    macos) sdk="macosx" ;;
    *) sdk="" ;;
  esac

  if [ -n "$sdk" ] && command -v xcrun >/dev/null 2>&1; then
    sanitize_component "${sdk}-$(xcrun --sdk "$sdk" --show-sdk-version 2>/dev/null || echo unknown-sdk)"
  else
    echo "unknown-sdk"
  fi
}

cache_object_name() {
  local repo
  local platform_component
  local host_component
  local xcode_component
  local sdk_component
  local flutter_component
  local deps_component
  local archive_extension

  repo="${GITHUB_REPOSITORY:-openci-org/openci}"
  platform_component="$(platform_cache_key_component)"
  host_component="$(host_cache_key_component)"
  xcode_component="$(xcode_cache_key_component)"
  sdk_component="$(sdk_cache_key_component "$platform_component")"
  flutter_component="$(flutter_cache_key_component)"
  deps_component="$(dependency_hash "$platform_component")"
  archive_extension="$(compression_extension)"

  printf 'caches/xcode-compilation/%s/apps-dashboard/%s/%s/%s/%s/%s/deps-%s.%s' \
    "$repo" \
    "$platform_component" \
    "$host_component" \
    "$xcode_component" \
    "$sdk_component" \
    "$flutter_component" \
    "$deps_component" \
    "$archive_extension"
}

object_exists() {
  local bucket="$1"
  local token="$2"
  local object_name="$3"
  local encoded_object_name
  local response_path="$tmp_dir/object-metadata.json"
  local http_code

  encoded_object_name="$(urlencode "$object_name")"
  if ! http_code="$(curl -sS -w '%{http_code}' -o "$response_path" \
    -H "Authorization: Bearer ${token}" \
    "https://storage.googleapis.com/storage/v1/b/${bucket}/o/${encoded_object_name}?fields=name,size,updated")"; then
    echo "Failed to inspect Xcode compilation cache object" >&2
    cat "$response_path" >&2 || true
    return 2
  fi

  if [ "$http_code" = "404" ]; then
    return 1
  fi

  case "$http_code" in
    ''|*[!0-9]*)
      echo "Failed to inspect Xcode compilation cache object (HTTP ${http_code:-unknown})" >&2
      cat "$response_path" >&2 || true
      return 2
      ;;
  esac

  if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
    echo "Failed to inspect Xcode compilation cache object (HTTP ${http_code})" >&2
    cat "$response_path" >&2 || true
    return 2
  fi

  return 0
}

local_cache_root() {
  if [ -z "${OPENCI_XCODE_LOCAL_CACHE_DIR:-}" ]; then
    return 1
  fi
  if [ ! -d "$OPENCI_XCODE_LOCAL_CACHE_DIR" ]; then
    return 1
  fi
  printf '%s' "$OPENCI_XCODE_LOCAL_CACHE_DIR"
}

local_cache_archive_path() {
  local object_name="$1"
  local root
  local key_hash

  root="$(local_cache_root)" || return 1
  key_hash="$(cache_key_hash "$object_name")"
  printf '%s/archives/%s.%s' "$root" "$key_hash" "$(compression_extension)"
}

local_cache_metadata_path() {
  local object_name="$1"
  local root
  local key_hash

  root="$(local_cache_root)" || return 1
  key_hash="$(cache_key_hash "$object_name")"
  printf '%s/metadata/%s.json' "$root" "$key_hash"
}

update_local_cache_metadata() {
  local object_name="$1"
  local archive_path="$2"
  local event="$3"
  local metadata_path

  metadata_path="$(local_cache_metadata_path "$object_name")" || return 0
  mkdir -p "$(dirname "$metadata_path")"
  python3 - "$object_name" "$archive_path" "$metadata_path" "$event" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

object_name, archive_path, metadata_path, event = sys.argv[1:]
now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
try:
    with open(metadata_path, encoding="utf-8") as f:
        metadata = json.load(f)
except Exception:
    metadata = {}

metadata.setdefault("createdAt", now)
metadata["objectName"] = object_name
metadata["archivePath"] = archive_path
metadata["size"] = os.path.getsize(archive_path)
metadata["lastAccessedAt"] = now
metadata["lastEvent"] = event
metadata["hitCount"] = int(metadata.get("hitCount") or 0) + (1 if event == "restore-hit" else 0)

tmp_path = f"{metadata_path}.tmp"
with open(tmp_path, "w", encoding="utf-8") as f:
    json.dump(metadata, f, separators=(",", ":"))
os.replace(tmp_path, metadata_path)
PY
}

prune_local_cache() {
  local root
  local max_bytes="${OPENCI_XCODE_LOCAL_CACHE_MAX_BYTES:-21474836480}"

  root="$(local_cache_root)" || return 0
  python3 - "$root" "$max_bytes" <<'PY'
import json
import os
import sys
from datetime import datetime

root, max_bytes_text = sys.argv[1:]
try:
    max_bytes = int(max_bytes_text)
except ValueError:
    max_bytes = 21474836480

archives_dir = os.path.join(root, "archives")
metadata_dir = os.path.join(root, "metadata")
if max_bytes <= 0 or not os.path.isdir(archives_dir):
    raise SystemExit(0)

entries = []
for name in os.listdir(archives_dir):
    archive_path = os.path.join(archives_dir, name)
    if not os.path.isfile(archive_path):
        continue
    key = name
    for suffix in (".tar.zst", ".tar.gz"):
        if key.endswith(suffix):
            key = key[: -len(suffix)]
            break
    metadata_path = os.path.join(metadata_dir, f"{key}.json")
    last_accessed = os.path.getmtime(archive_path)
    if os.path.isfile(metadata_path):
        try:
            with open(metadata_path, encoding="utf-8") as f:
                value = json.load(f).get("lastAccessedAt")
            if isinstance(value, str):
                last_accessed = datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
        except Exception:
            pass
    try:
        size = os.path.getsize(archive_path)
    except OSError:
        continue
    entries.append((last_accessed, archive_path, metadata_path, size))

total = sum(entry[3] for entry in entries)
for _, archive_path, metadata_path, size in sorted(entries):
    if total <= max_bytes:
        break
    try:
        os.remove(archive_path)
        total -= size
    except FileNotFoundError:
        total -= size
    except OSError:
        continue
    try:
        os.remove(metadata_path)
    except FileNotFoundError:
        pass
PY
}

store_local_archive() {
  local object_name="$1"
  local archive_path="$2"
  local event="$3"
  local local_archive_path
  local tmp_archive_path

  local_archive_path="$(local_cache_archive_path "$object_name")" || return 0
  mkdir -p "$(dirname "$local_archive_path")"
  if [ -f "$local_archive_path" ]; then
    update_local_cache_metadata "$object_name" "$local_archive_path" "$event"
    return 0
  fi

  tmp_archive_path="${local_archive_path}.tmp.$$"
  cp "$archive_path" "$tmp_archive_path"
  mv "$tmp_archive_path" "$local_archive_path"
  update_local_cache_metadata "$object_name" "$local_archive_path" "$event"
  prune_local_cache
}

restore_local_cache() {
  local object_name="$1"
  local local_archive_path
  local local_metadata_path

  local_archive_path="$(local_cache_archive_path "$object_name")" || return 1
  if [ ! -f "$local_archive_path" ]; then
    echo "Xcode compilation local cache miss"
    return 1
  fi

  echo "Restoring Xcode compilation cache from local archive: $local_archive_path"
  du -sh "$local_archive_path"
  if ! extract_archive "$local_archive_path"; then
    echo "Xcode compilation local cache restore failed; falling back to remote cache" >&2
    local_metadata_path="$(local_cache_metadata_path "$object_name")" || local_metadata_path=""
    rm -f "$local_archive_path"
    if [ -n "$local_metadata_path" ]; then
      rm -f "$local_metadata_path"
    fi
    return 1
  fi
  update_local_cache_metadata "$object_name" "$local_archive_path" "restore-hit"

  echo "Restored Xcode compilation cache:"
  du -sh "$cache_dir"
  find "$cache_dir" -type f | wc -l | awk '{ print "File count: " $1 }'
}

save_local_cache() {
  local object_name="$1"
  local archive_path
  local local_archive_path

  local_archive_path="$(local_cache_archive_path "$object_name")" || return 0
  if [ -f "$local_archive_path" ]; then
    echo "Xcode compilation local cache already exists; skipping local save: $local_archive_path"
    update_local_cache_metadata "$object_name" "$local_archive_path" "save-skip"
    return 0
  fi

  if [ ! -d "$cache_dir" ]; then
    echo "Xcode compilation cache not found; nothing to save locally: $cache_dir"
    return 0
  fi

  archive_path="$tmp_dir/xcode-compilation-cache-local.$(compression_extension)"
  echo "Creating Xcode compilation local cache archive:"
  du -sh "$cache_dir"
  create_archive "$archive_path"
  du -sh "$archive_path"
  store_local_archive "$object_name" "$archive_path" "save"
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

  if ! store_local_archive "$object_name" "$archive_path" "remote-seed"; then
    echo "Warning: failed to seed local Xcode compilation cache" >&2
  fi

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
  local exists_status
  local local_archive_path
  local local_exists="false"
  local remote_exists="false"

  if object_exists "$bucket" "$token" "$object_name"; then
    remote_exists="true"
  else
    exists_status="$?"
    if [ "$exists_status" -ne 1 ]; then
      return 1
    fi
  fi

  if local_archive_path="$(local_cache_archive_path "$object_name")" && [ -f "$local_archive_path" ]; then
    local_exists="true"
  fi

  if [ "$remote_exists" = "true" ] && [ "$local_exists" = "true" ]; then
    echo "Xcode compilation cache already exists locally and remotely; skipping save"
    update_local_cache_metadata "$object_name" "$local_archive_path" "save-skip"
    return 0
  fi

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

  if [ "$local_exists" = "false" ]; then
    store_local_archive "$object_name" "$archive_path" "save"
  else
    echo "Xcode compilation local cache already exists; skipping local save: $local_archive_path"
  fi

  if [ "$remote_exists" = "true" ]; then
    echo "Xcode compilation cache already exists; skipping upload: gs://${bucket}/${object_name}"
    return 0
  fi

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

report_cache() {
  local object_name="$1"

  echo "Xcode compilation cache key: ${object_name}"
  if [ ! -d "$cache_dir" ]; then
    echo "Xcode compilation cache not found: $cache_dir"
    return 0
  fi

  echo "Xcode compilation cache:"
  du -sh "$cache_dir"
  find "$cache_dir" -type f | wc -l | awk '{ print "File count: " $1 }'
}

object_name="$(cache_object_name)"

if [ "$action" = "report" ]; then
  report_cache "$object_name"
  exit 0
fi

if [ "$action" = "restore" ] && restore_local_cache "$object_name"; then
  exit 0
fi

if [ -z "${FIREBASE_SERVICE_ACCOUNT:-}" ]; then
  if [ "$action" = "save" ]; then
    save_local_cache "$object_name"
    exit 0
  fi
  echo "FIREBASE_SERVICE_ACCOUNT is not set; skipping remote Xcode compilation cache ${action}"
  exit 0
fi

bucket="$(storage_bucket)"
if [ -z "$bucket" ]; then
  echo "Could not read storageBucket from firebase_options.dart" >&2
  exit 1
fi

token="$(access_token)"

case "$action" in
  restore)
    restore_cache "$bucket" "$token" "$object_name"
    ;;
  save)
    save_cache "$bucket" "$token" "$object_name"
    ;;
esac
