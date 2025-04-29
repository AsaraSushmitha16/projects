from confluent_kafka import Producer
producer=Producer({'bootstrap.servers':'localhost:9092,localhost:9093, localhost:9094'})
topic_name='hello_world1'
parti=7
messages=['message1', 'message2', 'message3','message4', 'message5', 'message6','message7', 'message8', 'message9','message10', 'message11', 'message12']  # Add more messages as needed
for index,message in enumerate(messages):
    partition=index%parti
    producer.produce(topic=topic_name,value=message,partition=partition)
producer.flush()