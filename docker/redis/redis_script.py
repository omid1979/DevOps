import redis

# Connect to Redis server
r = redis.Redis(host='redis', port=6379, db=0)

# Write a string to Redis
r.set('key', 'Hello, Redis!')

# Read the string back from Redis
value = r.get('key')

# Print the value to show users
print(f'The value of "key" is: {value.decode("utf-8")}')

