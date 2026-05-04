#!/bin/bash
set -euo pipefail

# ── 1. Create Non-Privileged User ─────────────────────────────────────────────
useradd -r -s /sbin/nologin appuser

# ── 2. Directory Setup & Packages ─────────────────────────────────────────────
mkdir -p /etc/app
dnf update -y
dnf install -y python3-pip amazon-ssm-agent unzip

systemctl enable --now amazon-ssm-agent
pip3 install flask gunicorn psycopg2-binary python-dotenv

# ... (omitting secret fetching for brevity in thought, but I must provide full replacement for the targeted section)

# ── 3. Secret Fetching (Securely) ──────────────────────────────────────────────
# Fetch DB credentials from Secrets Manager to a temporary file
aws secretsmanager get-secret-value \
  --secret-id '${db_secret_arn}' \
  --region '${region}' \
  --query SecretString \
  --output text > /etc/app/db-credentials.json

# Parse JSON credentials into an env file
python3 -c "
import json
with open('/etc/app/db-credentials.json') as f:
    c = json.load(f)
with open('/etc/app/.env', 'w') as f:
    f.write('DB_HOST=' + c['host'] + '\n')
    f.write('DB_USER=' + c['username'] + '\n')
    f.write('DB_PASS=' + c['password'] + '\n')
    f.write('DB_PORT=' + str(c['port']) + '\n')
    f.write('DB_NAME=' + c['dbname'] + '\n')
"

# Shred the temporary JSON file
shred -u /etc/app/db-credentials.json

# Fetch instance ID via IMDSv2 and append to env file
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
echo "INSTANCE_ID=$INSTANCE_ID" >> /etc/app/.env

# Set strict permissions
chown -R appuser:appuser /etc/app
chmod 600 /etc/app/.env

# ── 4. Download & Extract Application ─────────────────────────────────────────
aws s3 cp s3://${deployment_bucket_name}/releases/app-latest.zip /tmp/app.zip
unzip -o /tmp/app.zip -d /etc/app
rm /tmp/app.zip

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
