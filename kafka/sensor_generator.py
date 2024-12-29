from kafka import KafkaProducer
import json
import random
import time
from datetime import datetime

# Kafka producer configuration
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Kafka topic
topic = 'sensors'

# Function to generate random temperature data
def generate_temperature():
    return round(random.uniform(20.0, 30.0), 1)

# Function to generate sensor data
def generate_sensor_data():
    return {
        'sensor_id': f'sensor_{random.randint(1, 5)}',
        'temperature': generate_temperature(),
        'timestamp': datetime.now().isoformat()
    }

# Main loop to generate and send data
try:
    while True:
        sensor_data = generate_sensor_data()
        producer.send(topic, value=sensor_data)
        print(f"Sent: {sensor_data}")
        time.sleep(0.5)  # Wait for 5 seconds before sending next data point
except KeyboardInterrupt:
    print("Stopping data generation...")
finally:
    producer.close()

