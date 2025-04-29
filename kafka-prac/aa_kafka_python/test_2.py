from kafka import KafkaProducer, KafkaConsumer
import json
bootstrap_servers = ['localhost:9092']
primary_topic = 'demo'
dlq_topic = 'dlq_topic'

consumer = KafkaConsumer(
    'demo',
    bootstrap_servers=bootstrap_servers,
    auto_offset_reset='latest',
    enable_auto_commit=True,
    value_deserializer=lambda x: x.decode('utf-8')
)
for i in range(5):
    msg=input("enter json data: ")
    print(f'\nReceived:\nPartition: {msg.partition} \tOffset: {msg.offset}\tValue: {msg.value}')
    print("msg",msg)

    try:
        data = json.loads(msg.value)
        print('Data Received:', data)
        demo_producer.send(primary_topic, value=msg)
    except:
        print(f'Value {msg.value} not in JSON format')
        dlq_producer.send(dlq_topic, value=msg.value)
        print('Message sent to DLQ Topic')