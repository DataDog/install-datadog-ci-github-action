#!/usr/bin/env bash
# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2024-present Datadog, Inc.
set -euo pipefail

version="$1"      # e.g. "v5.6.0"
binary_name="$2"  # e.g. "datadog-ci_linux-x64" (remote asset name)

checksums_url="https://github.com/DataDog/datadog-ci/releases/download/${version}/checksums.txt"
dest_dir="${RUNNER_TOOL_CACHE:-${HOME}/.datadog-ci}/datadog-ci/${version}"

# Determine local filename (must match download.sh)
if [[ "$RUNNER_OS" == "Windows" ]]; then
  dest_file="$dest_dir/datadog-ci.exe"
else
  dest_file="$dest_dir/datadog-ci"
fi

echo "Downloading checksums from ${checksums_url}"
if ! curl -L --fail --retry 3 --retry-delay 2 "$checksums_url" --output "$dest_dir/checksums.txt"; then
  echo "::warning::Failed to download checksums file. Skipping checksum verification."
  exit 0
fi

# Extract the expected checksum for the binary we downloaded
expected=$(grep "$binary_name" "$dest_dir/checksums.txt" | awk '{print $1}')
if [[ -z "$expected" ]]; then
  echo "::warning::No checksum found for ${binary_name} in checksums.txt. Skipping verification."
  exit 0
fi

# Compute actual checksum (shasum is available on Linux, macOS, and Windows Git Bash)
actual=$(shasum -a 256 "$dest_file" | awk '{print $1}')

if [[ "$expected" != "$actual" ]]; then
  echo "::error::Checksum mismatch for ${binary_name}. Expected: ${expected}, got: ${actual}. The binary may be corrupted or tampered with."
  rm -f "$dest_file"
  exit 1
fi

echo "Checksum verified: ${actual}"
