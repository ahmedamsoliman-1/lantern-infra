#!/usr/bin/env bash
set -Eeuo pipefail
: "${LANTERN_CORE_IP:?Set LANTERN_CORE_IP or source .env first}"
for name in windows.home.arpa dashboard.home.arpa status.home.arpa; do
  if command -v dig >/dev/null; then
    dig +short "@$LANTERN_CORE_IP" "$name"
  else
    nslookup "$name" "$LANTERN_CORE_IP"
  fi
done

