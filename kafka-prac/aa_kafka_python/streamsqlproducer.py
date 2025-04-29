import faust

app = faust.App('demo-streaming', broker='localhost:9092')

class ComplexStructure(faust.Record, serializer='json'):
    subject: str
    marks: str

input_topic = app.topic('hello_world', value_type=ComplexStructure, value_serializer='json')
output_topic = app.topic('kafkaTopic', value_type=ComplexStructure, value_serializer='json')

@app.agent(input_topic)
async def processor(stream):
    async for message in stream:
        print(f"Received {message}")
        # If you want to manipulate the data, you can do so here
        # For example, convert to dict:
        output_tf = {"subject": message.subject, "marks": message.marks}
        print(output_tf)
        await output_topic.send(value=output_tf)

if __name__ == "__main__":
    app.main()
