#!/usr/bin/env bash
# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/)
# Copyright 2024-present Datadog, Inc.

# Shared HTTP helpers — abstracts curl vs wget.
# Source this file from other scripts: source "$(dirname "$0")/http.sh"

_HTTP_CMD=""

_detect_http_cmd() {
  if [[ -n "$_HTTP_CMD" ]]; then
    return
  fi
  if command -v curl &>/dev/null; then
    _HTTP_CMD="curl"
  elif command -v wget &>/dev/null; then
    _HTTP_CMD="wget"
  else
    echo "::error::Neither curl nor wget found. If you are running this action inside a Docker container, make sure either curl or wget is installed in the container image."
    exit 1
  fi
}

# http_get URL [HEADER...]
# Performs an HTTP GET and outputs the response body to stdout.
# Optional headers are passed as "Key: Value" strings.
http_get() {
  _detect_http_cmd
  local url="$1"
  shift

  if [[ "$_HTTP_CMD" == "curl" ]]; then
    local args=(-sSL)
    for header in "$@"; do
      args+=(-H "$header")
    done
    curl "${args[@]}" "$url"
  else
    local args=(--no-verbose -O-)
    for header in "$@"; do
      args+=(--header="$header")
    done
    wget "${args[@]}" "$url"
  fi
}

# http_download URL FILE
# Downloads a file with retries. Returns non-zero on failure.
http_download() {
  _detect_http_cmd
  local url="$1"
  local output="$2"

  if [[ "$_HTTP_CMD" == "curl" ]]; then
    curl -L --fail --retry 3 --retry-delay 2 "$url" --output "$output"
  else
    wget -q -O "$output" --tries=4 --waitretry=2 "$url"
  fi
}
