from json import dumps
from time import sleep
from kafka import KafkaProducer
topic_name='hello_world4'
producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('utf-8'))
for i in range(100):
    data={'number':i}
    print(data)
    producer.send(topic_name,value=data)
producer.flush()
producer.close()