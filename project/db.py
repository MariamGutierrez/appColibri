import os
import psycopg2
from flask import g
from dotenv import load_dotenv

load_dotenv(override=True)  # Carga .env desde el raíz del proyecto

print("Valor desde .env:", repr(os.getenv("DATABASE_URL")))
print("Fuente probable:", "Sistema" if os.getenv("DATABASE_URL").startswith("postgresql://dottoooo") else "Archivo .env")

def get_db():
    print("Valor final de DATABASE_URL:", repr(os.environ.get("DATABASE_URL")))
    db_url = os.environ.get("DATABASE_URL")
    print("Conectando a:", db_url)  # DEBUG
    return psycopg2.connect(db_url)

def close_db(e=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


