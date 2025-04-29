import json
from kafka import TopicPartition,OffsetAndMetadata
import kafka
from kafka import KafkaConsumer
from time import sleep

topic='noofpartition'
class MyConsumerRebalanceListener(kafka.ConsumerRebalanceListener):

    def on_partitions_revoked(self, revoked):
        print(f"partitions {revoked} revoked")

    def on_partitions_assigned(self, assigned):
        print(f"partitions {assigned} assigned")

consumer=KafkaConsumer(bootstrap_servers=['localhost:9092'],
                       value_deserializer=lambda x: json.loads(x.decode('utf-8')),
                       group_id='consumer_group',
                       auto_offset_reset='earliest',
                       enable_auto_commit=False)
listener=MyConsumerRebalanceListener()
consumer.subscribe('noofpartition',listener=listener)

for i in consumer:
    print(i)
    print(f"the value is : {i.value}")
    tp=TopicPartition(i.topic,i.partition)
    om=OffsetAndMetadata(i.offset+1,i.timestamp)
    consumer.commit({tp:om})
    print("*"*100)

