from kafka import KafkaProducer
from time import sleep
from json import dumps
import json
import time
from datetime import datetime,timedelta
topic_name='car_speed'

def custom_partitioner(key,all_partitions,available_partitions):
    return int(key.decode('UTF-8'))%len(all_partitions)

producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('UTF-8'),partitioner=custom_partitioner)


list_car=[
    {"car_id":1,"car_name":"honda","car_speed":5},
    {"car_id":2,"car_name":"tesla","car_speed":3},
    {"car_id":3,"car_name":"volvo","car_speed":8},
    {"car_id":4,"car_name":"honda","car_speed":9},
    {"car_id":5,"car_name":"tesla","car_speed":2},
    {"car_id":6,"car_name":"volvo","car_speed":8},
    {"car_id":7,"car_name":"honda","car_speed":5},
    {"car_id":8,"car_name":"tesla","car_speed":7},
    {"car_id":9,"car_name":"volvo","car_speed":1},
    {"car_id":10,"car_name":"volvo","car_speed":5},
    {"car_id":11,"car_name":"volvo","car_speed":2},
    {"car_id":12,"car_name":"volvo","car_speed":3},
    {"car_id":13,"car_name":"volvo","car_speed":6},
    {"car_id":14,"car_name":"volvo","car_speed":5},
    {"car_id":15,"car_name":"volvo","car_speed":3},
    {"car_id":16,"car_name":"volvo","car_speed":1},
    {"car_id":17,"car_name":"volvo","car_speed":8},
    {"car_id":18,"car_name":"volvo","car_speed":9},
]
for i in range(0,len(list_car)):
    if i in (2,5,8,12,14,17):
        list_car[i]['capture_time']=int(time.time())
        print(list_car[i])
        producer.send(topic_name,key=str(i).encode(),value=(list_car[i]))
        sleep(1)
    else:
        list_car[i]['capture_time']=int(time.time())
        print(list_car[i])
        producer.send(topic_name,key=str(i).encode(),value=(list_car[i]))
while True:
    data=json.loads((input("enter the data").replace("'",'"')))
    print("inserting the data: ",data)
    producer.send(topic_name,key=str(data['car_id']).encode(),value=(data))
