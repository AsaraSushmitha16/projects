from kafka import KafkaProducer
from json import dumps
producer=KafkaProducer(bootstrap_servers='localhost:9092',value_serializer=lambda x:dumps(x).encode('utf-8'))
for i in range(1000):
    data={'number':i}
    producer.send(topic='hello_world',value=data)
producer.flush()
producer.close()
