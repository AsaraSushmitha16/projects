# 1) fire and forgot
# from kafka import KafkaProducer
# from json import dumps
# from time import sleep
#
# topic_name='hello_world'
# producer=KafkaProducer(bootstrap_servers='localhost:9092',value_serializer=lambda x:dumps(x).encode('utf-8'))
# for i in range(100):
#     data={'number':i}
#     print(data)
#     producer.send(topic=topic_name,value=data)
# #     sleep(0.5)
# -----------------------------------------------------------------------------------------------------------------------
#2)synchronous
# from kafka import KafkaProducer
# from time import sleep
# from json import dumps
#
# topic='hello_world'
# producer=KafkaProducer(bootstrap_servers='localhost:9092',value_serializer=lambda x:dumps(x).encode('utf-8'))
# for i in range(100):
#     data={'number':i}
#     try:
#         record_metadata=producer.send(topic=topic,value=data).get(timeout=10)
#         print(record_metadata.topic)
#         print(record_metadata.partition)
#         print(record_metadata.offset)
#         sleep(0.5)
#     except Exception as e:
#         print(e)
# producer.flush()

# -----------------------------------------------------------------------------------------------------------------------
#3)Asynchronous(success)
# from kafka import KafkaProducer
# from json import dumps
# topic='hello_world'
# producer=KafkaProducer(bootstrap_servers='localhost:9092',value_serializer=lambda x:dumps(x).encode('utf-8'))
# def on_send_success(record_metadata,message):
#     print()
#     print(f'successfully produced {message} to topic {record_metadata.topic} and partition {record_metadata.partition} at offset {record_metadata.offset}')
#     print()
#
# def on_send_error(excp,message):
#     print()
#     print(f'failed to write the message {message}, error: {excp}')
#     print()
#
#
# for i in range(1000):
#     data={'number':i}
#     record_metadata=producer.send(topic=topic,value=data).add_callback(on_send_success,message=data).add_errback(on_send_error,message=data)
#     print(f'sent the message {data} using sent method')
# producer.flush()
# producer.close()

# -----------------------------------------------------------------------------------------------------------------------
# 4)Asynchronous(failure)
from kafka import KafkaProducer
from json import dumps
from time import sleep
topic='hello_world'
producer=KafkaProducer(bootstrap_servers='localhost:9092',value_serializer=lambda x:dumps(x).encode('utf-8'))
def on_send_success(record_metadata,message):
    print()
    print(f'successfully produced {message} to topic {record_metadata.topic} and partition {record_metadata.partition} at offset {record_metadata.offset}')
    print()

def on_send_error(excp,message):
    print()
    print(f'failed to write the message {message}, error: {excp}')
    print()


for i in range(1000):
    data={'number':i}
    record_metadata=producer.send(topic=topic,value=data).add_callback(on_send_success,message=data).add_errback(on_send_error,message=data)
    print(f'sent the message {data} using sent method')
    print()
    sleep(0.5)
producer.flush()
producer.close()





























