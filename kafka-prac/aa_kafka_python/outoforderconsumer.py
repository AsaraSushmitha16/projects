import faust
from datetime import datetime,timedelta
from time import time

CLEANUP_INTERVAL=60
WINDOW_EXPIRES=60

app=faust.App('car_speed_data',broker='localhost:9092',topic_partitions=1)
app.conf.table_cleanup_interval=CLEANUP_INTERVAL

class withdrawls_data(faust.Record,serializer='json'):
    car_id:int
    car_name:str
    car_speed:int
    capture_time:datetime

def window_processor(key,events):
    start_time=key[1][0]
    end_time=key[1][1]
    values=[event.car_speed for event in events]
    total_value=sum(values)
    print("total value between {} & {} is {}".format(start_time,end_time,total_value))


input_topic=app.topic('car_speed',value_type=withdrawls_data)

tumbling_table=app.Table('car_speed_counter_one',default=list,on_window_close=window_processor). \
    tumbling(1,expires=timedelta(seconds=WINDOW_EXPIRES)) \
    .relative_to_field((withdrawls_data.capture_time))


@app.agent(input_topic)
async def processor(stream):
    async for i in stream:
        print("---- ",tumbling_table['events'])
        value_list=tumbling_table['events'].value()
        value_list.append(i)
        tumbling_table['events']=value_list
        print(tumbling_table['events'].value())
