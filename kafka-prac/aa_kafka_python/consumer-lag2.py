from kafka import KafkaConsumer,TopicPartition,OffsetAndMetadata
import json
from time import sleep

consumer=KafkaConsumer('hello_world',
                       bootstrap_servers=['localhost:9092'],
                       value_deserializer=lambda x:json.loads(x.decode('utf-8')),
                       group_id='demo',
                       auto_offset_reset='earliest',
                       enable_auto_commit=False)
for i in consumer:
    print(i)
    tp=TopicPartition(i.topic,i.partition)
    om=OffsetAndMetadata(i.offset+1,i.timestamp)
    consumer.commit({tp:om})
    sleep(0.8)