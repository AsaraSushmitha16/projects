from confluent_kafka import Producer
from time import sleep
producer=Producer({'bootstrap.servers':'localhost:9092'})
topic_name='hello_world'
parti=1
#messages=['message1', 'message2', 'message3','message4', 'message5', 'message6','message7', 'message8', 'message9','message10', 'message11', 'message12']  # Add more messages as needed
for index in range(100):
    partition=index%parti
    index1=str(index)
    producer.produce(topic=topic_name,value=index1,partition=partition)
    sleep(0.5)
producer.flush()