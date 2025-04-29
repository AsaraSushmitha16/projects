from time import sleep
from kafka import KafkaProducer
from json import dumps
import random
def custom_partitioner(key,all_partitions,available):
    return int(key.decode('UTF-8'))%len(all_partitions)

producer=KafkaProducer(bootstrap_servers=['localhost:9092'],partitioner=custom_partitioner,value_serializer=lambda x:dumps(x).encode('utf-8'))
topic_name='hello_world'
country_list=['India','Nepal','USA','Bhutan']
for i in range(10):
    data={'user_id':i,'country':random.choice(country_list),'amount':1}
    print("data is",data)
    producer.send(topic_name,key=str(i).encode(),value=(data))
    sleep(0.2)
