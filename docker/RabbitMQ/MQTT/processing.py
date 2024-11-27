# consumer.py
import pika
import json
import paho.mqtt.client as mqtt

# تنظیمات RabbitMQ
RABBITMQ_HOST = 'localhost'
RABBITMQ_QUEUE = 'iot_data'

# تنظیمات MQTT
MQTT_BROKER = "broker.emqx.io"
MQTT_PORT = 1883
MQTT_TOPIC = "iot/queue"

# اتصال به RabbitMQ
rabbitmq_connection = pika.BlockingConnection(pika.ConnectionParameters(RABBITMQ_HOST))
rabbitmq_channel = rabbitmq_connection.channel()

# اتصال به MQTT
mqtt_client = mqtt.Client()
mqtt_client.connect(MQTT_BROKER, MQTT_PORT)

def process_message(ch, method, properties, body):
    try:
        # دریافت پیام از RabbitMQ
        data = json.loads(body)
        print(f"پیام دریافت شده از RabbitMQ: {data}")
        
        # ارسال پیام به MQTT
        mqtt_client.publish(MQTT_TOPIC, json.dumps(data))
        print(f"پیام ارسال شده به MQTT: {data}")
        
        # تأیید دریافت پیام به RabbitMQ
        ch.basic_ack(delivery_tag=method.delivery_tag)
    except json.JSONDecodeError:
        print(f"خطا در پردازش پیام: {body}")
        ch.basic_nack(delivery_tag=method.delivery_tag)

# تنظیمات دریافت پیام از RabbitMQ
rabbitmq_channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
rabbitmq_channel.basic_qos(prefetch_count=1)
rabbitmq_channel.basic_consume(queue=RABBITMQ_QUEUE, on_message_callback=process_message)

print('در حال انتظار برای پیام‌ها. برای خروج CTRL+C را فشار دهید.')
rabbitmq_channel.start_consuming()

