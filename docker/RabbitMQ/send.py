import pika
import random
import string
import time

connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()

channel.queue_declare(queue='random_strings')

def generate_random_string(length=100):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

try:
    while True:
        random_string = generate_random_string()
        channel.basic_publish(exchange='',
                              routing_key='random_strings',
                              body=random_string)
        print(f"{random_string}")
        # time.sleep(0.1) 
except KeyboardInterrupt:
    print("STOP!")
finally:
    connection.close()


