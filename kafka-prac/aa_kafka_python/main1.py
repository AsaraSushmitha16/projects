#fire and forget
# from json import dumps
# from kafka import KafkaProducer
# from time import sleep
#
# topic_name='hello_world1'
# producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x: dumps(x).encode('utf-8'))
# for i in range(100):
#     data={'number':i}
#     print(data)
#     producer.send(topic_name,value=data)
#     sleep(0.5)
#---------------------------------------------------------------------
#synchronous method
# from json import dumps
# from time import sleep
# from kafka import KafkaProducer
# producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('utf-8'))
# topic_name='hello_world1'
# for i in range(100):
#     data={'number':i}
#     print(data)
#     try:
#         record_metadata=producer.send(topic_name,value=data).get(timeout=10)
#         print(record_metadata.topic)
#         print(record_metadata.partition)
#         print(record_metadata.offset)
#         sleep(0.5)
#     except Exception as e:
#         print(e)
# producer.close()
# producer.flush()
#---------------------------------------------------------------------
#Asynchronous method
# from json import dumps
# from kafka import KafkaProducer
#
# topic_name='hello_world1'
# producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('utf-8'))
# def on_send_success(record_metadata,message):
#     print()
#     print("""successfully produced "{}" to topic {} and partition {} at offset{}""".format(message,record_metadata.topic,record_metadata.partition,record_metadata.offset))
#     print()
#
# def on_send_error(excp,message):
#     print()
#     print("its failure message{},error: {}".format(message,excp))
#     print()
#
#
# for i in range(1000):
#     data={'number':i}
#     record_metadata =producer.send(topic_name,value=data).add_callback(on_send_success,message=data).add_errback(on_send_error,message=data)
#     print('sent {}'.format(data))
#
#
# producer.flush()
# producer.close()
#---------------------------------------------------------------------
#Asynchronous method
from json import dumps
from kafka import KafkaProducer
from time import sleep

topic_name='hello_world1'
producer=KafkaProducer(bootstrap_servers=['localhost:9092'],value_serializer=lambda x:dumps(x).encode('utf-8'))
def on_send_success(record_metadata,message):
    print()
    print("""successfully produced "{}" to topic {} and partition {} at offset{}""".format(message,record_metadata.topic,record_metadata.partition,record_metadata.offset))
    print()

def on_send_error(excp,message):
    print()
    print("its failure message{},error: {}".format(message,excp))
    print()


for i in range(1000):
    data={'number':i}
    record_metadata =producer.send(topic_name,value=data).add_callback(on_send_success,message=data).add_errback(on_send_error,message=data)
    print('sent {}'.format(data))
    print()
    sleep(0.5)


producer.flush()
producer.close()