from kafka import KafkaConsumer,KafkaProducer
import json
bootstrap_servers = ['localhost:9092']
primary_topic = 'demo'
dlq_topic = 'dlq_topic'
dlq_producer = KafkaProducer(
    bootstrap_servers=bootstrap_servers,
    value_serializer=lambda x: x.encode('utf-8'),
    acks='all'
)
consumer = KafkaConsumer(
    'demo',
    bootstrap_servers=bootstrap_servers,
    auto_offset_reset='latest',
    enable_auto_commit=True,
    value_deserializer=lambda x: x.decode('utf-8')
)
for msg in consumer:
    print(f'\nReceived:\nPartition: {msg.partition} \tOffset: {msg.offset}\tValue: {msg.value}')
    print("msg",msg)
    try:
        data = json.loads(msg.value)
        print('Data Received:', data)

    except:
        print(f'Value {msg.value} not in JSON format')
        dlq_producer.send(dlq_topic, value=msg.value)
        print('Message sent to DLQ Topic')