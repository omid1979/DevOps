# sender.py
import pika
import sys

# اتصال به RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()

# ایجاد صف
channel.queue_declare(queue='task_queue', durable=True)

# ارسال پیام
message = ' '.join(sys.argv[1:]) or "Hello World!"
channel.basic_publish(
    exchange='',
    routing_key='task_queue',
    body=message,
    properties=pika.BasicProperties(
        delivery_mode=2,  # پیام پایدار
    ))

print(f" [x] Sent {message}")

connection.close()

