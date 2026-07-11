#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[[ -f .env ]] || { echo 'Missing .env; run make bootstrap.' >&2; exit 1; }
docker compose -f compose/compose.yaml up -d --remove-orphans

