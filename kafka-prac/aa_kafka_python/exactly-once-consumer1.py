from kafka import KafkaConsumer,TopicPartition,OffsetAndMetadata
import json
consumer=KafkaConsumer('hello_world',
                       bootstrap_servers=['localhost:9092'],
                       value_deserializer=lambda x:json.loads(x.decode('utf-8')),
                       group_id='demos',auto_offset_reset='earliest',enable_auto_commit=False)

for i in consumer:
    print(i)
    print(f'the value is {i.value}')
    print(f'the key is {i.key}')
    print(f'the topic is {i.topic}')
    print(f'the partition is {i.partition}')
    print(f'the offset is {i.offset}')
    print(f'the timestamp is {i.timestamp}')
    tp=TopicPartition(i.topic,i.partition)
    om=OffsetAndMetadata(i.offset+1,i.timestamp)
    consumer.commit({tp:om})
    print('*' * 100)
