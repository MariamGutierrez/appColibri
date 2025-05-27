from flask import Blueprint, render_template
from project.db import get_db
import psycopg2

noticias_bp = Blueprint('noticias', __name__)

@noticias_bp.route("/noticias")
def lista_noticias():
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT 
            n.id_noticia,
            n.titulo,
            n.contenido,
            f.titulo_fuente,
            f.link_fuente,
            r.nombre_region
        FROM Noticias_ambientales n
        LEFT JOIN Fuentes f ON n.id_fuentes = f.id_fuentes
        LEFT JOIN Regiones r ON n.id_region = r.id_region
        ORDER BY n.id_noticia DESC
    """)
    noticias = cur.fetchall()
    # Opcional: obtener los nombres de las columnas para usar con dicts
    colnames = [desc[0] for desc in cur.description]
    noticias = [dict(zip(colnames, row)) for row in noticias]
    cur.close()
    return render_template("noticias_feed.html", noticias=noticias)