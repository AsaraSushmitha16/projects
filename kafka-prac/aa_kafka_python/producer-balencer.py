from kafka import KafkaProducer
from json import dumps
from time import sleep
producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('utf-8'))

partitions=2
for i in range(1000):
    data={'number':i}
    print(data)
    producer.send(topic='hello_world',value=data,partition=i%partitions)
    sleep(2)