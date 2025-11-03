#!/usr/bin/env bash
set -euo pipefail

# เตรียมไฟล์ log ให้ ec2-user
sudo install -o ec2-user -g ec2-user -m 664 /dev/null /var/log/ec2-app.log || true

# หยุดของเก่าถ้ามี
pkill -f "node app/index.js" || true

# ใช้ nvm + Node 16 (ตามที่เราติดตั้งใน before_install)
su - ec2-user -c 'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; \
  cd /opt/ec2-app && nohup node app/index.js >> /var/log/ec2-app.log 2>&1 &'