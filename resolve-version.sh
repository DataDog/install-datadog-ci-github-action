#!/usr/bin/env bash
# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2024-present Datadog, Inc.
set -euo pipefail

# shellcheck source=http.sh
source "${GITHUB_ACTION_PATH:-$(dirname "$0")}/http.sh"

requested_version="$1"

if [[ "$requested_version" =~ ^v?[0-9]+$ ]]; then
  # Major version only (e.g., "v5" or "5") → resolve to the latest release within that major version.
  major="${requested_version#v}"

  headers=()
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    headers+=("Authorization: token ${GITHUB_TOKEN}")
  fi

  releases_json=$(http_get "https://api.github.com/repos/DataDog/datadog-ci/releases?per_page=100" ${headers[@]+"${headers[@]}"})

  if command -v jq &>/dev/null; then
    all_versions=$(echo "$releases_json" | jq -r '.[] | select(.prerelease == false) | .tag_name')
  else
    # Fallback: parse JSON with awk when jq is not available.
    all_versions=$(echo "$releases_json" | \
      awk '/"tag_name"/ { gsub(/.*"tag_name"[[:space:]]*:[[:space:]]*"/, ""); gsub(/".*/, ""); tag = $0 }
           /"prerelease"[[:space:]]*:[[:space:]]*false/ { if (tag != "") { print tag; tag = "" } }')
  fi
  resolved_version=$(echo "$all_versions" | grep "^v${major}\." | head -1)

  if [[ -z "$resolved_version" ]]; then
    echo "::error::Failed to resolve latest v${major}.x datadog-ci version from GitHub Releases."
    exit 1
  fi

  echo "Resolved 'v${major}' → ${resolved_version}"
else
  resolved_version="$requested_version"
  echo "Using pinned version: ${resolved_version}"
fi

# Normalize: ensure it starts with 'v'
if [[ "$resolved_version" != v* ]]; then
  resolved_version="v${resolved_version}"
fi

echo "version=$resolved_version" >> "$GITHUB_OUTPUT"
