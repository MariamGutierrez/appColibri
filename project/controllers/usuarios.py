from flask import Blueprint, jsonify
from db import get_db

usuarios_bp = Blueprint("usuarios", __name__)

@usuarios_bp.route("/usuarios")
def get_usuarios():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM usuarios;")
        usuarios = cur.fetchall()
    return jsonify(usuarios)