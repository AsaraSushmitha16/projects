import faust
app=faust.App('data-streaming',broker='localhost:9092')
topic=app.topic('hello_world',value_type=str,value_serializer='raw')

@app.agent(topic)
async def processor(stream):
    async for i in stream:
        print(f"received {i}")