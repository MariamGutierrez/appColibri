import os
import psycopg
from flask import g
from urllib.parse import urlparse

def get_db():
    if "db" not in g:
        db_url = os.getenv("postgresql://postgres:GtsuuqKGwGlhmYFUZlEJWDMyXxPzhUfl@caboose.proxy.rlwy.net:14438/railway")
        if db_url is None:
            raise RuntimeError("DATABASE_URL no está definida")

        result = urlparse(db_url)
        g.db = psycopg.connect(
            dbname=result.path[1:],
            user=result.username,
            password=result.password,
            host=result.hostname,
            port=result.port,
            sslmode="require"  # Railway requiere conexión segura
        )
    return g.db

def close_db(e=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()

