import faust
app=faust.App("demo-streaming",broker='localhost:9092')
class greetings(faust.Record,serializer='json'):
    name:str
    age:int


topic=app.topic('hello_world',value_type=greetings)
aged_table=app.Table("major-count",key_type=str,value_type=str,partitions=1,default=int)

@app.agent(topic)
async def processor(stream):
    async for i in stream:
        if (i.age>30):
            aged_table[str(i.name)]=i.age
            print(aged_table.as_ansitable(title='Aged Tabled'))

