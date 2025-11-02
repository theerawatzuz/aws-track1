#!/usr/bin/env bash
set -e
cd /opt/ec2-app
nohup node app/index.js > /var/log/ec2-app.log 2>&1 &
