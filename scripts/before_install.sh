#!/usr/bin/env bash
set -e
sudo mkdir -p /opt/ec2-app
if command -v yum >/dev/null 2>&1; then sudo yum install -y nodejs npm || true; fi
if command -v dnf >/dev/null 2>&1; then sudo dnf install -y nodejs npm || true; fi
cd /opt/ec2-app
npm ci || true
