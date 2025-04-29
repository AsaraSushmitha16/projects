from kafka import KafkaProducer
import json
bootstrap_servers = ['localhost:9092']
primary_topic = 'demo'
dlq_topic = 'dlq_topic'
dlq_producer = KafkaProducer(
    bootstrap_servers=bootstrap_servers,
    value_serializer=lambda x: x.encode('utf-8'),
    acks='all'
)
demo_producer = KafkaProducer(
    bootstrap_servers=bootstrap_servers,
    value_serializer=lambda x: x.encode('utf-8'),
    acks='all'
)
# consumer = KafkaConsumer(
#     'demo',
#     bootstrap_servers=bootstrap_servers,
#     auto_offset_reset='latest',
#     enable_auto_commit=True,
#     value_deserializer=lambda x: x.decode('utf-8')
# )
for i in range(5):
    msg=input("enter json data: ")
    #print(f'\nReceived:\nPartition: {msg.partition} \tOffset: {msg.offset}\tValue: {msg.value}')
    print("msg",msg)

    try:
        data = json.loads(msg)
        print('Data Received:', data)
        demo_producer.send(primary_topic, value=msg)
    except:
        print(f'Value {msg} not in JSON format')
        dlq_producer.send(dlq_topic, value=msg)
        print('Message sent to DLQ Topic')