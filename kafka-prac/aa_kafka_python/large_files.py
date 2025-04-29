from confluent_kafka import Producer, Consumer

# Producer configuration
producer_config = {
    'bootstrap.servers': 'localhost:9092',
    'compression.codec': 'gzip',  # Enable compression
    # Add other producer configs as needed
}

# Create a Kafka producer
producer = Producer(producer_config)

# Produce a large message
large_message = "your_large_message_here"

# Produce the message to a Kafka topic
producer.produce('your_topic', value=large_message)

# Make sure to flush messages to Kafka
producer.flush()

# Consumer configuration
consumer_config = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'your_consumer_group_id',
    # Add other consumer configs as needed
}

# Create a Kafka consumer
consumer = Consumer(consumer_config)

# Subscribe to the Kafka topic
consumer.subscribe(['your_topic'])

# Start consuming messages
while True:
    msg = consumer.poll(timeout=1.0)
    if msg is None:
        continue
    if msg.error():
        print("Consumer error: {}".format(msg.error()))
        continue
    print('Received message: {}'.format(msg.value().decode('utf-8')))

# Close Kafka producer and consumer when done
producer.close()
consumer.close()
