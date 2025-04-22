from flask import Flask, jsonify, request, render_template
from db import get_db, close_db

app = Flask(__name__)
@app.route("/")
def index():
    return render_template("index.html")

#### METODOS GET ####
######tienes que poner los que necesites ahi segun lo que vayas haciendo######
@app.route("/usuarios")
def get_usuarios():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM usuarios;")
        usuarios = cur.fetchall()
    return jsonify(usuarios)

@app.route("/pqrs")
def get_pqrs():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM pqrs;")
        datos = cur.fetchall()
    return jsonify(datos)
#### METODOS POST ####
######tienes que poner los que necesites ahi segun lo que vayas haciendo#######
@app.route("/pqrs", methods=["POST"])
def crear_pqrs():
    data = request.get_json()
    tipo = data["tipo"]
    descripcion = data["descripcion"]
    estado = data["estado"]
    usuario_id = data["usuario_id"]

    db = get_db()
    with db.cursor() as cur:
        cur.execute("""
            INSERT INTO pqrs (tipo, descripcion, estado, usuario_id)
            VALUES (%s, %s, %s, %s)
        """, (tipo, descripcion, estado, usuario_id))
        db.commit()
    return jsonify({"mensaje": "PQRS creada con éxito"}), 201

@app.teardown_appcontext
def teardown(exception):
    close_db()

if __name__ == '__main__':
    app.run(debug=True)
