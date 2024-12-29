import sqlite3
import paho.mqtt.client as mqtt

# Database setup
def setup_database():
    conn = sqlite3.connect('mqtt_messages.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic TEXT,
            payload TEXT
        )
    ''')
    conn.commit()
    return conn

# Callback when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    print("Connected with result code " + str(rc))
    # Subscribe to the topic
    client.subscribe("sensor")  # Change this to your desired topic

# Callback when a message is received from the server.
def on_message(client, userdata, msg):
    print(f"Message received on topic {msg.topic}: {msg.payload.decode()}")
    # Save message to database
    save_message_to_db(msg.topic, msg.payload.decode())

# Function to save message to database
def save_message_to_db(topic, payload):
    conn = sqlite3.connect('mqtt_messages.db')
    cursor = conn.cursor()
    cursor.execute('INSERT INTO messages (topic, payload) VALUES (?, ?)', (topic, payload))
    conn.commit()
    conn.close()

# Main function to run the MQTT client
def main():
    # Setup database
    setup_database()

    # Create MQTT client and set callbacks
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    # Connect to the MQTT broker
    broker_address = "127.0.0.1"  # Replace with your broker address
    broker_port = 1883  # Default MQTT port
    client.connect(broker_address, broker_port)

    # Start the loop
    client.loop_forever()

if __name__ == '__main__':
    main()

