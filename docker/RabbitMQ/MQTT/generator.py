# producer.py
import pika
import json
import random
import time

# تنظیمات RabbitMQ
RABBITMQ_HOST = 'localhost'
RABBITMQ_QUEUE = 'iot_data'

# اتصال به RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters(RABBITMQ_HOST))
channel = connection.channel()

# ایجاد صف
channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)

try:
    while True:
        # تولید داده تصادفی
        data = {
            "device_id": f"device_{random.randint(1, 100)}",
            "temperature": round(random.uniform(20, 30), 2),
            "humidity": round(random.uniform(40, 60), 2),
            "timestamp": int(time.time())
        }
        
        # تبدیل داده به JSON و ارسال به RabbitMQ
        message = json.dumps(data)
        channel.basic_publish(
            exchange='',
            routing_key=RABBITMQ_QUEUE,
            body=message,
            properties=pika.BasicProperties(
                delivery_mode=2,  # پیام پایدار
            )
        )
        print(f"پیام ارسال شد به RabbitMQ: {message}")
        time.sleep(5)  # ارسال هر 5 ثانیه

except KeyboardInterrupt:
    print("برنامه تولیدکننده متوقف شد")
finally:
    connection.close()

