#!/usr/bin/env bash
set -euo pipefail

# รอให้แอปพร้อมสูงสุด ~60วินาที (30 รอบ × 2 วินาที)
for i in {1..30}; do
  if curl -fsS http://localhost:3000/ >/dev/null; then
    exit 0
  fi
  sleep 2
done

echo "App is not responding on localhost:3000"
echo "--- tail app log ---"
tail -n 100 /var/log/ec2-app.log || true
exit 1