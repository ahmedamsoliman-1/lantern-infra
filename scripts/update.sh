#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo 'Image tags are intentionally pinned. Update .env.example and compose defaults first.'
docker compose -f compose/compose.yaml pull
docker compose -f compose/compose.yaml up -d --remove-orphans

