#Create a Kafka Topic
docker exec -it kafka /opt/kafka/bin/kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 1 --partitions 1 --topic my-topic

##Produce and Consume Messages
#Produce messages:
    docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic my-topic
#Consume messages:
    docker exec -it kafka  /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic my-topic --from-beginning
