import faust
app=faust.App('data-streaming234',broker='localhost:9092',topic_partitions=3)

class syntaxforjson(faust.Record,serializer='json'):
    user_id:int
    country:str
    amount:int
topic=app.topic('hello_world1',value_type=syntaxforjson)
count_wise_withdrawals_table=app.Table('count_wise_withdrawals1234',default=int)

@app.agent(topic)
async def processor(stream):
    async for i in stream.group_by(syntaxforjson.country):
        print(i)
        count_wise_withdrawals_table[i.country]=count_wise_withdrawals_table[i.country]+1
        print(count_wise_withdrawals_table.as_ansitable(title='Count Tabled'))

