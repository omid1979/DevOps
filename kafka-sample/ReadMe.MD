
# مستند پروژه: پیاده‌سازی زیرساخت داده با Kafka و اتصال به MQTT

**تهیه‌کننده**: امید حسینی  

---

## مقدمه
این مستند، پیاده‌سازی یک زیرساخت داده را شرح می‌دهد که در آن 2000 سنسور فرضی هر 0.1 ثانیه داده تولید می‌کنند، این داده‌ها به Apache Kafka ارسال شده و سپس به یک بروکر MQTT منتقل می‌شوند. هدف این پروژه، آزمایش قابلیت‌های Kafka در مدیریت جریان داده و اتصال آن به سیستم‌های دیگر است.

---

## نیازمندی‌ها
### سخت‌افزار
- سرور با Proxmox نصب‌شده
- رم: 32 گیگابایت
- ذخیره‌سازی: دو هارد SSD

### نرم‌افزار
- Docker
- Python 3.x
- کتابخانه‌ها:
  - `kafka-python`
  - `paho-mqtt`
  - `psycopg2-binary`
- Apache Kafka (با Zookeeper)
- PostgreSQL (اختیاری برای ذخیره‌سازی)
- بروکر MQTT (Mosquitto)

---

## معماری پروژه
1. **تولید داده**: اسکریپت پایتون برای شبیه‌سازی 2000 سنسور.
2. **Kafka**: بروکر پیام‌رسانی برای دریافت و توزیع داده.
3. **MQTT**: بروکر برای انتقال داده به سیستم‌های دیگر.
4. **مصرف‌کننده‌ها**: نمایش realtime یا ذخیره در دیتابیس.

---

## پیاده‌سازی

### 1. اسکریپت تولید داده (2000 سنسور)
```python
import time
import random
import json
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

def generate_sensor_data(sensor_id):
    temperature = random.uniform(20.0, 40.0)
    return {
        'sensor_id': sensor_id,
        'temperature': temperature,
        'timestamp': time.time()
    }

while True:
    for sensor_id in range(1, 2001):
        data = generate_sensor_data(sensor_id)
        producer.send('sensor_data', value=data)
        print(f"Sent: {data}")
    time.sleep(0.1)

producer.close()
```

**نصب**:
```bash
pip install kafka-python
```

---

### 2. راه‌اندازی Kafka روی Docker
فایل `docker-compose.yml`:
```yaml
version: '3'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_NUM_PARTITIONS: 10
      KAFKA_MESSAGE_MAX_BYTES: 1000000
      KAFKA_REPLICA_FETCH_MAX_BYTES: 1000000
```

**اجرا**:
```bash
docker-compose up -d
```

---

### 3. اتصال Kafka به بروکر MQTT
**اسکریپت Consumer**:
```python
from kafka import KafkaConsumer
import paho.mqtt.client as mqtt
import json

consumer = KafkaConsumer(
    'sensor_data',
    bootstrap_servers='localhost:9092',
    auto_offset_reset='latest',
    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
)

mqtt_client = mqtt.Client()
mqtt_client.connect('localhost', 1883, 60)

for message in consumer:
    data = message.value
    sensor_id = data['sensor_id']
    mqtt_topic = f"sensors/{sensor_id}"
    mqtt_client.publish(mqtt_topic, json.dumps(data))
    print(f"Sent to MQTT: {data}")

mqtt_client.disconnect()
```

**نصب**:
```bash
pip install kafka-python paho-mqtt
```

---

### 4. گزینه‌های خواندن داده
#### الف) مستقیم از Kafka
```python
from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
    'sensor_data',
    bootstrap_servers='localhost:9092',
    auto_offset_reset='latest',
    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
)

for message in consumer:
    print(f"Read from Kafka: {message.value}")
```

#### ب) ذخیره در PostgreSQL و خواندن از آن
**راه‌اندازی PostgreSQL**:
```yaml
version: '3'
services:
  postgres:
    image: postgres:latest
    environment:
      POSTGRES_DB: sensors_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: your_password
    ports:
      - "5432:5432"
```
اجرا: `docker-compose up -d`

**ذخیره داده**:
```python
from kafka import KafkaConsumer
import psycopg2
import json

conn = psycopg2.connect(
    dbname="sensors_db",
    user="postgres",
    password="your_password",
    host="localhost",
    port="5432"
)
cur = conn.cursor()

cur.execute("""
    CREATE TABLE IF NOT EXISTS sensor_data (
        sensor_id INT,
        temperature FLOAT,
        timestamp FLOAT
    )
""")
conn.commit()

consumer = KafkaConsumer(
    'sensor_data',
    bootstrap_servers='localhost:9092',
    auto_offset_reset='latest',
    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
)

for message in consumer:
    data = message.value
    cur.execute(
        "INSERT INTO sensor_data (sensor_id, temperature, timestamp) VALUES (%s, %s, %s)",
        (data['sensor_id'], data['temperature'], data['timestamp'])
    )
    conn.commit()
    print(f"Saved to DB: {data}")

cur.close()
conn.close()
```

**نصب**:
```bash
pip install kafka-python psycopg2-binary
```

---

## مراحل اجرا
1. Kafka و Zookeeper رو با `docker-compose up -d` اجرا کن.
2. اسکریپت تولید داده رو توی یه ترمینال اجرا کن.
3. اسکریپت اتصال به MQTT رو توی ترمینال دیگه اجرا کن.
4. برای خواندن داده:
   - یا Consumer مستقیم Kafka رو اجرا کن.
   - یا PostgreSQL رو راه بنداز و داده‌ها رو اونجا ذخیره کن.

---

## نکات
- **تنظیمات Kafka**: 10 پارتیشن برای توزیع بار 2000 سنسور کافیست.
- **MQTT**: پورت 1883 فرض شده؛ در صورت نیاز تغییر دهید.
- **عملکرد**: با 32 گیگ رم، این پروژه روی سرور خانگی به‌خوبی اجرا می‌شود.

---

## نتیجه‌گیری
این پروژه نشان داد که Kafka می‌تواند به‌عنوان یک لایه میانی برای مدیریت جریان داده عمل کند و با اتصال به MQTT، انعطاف‌پذیری بالایی ارائه دهد. برای پروژه‌های بزرگ‌تر، Kafka پایداری و مقیاس‌پذیری بیشتری نسبت به MQTT تنها فراهم می‌کند.

---

**پایان مستند**

---


