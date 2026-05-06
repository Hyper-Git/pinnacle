import os
import datetime
import json
import boto3
import psycopg2
from flask import Flask, jsonify
from dotenv import load_dotenv

# Load configuration from /etc/app/.env if it exists, otherwise from current dir
env_path = '/etc/app/.env'
if os.path.exists(env_path):
    load_dotenv(env_path)
else:
    load_dotenv()

app = Flask(__name__)

# ── Configuration Handling ───────────────────────────────────────────────────

INSTANCE_ID = os.environ.get('INSTANCE_ID', 'unknown')
REGION = os.environ.get('AWS_REGION', 'eu-west-2')
DB_SECRET_ARN = os.environ.get('DB_SECRET_ARN')

# Initialize DB config with defaults from environment
DB_CONFIG = {
    'host': os.environ.get('DB_HOST'),
    'user': os.environ.get('DB_USER'),
    'pass': os.environ.get('DB_PASS'),
    'port': int(os.environ.get('DB_PORT', 5432)),
    'name': os.environ.get('DB_NAME')
}

# If a secret ARN is provided, fetch credentials directly into memory
if DB_SECRET_ARN:
    try:
        client = boto3.client('secretsmanager', region_name=REGION)
        response = client.get_secret_value(SecretId=DB_SECRET_ARN)
        secrets = json.loads(response['SecretString'])
        
        DB_CONFIG.update({
            'host': secrets['host'],
            'user': secrets['username'],
            'pass': secrets['password'],
            'port': int(secrets['port']),
            'name': secrets['dbname']
        })
        print(f"Successfully loaded secrets from {DB_SECRET_ARN}")
    except Exception as e:
        print(f"Warning: Failed to fetch secrets from AWS: {str(e)}")

@app.route('/')
def index():
    return f'Pinnacle App - Instance {INSTANCE_ID} - Healthy (Secrets: {"Memory" if DB_SECRET_ARN else "Disk"})'


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
            host=DB_CONFIG['host'],
            port=DB_CONFIG['port'],
            dbname=DB_CONFIG['name'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['pass'],
            connect_timeout=5
        )
        cur = conn.cursor()
        cur.execute('SELECT 1')
        cur.close()
        conn.close()
        return jsonify({
            'database': 'connected',
            'host': DB_CONFIG['host'],
            'instance_id': INSTANCE_ID,
            'secret_source': 'AWS Secrets Manager' if DB_SECRET_ARN else 'Local Environment'
        })
    except Exception as e:
        return jsonify({
            'database': 'error',
            'message': str(e),
            'instance_id': INSTANCE_ID
        }), 500


if __name__ == '__main__':
    # Default to 8080 to match systemd and security group
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
