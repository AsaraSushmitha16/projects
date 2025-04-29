from kafka.coordinator.assignors.range import RangePartitionAssignor
from kafka.coordinator.assignors.roundrobin import RoundRobinPartitionAssignor
from kafka import KafkaConsumer
from kafka import TopicPartition,OffsetAndMetadata
import kafka
import json

class Myconsumerrebalancelistener(kafka.ConsumerRebalanceListener):
    def on_partitions_revoked(self,revoked):
        print(f"partition {revoked} revoked")
        print("*" * 50)
    def on_partitions_assigned(self,assigned):
        print(f"partition {assigned} assigned")
        print("*" * 50)


topic='hello_world'
consumer=KafkaConsumer(bootstrap_servers=['localhost:9092'],
                       value_deserializer=lambda x:json.loads(x.decode('utf-8')),
                       group_id='demo',
                       auto_offset_reset='earliest',
                       enable_auto_commit=False,
                       partition_assignment_strategy=[RoundRobinPartitionAssignor])
listener=Myconsumerrebalancelistener()
consumer.subscribe(topic,listener=listener)
for i in consumer:
    print(i)
    print(f'the value {i.value}')
    tp=TopicPartition(i.topic,i.partition)
    om=OffsetAndMetadata(i.offset+1,i.timestamp)
    consumer.commit({tp:om})