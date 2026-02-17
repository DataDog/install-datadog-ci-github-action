#!/usr/bin/env bash
# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2024-present Datadog, Inc.
set -euo pipefail

version="$1"      # e.g. "v5.6.0"
binary_name="$2"  # e.g. "datadog-ci_linux-x64" (remote asset name, no .exe even for Windows)

url="https://github.com/DataDog/datadog-ci/releases/download/${version}/${binary_name}"
dest_dir="${RUNNER_TOOL_CACHE:-${HOME}/.datadog-ci}/datadog-ci/${version}"

mkdir -p "$dest_dir"

# Determine local filename — add .exe on Windows for shell/OS association
if [[ "$RUNNER_OS" == "Windows" ]]; then
  dest_file="$dest_dir/datadog-ci.exe"
else
  dest_file="$dest_dir/datadog-ci"
fi

echo "Downloading ${url} → ${dest_file}"
if ! curl -L --fail --retry 3 --retry-delay 2 "$url" --output "$dest_file"; then
  echo "::error::Failed to download datadog-ci ${version}. Verify the version exists: https://github.com/DataDog/datadog-ci/releases/tag/${version}"
  exit 1
fi

if [[ "$RUNNER_OS" != "Windows" ]]; then
  chmod +x "$dest_file"
fi

echo "Downloaded datadog-ci ${version}"
