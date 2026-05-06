#!/bin/bash
set -euo pipefail

# ── 1. Create Non-Privileged User ─────────────────────────────────────────────
useradd -r -s /sbin/nologin appuser

# ── 2. Directory Setup & Packages ─────────────────────────────────────────────
mkdir -p /etc/app
dnf update -y
dnf install -y python3-pip amazon-ssm-agent unzip

systemctl enable --now amazon-ssm-agent
pip3 install flask gunicorn psycopg2-binary python-dotenv boto3

# ── 3. Configuration Setup ────────────────────────────────────────────────────
# Fetch instance ID via IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

# Create environment file with non-sensitive identifiers only
# The application will use DB_SECRET_ARN to fetch credentials into memory
cat > /etc/app/.env << ENVEOF
INSTANCE_ID=$INSTANCE_ID
AWS_REGION=${region}
DB_SECRET_ARN=${db_secret_arn}
ENVEOF

# Set strict permissions
chown -R appuser:appuser /etc/app
chmod 600 /etc/app/.env

# ── 4. Download & Extract Application ─────────────────────────────────────────
# We try to download the artifact. If it's missing (first boot), we write a temporary bootstrap app.
if aws s3 cp s3://${deployment_bucket_name}/releases/app-latest.zip /tmp/app.zip; then
    unzip -o /tmp/app.zip -d /etc/app
    rm /tmp/app.zip
else
    echo "Deployment artifact not found. Writing bootstrap app."
    cat > /etc/app/app.py << 'PYEOF'
import os
from flask import Flask
app = Flask(__name__)
@app.route('/')
def index(): return "Pinnacle Bootstrap - Waiting for first CI/CD push..."
@app.route('/health')
def health(): return {"status": "healthy"}
if __name__ == '__main__': app.run(host='0.0.0.0', port=8080)
PYEOF
fi

# ── 5. Systemd Service (Running as appuser) ───────────────────────────────────
cat > /etc/systemd/system/pinnacle.service << 'SERVICE'
[Unit]
Description=Pinnacle Flask Application
After=network.target

[Service]
Type=simple
User=appuser
Group=appuser
WorkingDirectory=/etc/app
EnvironmentFile=/etc/app/.env
ExecStart=/usr/local/bin/gunicorn --bind 0.0.0.0:8080 --workers 2 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now pinnacle
