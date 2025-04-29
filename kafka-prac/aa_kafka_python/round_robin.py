from confluent_kafka import Producer

# Initialize Kafka producer
producer = Producer({'bootstrap.servers': 'localhost:9092,localhost:9093,localhost:9094'})
topic='demo_testing5'
messages = ['message1', 'message2', 'message3','message4', 'message5', 'message6','message7', 'message8', 'message9','message10', 'message11', 'message12']  # Add more messages as needed
for index,message in enumerate(messages):
    partition=index%7
    producer.produce(topic=topic,value=message,partition=partition)
producer.flush()