#!/usr/bin/env bash
set -euo pipefail

# ติดตั้ง dependency
su - ec2-user -c 'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; \
  cd /opt/ec2-app && (npm ci || npm install)'

# สร้าง service unit
cat >/etc/systemd/system/ec2-app.service <<'UNIT'
[Unit]
Description=EC2 App (Node.js)
After=network.target

[Service]
User=ec2-user
Environment=NVM_DIR=/home/ec2-user/.nvm
ExecStart=/bin/bash -lc 'source $NVM_DIR/nvm.sh && cd /opt/ec2-app && node app/index.js >> /var/log/ec2-app.log 2>&1'
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

install -o ec2-user -g ec2-user -m 664 /var/log/ec2-app.log || true
systemctl daemon-reload
systemctl enable ec2-app.service