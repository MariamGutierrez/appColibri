# db.py
import psycopg
from flask import g

# Configurá los datos según tu setup:
DB_CONFIG = {
    "dbname": "dottoooo",
    "user": "dottoooo",
    "password": "Kuyaminovio123",
    "host": "localhost",  # o la IP de tu servidor
    "port": 5432
}

def get_db():
    if "db" not in g:
        g.db = psycopg.connect(**DB_CONFIG)
    return g.db

def close_db(e=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()
