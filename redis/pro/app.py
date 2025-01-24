from flask import Flask, jsonify
import redis
import time

app = Flask(__name__)
redis_client = redis.Redis(host='redis', port=6379, db=0)

RATE_LIMIT = 100
RATE_LIMIT_PERIOD = 5  # in seconds

def is_rate_limited(user_id):
    current_time = int(time.time())
    key = f"rate_limit:{user_id}:{current_time // RATE_LIMIT_PERIOD}"
    
    count = redis_client.incr(key)
    if count == 1:
        redis_client.expire(key, RATE_LIMIT_PERIOD)
    
    return count > RATE_LIMIT

@app.route('/api/<user_id>')
def api_request(user_id):
    if is_rate_limited(user_id):
        return jsonify({"error": "Rate limit exceeded"}), 429
    return jsonify({"message": "Request successful"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)


