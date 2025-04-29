from datetime import datetime, timedelta
from time import time
import faust
app=faust.App('demo-transactions',broker='localhost:9092',topic_partitions=1)

class withdrawals_data(faust.Record,serializer='json'):
    car_id:int
    car_name:str
    car_speed:int
    capture_time:int

input_topic=app.topic('car_speed',value_type=withdrawals_data)
car_speed_save_table=app.Table("car_speed_counter1",default=int).tumbling(1)

@app.agent(input_topic)
async def processor(stream):
    async for i in stream:
        print(i)
        car_speed_save_table['total']+=i.car_speed
        print("current total: ",car_speed_save_table['total'].value())
