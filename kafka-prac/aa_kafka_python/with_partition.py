#first
# from kafka import KafkaProducer
# from time import sleep
# from json import dumps
#
# producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('utf-8'))
# data1={'number1':1}
# data2={'number2':2}
# data3={'number3':3}
# data4={'number4':4}
# data5={'number5':5}
# data6={'number6':6}
# producer.send(topic='hello_world0',value=data1,partition=1)
# producer.close()
#
# -----------------------------------------------------------------------------------------------------------------------------
#second
# from kafka import KafkaProducer
# from time import sleep
# from json import dumps
# producer=KafkaProducer(bootstrap_servers=['localhost:9092'])
# producer.send(topic='hello_world1',key=b'foo',value=b'bar')
# producer.send(topic='hello_world1',key=b'foo',value=b'bar')
# producer.close()

# -----------------------------------------------------------------------------------------------------------------------------
# third
# from kafka import KafkaProducer
# from json import dumps
# producer=KafkaProducer(bootstrap_servers=['localhost:9092'],key_serializer=str.encode,value_serializer=lambda x:dumps(x).encode('utf-8'))
# data1={'number1':1}
# data2={'number2':2}
# data3={'number3':3}
# data4={'number4':4}
# data5={'number5':5}
# data6={'number6':6}
# producer.send(topic='hello_world2',key='ping',value=data1)
# producer.send(topic='hello_world2',key='ping',value=data2)
# producer.send(topic='hello_world2',key='ping',value=data3)
# producer.send(topic='hello_world2',key='pong',value=data4)
# producer.send(topic='hello_world2',key='pong',value=data5)
# producer.send(topic='hello_world2',key='pong',value=data6)

# -----------------------------------------------------------------------------------------------------------------------------
#fourth
# from kafka import KafkaProducer
# from json import dumps
# def custom_partition(key,all_partitions,available):
#     print(f"the key is: {key}")
#     print(f"All partitions: {all_partitions}")
#     print(f"After decode of the key: {key.decode('utf-8')}")
#     return int(key.decode('utf-8'))%len(all_partitions)
# producer=KafkaProducer(bootstrap_servers=['localhost:9092'],partitioner=custom_partition)
# producer.send(topic='hello_world3',key=b'3',value=b'Hello Partitioner')
# producer.send(topic='hello_world3',key=b'2',value=b'Hello Partitioner')
# producer.send(topic='hello_world3',key=b'369',value=b'Hello Partitioner')
# producer.send(topic='hello_world3',key=b'301',value=b'Hello Partitioner')