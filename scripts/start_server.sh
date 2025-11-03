#!/usr/bin/env bash
set -euo pipefail

# รวม stdout/stderr ของสคริปต์นี้ (กัน error close stdout)
exec > /tmp/codedeploy-start.log 2>&1

# เตรียม log
install -o ec2-user -g ec2-user -m 664 /var/log/ec2-app.log || true

# หยุดของเก่าถ้ามี
pkill -f "node app/index.js" || true

# สตาร์ทด้วย nvm ของ ec2-user แล้ว detach
su - ec2-user -c '
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
  cd /opt/ec2-app
  NODE_ENV=production nohup node app/index.js >> /var/log/ec2-app.log 2>&1 & echo $! > /tmp/ec2-app.pid
'