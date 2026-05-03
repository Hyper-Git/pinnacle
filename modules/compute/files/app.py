from flask import Flask, jsonify
import json
import datetime
import psycopg2

app = Flask(__name__)


def get_db_creds():
    with open('/etc/app/db-credentials.json') as f:
        return json.load(f)


@app.route('/')
def index():
    return 'Pinnacle App - Healthy'


@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.utcnow().isoformat() + 'Z'
    })


@app.route('/db-check')
def db_check():
    try:
        creds = get_db_creds()
        conn = psycopg2.connect(
            host=creds['host'],
            port=int(creds['port']),
            dbname=creds['dbname'],
            user=creds['username'],
            password=creds['password'],
            connect_timeout=5
        )
        conn.close()
        return jsonify({'database': 'connected'})
    except Exception as e:
        return jsonify({'database': 'error', 'message': str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
