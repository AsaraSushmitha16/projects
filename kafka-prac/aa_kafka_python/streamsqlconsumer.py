import faust
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Define SQLAlchemy engine and session
engine = create_engine('sqlite:///example.db')
Session = sessionmaker(bind=engine)
session = Session()

# Define SQLAlchemy base model
Base = declarative_base()

# Define SQLAlchemy model for a table in the database
class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    name = Column(String)
    age = Column(Integer)

# Define Faust app
app = faust.App('sql-app')

# Define Faust topic
topic = app.topic('hello_world')

# Define Faust agent
@app.agent(topic)
async def process_users(users):
    async for user in users:
        # Insert user into database using SQLAlchemy
        new_user = User(name=user['name'], age=user['age'])
        session.add(new_user)
        session.commit()

if __name__ == '__main__':
    app.main()
