from time import sleep
from kafka import KafkaProducer
from json import dumps
topic_name='hello_world'
producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('utf-8'))
for i in range(1000):
    data={'number':i}
    print(data)
    producer.send(topic_name,value=data)
    sleep(2)