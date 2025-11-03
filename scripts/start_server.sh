#!/usr/bin/env bash
set -euo pipefail
systemctl restart ec2-app.service > /dev/null 2>&1 &
exit 0