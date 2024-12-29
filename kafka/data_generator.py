from faker import Faker
from kafka import KafkaProducer
import json
import time

# Initialize Faker and KafkaProducer
fake = Faker()
producer = KafkaProducer(bootstrap_servers=['localhost:9092'],
                         value_serializer=lambda v: json.dumps(v).encode('utf-8'))

# Define the Kafka topic
topic = 'my-topic'

# Generate and send random data
while True:
    # Create a dictionary with random data
    data = {
        "name": fake.name(),
        "email": fake.email(),
        "address": fake.address(),
        "phone_number": fake.phone_number(),
        "job": fake.job(),
        "company": fake.company(),
        "timestamp": fake.date_time_this_year().isoformat()
    }
    
    # Send the data to Kafka topic
    producer.send(topic, value=data)
    print(f"Sent: {data}")
    
    # Wait for 1 second before sending the next message
#    time.sleep(1)

# Note: This script runs indefinitely. Use Ctrl+C to stop it.

