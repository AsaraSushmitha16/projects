from kafka import KafkaConsumer
from kafka import TopicPartition,OffsetAndMetadata
import kafka
import json

class MyConsumerRebalancerLisener(kafka.ConsumerRebalanceListener):
    def on_partitions_revoked(self,revoked):
        print(f"partitions {revoked} revoked")

    def on_partitions_assigned(self,assigned):
        print(f"partitions {assigned} assigned")

consumer=KafkaConsumer(bootstrap_servers=['localhost:9092'],
                       value_deserializer=lambda m:json.loads(m.decode('utf-8')),
                       group_id='demo0',auto_offset_reset='earliest',
                       enable_auto_commit=False)
listener=MyConsumerRebalancerLisener()
consumer.subscribe('hello_world',listener=listener)

for i in consumer:
    print(i)
    print(f"the value is: {i.value}")
    print(f"the key is: {i.key}")
    print(f"the topic is: {i.topic}")
    print(f"the partition is: {i.partition}")
    print(f"the offset is: {i.offset}")
    print(f"the timestamp is: {i.timestamp}")
    tp=TopicPartition(i.topic,i.partition)
    om=OffsetAndMetadata(i.offset+1,i.timestamp)
    consumer.commit({tp:om})
    print("*" * 10)