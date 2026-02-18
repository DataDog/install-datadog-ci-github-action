#!/usr/bin/env bash
# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2024-present Datadog, Inc.
set -euo pipefail

requested_version="$1"

if [[ "$requested_version" == "latest" ]]; then
  # GitHub redirects /releases/latest → /releases/tag/vX.Y.Z
  # We follow the redirect and extract the tag from the final URL.
  # The response body is discarded (-o /dev/null); only the final URL is captured.
  redirect_url=$(
    curl -sSL -o /dev/null -w '%{url_effective}' \
      "https://github.com/DataDog/datadog-ci/releases/latest"
  )
  resolved_version="${redirect_url##*/}"

  if [[ -z "$resolved_version" || "$resolved_version" == "latest" ]]; then
    echo "::error::Failed to resolve latest datadog-ci version from GitHub Releases."
    exit 1
  fi

  echo "Resolved 'latest' → ${resolved_version}"
else
  resolved_version="$requested_version"
  echo "Using pinned version: ${resolved_version}"
fi

# Normalize: ensure it starts with 'v'
if [[ "$resolved_version" != v* ]]; then
  resolved_version="v${resolved_version}"
fi

echo "version=$resolved_version" >> "$GITHUB_OUTPUT"
