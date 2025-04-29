from time import sleep
from kafka import KafkaProducer
from json import dumps
topic_name="hello_world"
producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('utf-8'))
while True:
    message=input("enter the message you want to send: ")
    partition_no=int(input("in which partition you want to send: "))
    producer.send(topic_name,value=message,partition=partition_no)

producer.close()