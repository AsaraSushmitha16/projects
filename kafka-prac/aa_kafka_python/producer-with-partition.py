from kafka import KafkaProducer
from json import dumps
from time import sleep
def custom_partition(key,all_partitions,available):
    print(f"the key is {key}")
    print(f"the all_partitions {all_partitions}")
    print(f"after decoding the key {key.decode('utf-8')}")
    return int(key.decode('utf-8'))%len(all_partitions)

topic='hello_world'
producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('utf-8'),partitioner=custom_partition)

for i in range(1000):
    data={'number':i}
    print(data)
    producer.send(topic,key=str(i).encode(),value=data)
    sleep(0.4)