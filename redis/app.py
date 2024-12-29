from flask import Flask, request, jsonify
import redis

app = Flask(__name__)

# Connect to Redis server running in another container
r = redis.Redis(host='redis', port=6379, db=0)

@app.route('/data', methods=['POST'])
def add_data():
    data = request.json.get('data')
    r.set('my_key', data)
    return jsonify({"message": "Data added to Redis"}), 201

@app.route('/data', methods=['GET'])
def get_data():
    value = r.get('my_key')
    if value:
        return jsonify({"data": value.decode('utf-8')}), 200
    return jsonify({"message": "No data found"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

