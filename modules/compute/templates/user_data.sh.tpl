#!/bin/bash
set -euo pipefail

mkdir -p /etc/app

# System updates + Python packages + SSM agent (explicit install covers minimal AMIs)
dnf update -y
dnf install -y python3-pip amazon-ssm-agent

systemctl enable --now amazon-ssm-agent

pip3 install flask gunicorn psycopg2-binary python-dotenv

# Fetch DB credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id '${db_secret_arn}' \
  --region '${region}' \
  --query SecretString \
  --output text > /etc/app/db-credentials.json
chmod 600 /etc/app/db-credentials.json

# Parse JSON credentials into an env file for Flask and systemd
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

# Fetch instance ID via IMDSv2 and append to env file
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
echo "INSTANCE_ID=$INSTANCE_ID" >> /etc/app/.env

chmod 600 /etc/app/.env

# Write Flask application inline
cat > /etc/app/app.py << 'PYEOF'
import os
import datetime
import psycopg2
from flask import Flask, jsonify
from dotenv import load_dotenv

load_dotenv('/etc/app/.env')

app = Flask(__name__)

INSTANCE_ID = os.environ.get('INSTANCE_ID', 'unknown')
DB_HOST = os.environ.get('DB_HOST')
DB_USER = os.environ.get('DB_USER')
DB_PASS = os.environ.get('DB_PASS')
DB_PORT = int(os.environ.get('DB_PORT', 5432))
DB_NAME = os.environ.get('DB_NAME')


@app.route('/')
def index():
    return f'Pinnacle App - Instance {INSTANCE_ID} - Healthy'


@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'instance_id': INSTANCE_ID,
        'timestamp': datetime.datetime.utcnow().isoformat() + 'Z'
    })


@app.route('/db-check')
def db_check():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS,
            connect_timeout=5
        )
        cur = conn.cursor()
        cur.execute('SELECT 1')
        cur.close()
        conn.close()
        return jsonify({'database': 'connected', 'host': DB_HOST})
    except Exception as e:
        return jsonify({'database': 'error', 'message': str(e)}), 500
PYEOF

# Systemd service — gunicorn on port 80, env loaded from .env file
cat > /etc/systemd/system/pinnacle.service << 'SERVICE'
[Unit]
Description=Pinnacle Flask Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/app
EnvironmentFile=/etc/app/.env
ExecStart=/usr/local/bin/gunicorn --bind 0.0.0.0:80 --workers 2 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now pinnacle
