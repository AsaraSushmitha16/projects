import json
from kafka import KafkaConsumer
consumer=KafkaConsumer('hello_world5',bootstrap_servers=['localhost:9092'],
                       value_deserializer=lambda x:json.loads(x.decode('utf-8')),group_id='demos1',auto_offset_reset='earliest')
for i in consumer:
    print(i)