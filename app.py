import os
import datetime
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
        return jsonify({
            'database': 'connected',
            'host': DB_HOST,
            'instance_id': INSTANCE_ID
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
