import asyncio
from dataclasses import asdict, dataclass, field
import json
import random
from confluent_kafka import avro, Consumer, Producer
from confluent_kafka.avro import AvroConsumer, AvroProducer, CachedSchemaRegistryClient
from faker import Faker
faker = Faker()
topic_name = 'hello_world'
SCHEMA_REGISTRY_URL = "http://localhost:8081"
BROKER_URL = "PLAINTEXT://localhost:9092"
@dataclass
class Purchase:
    username: str = field(default_factory=faker.user_name)
    currency: str = field(default_factory=faker.currency_code)
    amount: int = field(default_factory=lambda: random.randint(100, 200000))

    schema = avro.loads(
        """{
        "type": "record",
        "namespace": "com.example.purchase",
        "name": "AvroFakePurchase",
        "fields": [
            {"name": "username", "type": "string"},
            {"name": "currency", "type": "string"},
            {"name": "amount", "type": "int"}
        ]
    }"""
    )
async def produce(topic_name):
    """Produces data into the Kafka Topic"""
    schema_registry = CachedSchemaRegistryClient({"url": SCHEMA_REGISTRY_URL})
    p = AvroProducer({"bootstrap.servers": BROKER_URL}, schema_registry=schema_registry)
    while True:
        p.produce(
                topic=topic_name,
                value=asdict(Purchase()),
                value_schema=Purchase.schema
        )
        await asyncio.sleep(1.0)
async def consume(topic_name):
    """Consumes data from the Kafka Topic"""
    schema_registry = CachedSchemaRegistryClient({"url": SCHEMA_REGISTRY_URL})
    c = AvroConsumer(
        {"bootstrap.servers": BROKER_URL, "group.id": "0"},
        schema_registry=schema_registry,
    )
    c.subscribe([topic_name])
    while True:
        message = c.poll(2.0)
        if message is None:
            print("no message received by consumer")
        elif message.error() is not None:
            print(f"error from consumer {message.error()}")
        else:
            try:
                print(message.value())
            except KeyError as e:
                print(f"Failed to unpack message {e}")
        await asyncio.sleep(2.0)
def main():
    """Checks for topic and creates the topic if it does not exist"""
    try:
        asyncio.run(produce_consume("hello_world"))
    except KeyboardInterrupt as e:
        print("shutting down")


async def produce_consume(topic_name):
    """Runs the Producer and Consumer tasks"""
    t1 = asyncio.create_task(produce(topic_name))
    t2 = asyncio.create_task(consume(topic_name))
    await t1
    await t2

if __name__ == "__main__":
    main()