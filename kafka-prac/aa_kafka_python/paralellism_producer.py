from json import dumps
from kafka import KafkaProducer
from time import sleep

def custom_partitioner(key,all_partitions,avialbale):
    print(f"the key is {key}")
    print(f"all partitions: {all_partitions}")
    print(f"after_decoding of the key: {key.decode('UTF-8')}")
    return int(key.decode('UTF-8'))%len(all_partitions)

producer=KafkaProducer(bootstrap_servers=['localhost:9092'],partitioner=custom_partitioner)
topic_name='hello_world'
for i in range(1000):
    data={'number':i}
    print(data)
    producer.send(topic_name,key=str(i).encode(),value=str(data).encode())
    sleep(0.5)