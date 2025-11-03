#!/usr/bin/env bash
set -euo pipefail
su - ec2-user -c 'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; \
  cd /opt/ec2-app && (npm ci || npm install)'