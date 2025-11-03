#!/usr/bin/env bash
set -euo pipefail

# ติดตั้ง nvm (ครั้งแรก) + Node 16
su - ec2-user -c 'if [ ! -d "$HOME/.nvm" ]; then \
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; \
fi'
su - ec2-user -c 'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; \
  nvm install 16; nvm alias default 16'

# โฟลเดอร์แอป
sudo mkdir -p /opt/ec2-app
sudo chown -R ec2-user:ec2-user /opt/ec2-app