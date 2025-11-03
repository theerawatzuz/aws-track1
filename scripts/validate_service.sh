#!/usr/bin/env bash
set -euo pipefail
for i in {1..15}; do
  curl -fsS http://localhost:3000/ >/dev/null && exit 0
  sleep 2
done
exit 1