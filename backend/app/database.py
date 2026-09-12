"""
Database connection and session management.
Uses SQLAlchemy with pyodbc to connect to Microsoft SQL Server.
"""

from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = URL.create(
    "mssql+pyodbc",
    host=r"localhost\SQLEXPRESS",
    database="FootballIndustryDB",
    query={
        "driver": "ODBC Driver 17 for SQL Server",
        "trusted_connection": "yes",
    },
)

engine = create_engine(
    DATABASE_URL,
    fast_executemany=True,
    pool_pre_ping=True,
    pool_recycle=1800,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()


def get_db():
    """FastAPI dependency that yields a database session and always closes it."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()