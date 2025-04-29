from time import sleep
from json import dumps
from kafka import KafkaProducer

def custom_partitioner(key,all_partitions,available_partitions):
    print(f"the key is {key}")
    print(f"all_partitions {all_partitions}")
    print(f"after decode of the key {key.decode('utf-8')}")
    return int(key.decode('utf-8'))%len(available_partitions)


producer=KafkaProducer(bootstrap_servers=['localhost:9092'],
                       value_serializer=lambda x:dumps(x).encode('utf-8'),
                       partitioner=custom_partitioner)
topic='noofpartition'
for i in range(1000):
    data={'number':i}
    producer.send(topic,key=str(i).encode(),value=data)
    sleep(10)

