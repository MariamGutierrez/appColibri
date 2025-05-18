import os
import psycopg2
from flask import g
from dotenv import load_dotenv

load_dotenv()  # Carga .env desde el raíz del proyecto

def get_db():
    print("🌐 Conectando a:", os.environ.get("DATABASE_URL"))  # DEBUG
    return psycopg2.connect(os.environ["DATABASE_URL"])

def close_db(e=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


