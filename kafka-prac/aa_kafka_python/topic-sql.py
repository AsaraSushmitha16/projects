from kafka import KafkaConsumer
import mysql.connector
import json
# Kafka consumer settings
kafka_bootstrap_servers = 'localhost:9092'
kafka_topic = 'kafkaTopic'

# MySQL connection settings
mysql_host = 'localhost'
mysql_database = 'first_db'
mysql_user = 'root'
mysql_password = 'dolly'

def connect_mysql():
    return mysql.connector.connect(
        host=mysql_host,
        database=mysql_database,
        user=mysql_user,
        password=mysql_password
    )

def save_to_mysql(data):
    try:
        connection = connect_mysql()
        cursor = connection.cursor()

        # Insert data into MySQL table
        insert_query = "INSERT INTO kafkaTopic (batchid, subject, marks) VALUES (DEFAULT, %s, %s)"
        cursor.executemany(insert_query, data)
        connection.commit()
        print("Data inserted into MySQL successfully")

    except mysql.connector.Error as error:
        print("Failed to insert data into MySQL table:", error)

    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def consume_and_insert():
    consumer = KafkaConsumer(
        kafka_topic,
        bootstrap_servers=kafka_bootstrap_servers,
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        group_id='my_consumer_group'
    )

    try:
        for message in consumer:
            data = message.value.decode('utf-8').split(',')  # Assuming data is comma-separated
            print("data is",data)
            json_string = ','.join(data)
            print(json_string)
            # Convert the JSON string to a JSON object
            json_object = json.loads(json_string)
            print(json_object)
            subject, marks = json_object["subject"], int(json_object["marks"])
            save_to_mysql([(subject, marks)])

    except KeyboardInterrupt:
        pass

    finally:
        consumer.close()

if __name__ == "__main__":
    consume_and_insert()
