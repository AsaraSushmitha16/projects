import faust
app=faust.App('demo-streaming',broker='localhost:9092')
class complex_structure(faust.Record,serializer='json'):
    from_name:str
    to_name:str

input_topic=app.topic('hello_world',value_type=complex_structure)

output_topic=app.topic('send_greetings',value_type=str,value_serializer='raw')
@app.agent(input_topic)
async def processor(stream):
    async for message in stream:
        print(f"received {message}")
        output_tf=(f'greetings from {message.from_name} to {message.to_name}')
        print(output_tf)
        await output_topic.send(value=output_tf)
