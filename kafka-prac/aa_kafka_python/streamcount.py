import faust
app=faust.App('data-streaming1',broker='localhost:9092')

topic=app.topic('hello_world1',value_type=str,value_serializer='raw')
aged_table=app.Table('table_name',key_type=str,value_type=int,partitions=1,default=int)

@app.agent(topic)
async def processor(stream):
    async for i in stream:
        data_part=i.split()
        for j in data_part:
            aged_table[str(j)]=aged_table[str(j)]+1
            print(aged_table.as_ansitable(title='Count Tabled'))

