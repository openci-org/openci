#!/usr/bin/env bash
set -euo pipefail

derived_data_dir="${OPENCI_XCODE_DERIVED_DATA_DIR:-${HOME}/Library/Developer/Xcode/DerivedData}"
compilation_cache_dir="${XCODE_COMPILATION_CACHE_DIR:-${derived_data_dir}/CompilationCache.noindex}"
lookback_minutes="${OPENCI_XCODE_BUILD_LOG_LOOKBACK_MINUTES:-180}"
log_limit="${OPENCI_XCODE_BUILD_LOG_LIMIT:-3}"
platform="${OPENCI_XCODE_BUILD_LOG_PLATFORM:-unknown}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "Xcode build log summary"
echo "Platform: ${platform}"
echo "DerivedData: ${derived_data_dir}"
echo "Lookback minutes: ${lookback_minutes}"
echo "Log limit: ${log_limit}"

if [ -d "$compilation_cache_dir" ]; then
  echo "Compilation cache:"
  du -sh "$compilation_cache_dir" 2>/dev/null || true
  find "$compilation_cache_dir" -type f 2>/dev/null | wc -l | awk '{ print "  File count: " $1 }'
else
  echo "Compilation cache: not found at ${compilation_cache_dir}"
fi

if [ ! -d "$derived_data_dir" ]; then
  echo "No DerivedData directory found"
  exit 0
fi

mapfile_path="$tmp_dir/xcode-build-logs.txt"
python3 - "$derived_data_dir" "$lookback_minutes" "$log_limit" > "$mapfile_path" <<'PY'
import os
import sys
import time

root = sys.argv[1]
try:
    lookback_minutes = int(sys.argv[2])
except ValueError:
    lookback_minutes = 180
try:
    limit = max(1, int(sys.argv[3]))
except ValueError:
    limit = 3

logs = []
root_normalized = os.path.abspath(root).replace(os.sep, "/")
for dirpath, dirnames, filenames in os.walk(root):
    normalized = os.path.abspath(dirpath).replace(os.sep, "/")
    if "/Logs/Build" not in normalized:
        if normalized == root_normalized:
            dirnames[:] = [name for name in dirnames if name != "CompilationCache.noindex"]
        elif normalized.endswith("/Logs"):
            dirnames[:] = [name for name in dirnames if name == "Build"]
        elif not normalized.endswith("/Logs/Build"):
            dirnames[:] = [name for name in dirnames if name == "Logs"]
        continue
    for filename in filenames:
        if not filename.endswith(".xcactivitylog"):
            continue
        path = os.path.join(dirpath, filename)
        try:
            logs.append((os.path.getmtime(path), path))
        except OSError:
            pass

if not logs:
    sys.exit(0)

logs.sort(reverse=True)
cutoff = time.time() - (lookback_minutes * 60)
recent_logs = [(mtime, path) for mtime, path in logs if mtime >= cutoff]
selected_logs = recent_logs[:limit] if recent_logs else logs[:limit]

for mtime, path in selected_logs:
    is_recent = "recent" if mtime >= cutoff else "fallback-old"
    print(f"{is_recent}\t{mtime:.0f}\t{path}")
PY

if [ ! -s "$mapfile_path" ]; then
  echo "No .xcactivitylog files found"
  exit 0
fi

extract_strings() {
  local log_path="$1"
  local raw_path="$2"
  local text_path="$3"

  if gzip -dc "$log_path" > "$raw_path" 2>/dev/null; then
    if ! LC_ALL=C strings -a "$raw_path" > "$text_path" 2>/dev/null; then
      LC_ALL=C strings "$raw_path" > "$text_path" 2>/dev/null || true
    fi
  else
    if ! LC_ALL=C strings -a "$log_path" > "$text_path" 2>/dev/null; then
      LC_ALL=C strings "$log_path" > "$text_path" 2>/dev/null || true
    fi
  fi
}

count_fixed() {
  local pattern="$1"
  local text_path="$2"
  awk -v pattern="$pattern" '
    {
      line = $0
      while ((position = index(line, pattern)) > 0) {
        count++
        line = substr(line, position + length(pattern))
      }
    }
    END { print count + 0 }
  ' "$text_path"
}

print_top_targets() {
  local text_path="$1"
  python3 - "$text_path" <<'PY'
import collections
import re
import sys

path = sys.argv[1]
patterns = [
    re.compile(r"in target '([^']+)'"),
    re.compile(r"target '([^']+)'"),
    re.compile(r"Target '([^']+)'"),
]
counts = collections.Counter()
with open(path, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        for pattern in patterns:
            for match in pattern.findall(line):
                value = match.strip()
                if value:
                    counts[value] += 1

if not counts:
    print("  none")
else:
    for target, count in counts.most_common(20):
        print(f"  {count:5d}  {target}")
PY
}

print_matching_lines() {
  local text_path="$1"
  local limit="$2"
  shift 2

  python3 - "$text_path" "$limit" "$@" <<'PY'
import sys

path = sys.argv[1]
limit = int(sys.argv[2])
needles = sys.argv[3:]
printed = 0

with open(path, "r", encoding="utf-8", errors="ignore") as f:
    for raw_line in f:
        line = " ".join(raw_line.strip().split())
        if not line:
            continue
        if any(needle in line for needle in needles):
            print(f"  {line[:240]}")
            printed += 1
            if printed >= limit:
                break

if printed == 0:
    print("  none")
PY
}

operation_patterns=(
  "SwiftDriver Compilation"
  "CompileSwiftSources"
  "CompileSwift "
  "CompileC "
  "CompileAssetCatalog"
  "Ld "
  "PhaseScriptExecution"
  "ProcessInfoPlistFile"
  "CodeSign "
  "CopySwiftLibs"
  "GenerateDSYMFile"
  "CompileStoryboard"
  "CompileXIB"
)

while IFS=$'\t' read -r recency mtime log_path; do
  raw_path="$tmp_dir/$(basename "$log_path").raw"
  text_path="$tmp_dir/$(basename "$log_path").strings"
  modified_at="$(python3 - "$mtime" <<'PY'
import datetime
import sys

print(datetime.datetime.fromtimestamp(float(sys.argv[1])).isoformat(timespec="seconds"))
PY
  )"

  echo ""
  echo "Build log (${recency}): ${log_path}"
  echo "Modified: ${modified_at}"
  du -sh "$log_path" 2>/dev/null || true

  extract_strings "$log_path" "$raw_path" "$text_path"
  if [ ! -s "$text_path" ]; then
    echo "Could not extract readable strings from build log"
    continue
  fi

  echo "Diagnostics:"
  warning_count="$(awk '
    {
      line = tolower($0)
      while ((position = index(line, "warning:")) > 0) {
        count++
        line = substr(line, position + length("warning:"))
      }
    }
    END { print count + 0 }
  ' "$text_path")"
  error_count="$(awk '
    {
      line = tolower($0)
      while ((position = index(line, "error:")) > 0) {
        count++
        line = substr(line, position + length("error:"))
      }
    }
    END { print count + 0 }
  ' "$text_path")"
  echo "  Warnings: ${warning_count}"
  echo "  Errors: ${error_count}"

  echo "Operation counts:"
  for pattern in "${operation_patterns[@]}"; do
    count="$(count_fixed "$pattern" "$text_path")"
    printf '  %-28s %s\n' "$pattern" "$count"
  done

  echo "Top target mentions:"
  print_top_targets "$text_path"

  echo "CompilationCacheMetrics:"
  print_matching_lines "$text_path" 20 "CompilationCacheMetrics"

  echo "Compilation cache references:"
  print_matching_lines "$text_path" 20 "CompilationCache"

  echo "Representative expensive operations:"
  print_matching_lines "$text_path" 40 \
    "SwiftDriver Compilation" \
    "CompileSwiftSources" \
    "CompileSwift " \
    "CompileC " \
    "CompileAssetCatalog" \
    "Ld " \
    "PhaseScriptExecution"
done < "$mapfile_path"
