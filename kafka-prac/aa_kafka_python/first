from kafka import KafkaConsumer
import mysql.connector

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
        insert_query = "INSERT INTO kafkaconsumer (batchid, deptname, salary) VALUES (DEFAULT, %s, %s)"
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
            deptname, salary = data[0], int(data[1])  # Assuming the structure of data
            save_to_mysql([(deptname, salary)])

    except KeyboardInterrupt:
        pass

    finally:
        consumer.close()

if __name__ == "__main__":
    consume_and_insert()
