from importlib.metadata import files
from flask import Flask, jsonify, request, render_template, redirect, url_for, session, flash
from db import get_db, close_db
from werkzeug.security import generate_password_hash, check_password_hash
from controllers.usuarios import usuarios_bp
from db import get_db
import re
from authentication import blueprint as authentication_blueprint
import random
import os
from werkzeug.utils import secure_filename
import cloudinary
import cloudinary.uploader

# Configurar Cloudinary
cloudinary.config( 
    cloud_name = "dhaneunlu", 
    api_key = "176747317263595", 
    api_secret = "6a959CR7AvrMfAL94jyUJ56jKU8", # Click 'View API Keys' above to copy your API secret
    secure=True
)

UPLOAD_FOLDER = 'static/uploads/'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}


app = Flask(__name__)
app.secret_key = 'clave_secreta_segura'  # Necesario para manejar sesiones

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Asegurar que la carpeta 'static/uploads' exista
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# Register the authentication blueprint
app.register_blueprint(authentication_blueprint)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/login", methods=["GET", "POST"])
def login_page():
    if request.method == "POST":
        correo = request.form.get("correo")
        password = request.form.get("password")

        db = get_db()
        with db.cursor() as cur:
            # Obtener el usuario con su hash de contraseña más reciente
            cur.execute("""
                SELECT u.id_usuario, u.id_rol, h.contrasena_hash
                FROM usuarios u
                JOIN Historial_contrasenas h ON u.id_usuario = h.id_usuario
                WHERE u.correo = %s
                ORDER BY h.fecha_registro DESC
                LIMIT 1
            """, (correo,))
            user = cur.fetchone()

        if user and check_password_hash(user[2], password):
            session["user_id"] = user[0]
            session["user_role"] = user[1]

            role = user[1]
            # Redirección basada en rol (misma lógica del registro)
            if role == 1:
                return redirect(url_for("user_dashboard"))
            elif role == 2:
                return redirect(url_for("biologo_dashboard"))
            elif role == 3:
                return redirect(url_for("moderator_dashboard"))
            elif role == 4:
                return redirect(url_for("ong_dashboard"))
            elif role == 5:
                return redirect(url_for("admin_dashboard"))
            else:
                return redirect(url_for("index"))

        return render_template("login.html", msg="Credenciales incorrectas")

    return render_template("login.html")

@app.route("/user")
def user_dashboard():
    if "user_role" in session and session["user_role"] == 1:
        return render_template("user_index.html")
    return redirect(url_for("login_page"))


@app.route("/moderador")
def moderator_dashboard():
    if "user_role" in session and session["user_role"] == 3:
        return "Bienvenido al panel de moderador"
    return redirect(url_for("login_page"))

@app.route("/ong")
def ong_dashboard():
    if "user_role" in session and session["user_role"] == 4:
        return "Bienvenido al panel de ONG"
    return redirect(url_for("login_page"))

@app.route("/admin")
def admin_dashboard():
    if "user_role" in session and session["user_role"] == 5:
        return "Bienvenido al panel de superusuario"
    return redirect(url_for("login_page"))


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login_page'))

@app.route("/check_email")
def check_email():
    email = request.args.get("email")
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT 1 FROM usuarios WHERE correo = %s", (email,))
        exists = cur.fetchone() is not None
    return jsonify({"exists": exists})

@app.route("/check_username")
def check_username():
    username = request.args.get("username")
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT 1 FROM usuarios WHERE nombre = %s", (username,))
        exists = cur.fetchone() is not None
    return jsonify({"exists": exists})

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        msg = None  # Inicializar el mensaje como None
        username = request.form.get("username")
        lastname = request.form.get("lastname")
        email = request.form.get("email")
        role = request.form.get("role")
        password = request.form.get("password")
        confirm_password = request.form.get("confirm_password")

        if not all([username, lastname, email, role, password, confirm_password]):
            msg = "Todos los campos son obligatorios"
        elif password != confirm_password:
            msg = "Las contraseñas no coinciden"
        elif len(password) < 8 or not re.search(r"[A-Z]", password) or not re.search(r"[a-z]", password) or not re.search(r"\d", password) or not re.search(r"[\W_]", password):
            msg = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula, un número y un símbolo."
        else:
            db = get_db()
            with db.cursor() as cur:
                cur.execute("SELECT 1 FROM usuarios WHERE correo = %s", (email,))
                if cur.fetchone():
                    msg = "El correo ya está registrado"
                else:
                    cur.execute("SELECT 1 FROM usuarios WHERE nombre = %s", (username,))
                    if cur.fetchone():
                        msg = "El nombre de usuario ya está en uso"
                    else:
                        hashed_password = generate_password_hash(password)

                        cur.execute("""
                            INSERT INTO usuarios (nombre, apellido1, correo, id_rol)
                            VALUES (%s, %s, %s, %s)
                            RETURNING id_usuario
                        """, (username, lastname, email, role))
                        user_id = cur.fetchone()[0]

                        cur.execute("""
                            INSERT INTO Historial_contrasenas (id_usuario, contrasena_hash)
                            VALUES (%s, %s)
                        """, (user_id, hashed_password))
                        db.commit()

                        session["user_id"] = user_id
                        session["user_role"] = int(role)
                        return redirect(url_for("ong_dashboard"))

        return render_template("register.html", msg=msg)

    return render_template("register.html")

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

@app.route("/user/reportar", methods=["GET", "POST"])
def reportar():
    db = get_db()
    uploaded_urls = []
    
    if request.method == "POST":
        id_usuario = session.get("user_id")
        id_tipo_reporte = request.form.get("id_tipo_reporte")
        descripcion = request.form.get("descripcion")
        direccion = request.form.get("direccion")
        id_alerta = random.randint(1000, 9999)

        # Manejar archivo
        file = request.files.getlist('foto')  # ahora recibimos 'foto'

        if not all([id_usuario, id_tipo_reporte, descripcion, direccion, file]):
            with db.cursor() as cur:
                cur.execute("SELECT id_tipo_reporte, nombre_tipo_reporte FROM tipos_reportes")
                tipos_reporte = cur.fetchall()
            return render_template("page-contact-us.html", msg="Todos los campos obligatorios deben ser completados", tipos_reporte=tipos_reporte)
        for file in files:
            if file and allowed_file(file.filename):
                upload_result = cloudinary.uploader.upload(file)
                uploaded_urls.append(upload_result['secure_url'])
        else:
            with db.cursor() as cur:
                cur.execute("SELECT id_tipo_reporte, nombre_tipo_reporte FROM tipos_reportes")
                tipos_reporte = cur.fetchall()
            return render_template("page-contact-us.html", msg="Tipo de archivo no permitido. Solo PNG o JPG.", tipos_reporte=tipos_reporte)

        # Insertar reporte en base de datos
        with db.cursor() as cur:
            cur.execute("""
                INSERT INTO Reportes (id_usuario, id_tipo_reporte, descripcion, fecha_reporte, foto_url, id_alerta, direccion)
                VALUES (%s, %s, %s, NOW(), %s, %s, %s)
            """, (id_usuario, id_tipo_reporte, descripcion, foto_url, id_alerta, direccion))
            db.commit()

        with db.cursor() as cur:
            cur.execute("SELECT id_tipo_reporte, nombre_tipo_reporte FROM tipos_reportes")
            tipos_reporte = cur.fetchall()

        return render_template("page-contact-us.html", msg="Reporte enviado con éxito", tipos_reporte=tipos_reporte)

    else:
        with db.cursor() as cur:
            cur.execute("SELECT id_tipo_reporte, nombre_tipo_reporte FROM tipos_reportes")
            tipos_reporte = cur.fetchall()
        return render_template("page-contact-us.html", tipos_reporte=tipos_reporte)

@app.route("/biologo")
def biologo_dashboard():
    if "user_role" in session and session["user_role"] == 2:
        db = get_db()
        with db.cursor() as cur:
            cur.execute("""
                SELECT 
                    r.id_reporte,               -- 0
                    tr.nombre_tipo_reporte,     -- 1
                    r.descripcion,              -- 2
                    r.fecha_reporte,             -- 3
                    r.foto_url,                  -- 4
                    u.nombre,            -- 5
                    r.estado_validacion          -- 6
                FROM reportes r
                JOIN tipos_reportes tr ON r.id_tipo_reporte = tr.id_tipo_reporte
                JOIN usuarios u ON r.id_usuario = u.id_usuario
            """)
            reportes = cur.fetchall()
        return render_template("biologo_dashboard.html", reportes=reportes)
    return redirect(url_for("login_page"))


@app.route("/editar_reporte/<int:id_reporte>", methods=["GET", "POST"])
def editar_reporte(id_reporte):
    if "user_role" not in session or session["user_role"] != 2:
        return redirect(url_for("login_page"))

    db = get_db()

    if request.method == "POST":
        descripcion = request.form.get("descripcion")
        foto_url = request.form.get("foto_url")
        id_tipo_reporte = request.form.get("id_tipo_reporte")  # Nuevo campo si quieres permitir cambiarlo también

        with db.cursor() as cur:
            cur.execute("""
                UPDATE reportes
                SET descripcion = %s,
                    foto_url = %s,
                    id_tipo_reporte = %s
                WHERE id_reporte = %s
            """, (descripcion, foto_url, id_tipo_reporte, id_reporte))
            db.commit()
        return redirect(url_for("biologo_dashboard"))

    # GET - obtener los datos actuales
    with db.cursor() as cur:
        cur.execute("""
            SELECT r.descripcion, r.foto_url, tr.nombre_tipo_reporte, r.fecha_reporte, r.id_tipo_reporte, u.nombre
            FROM reportes r
            JOIN tipos_reportes tr ON r.id_tipo_reporte = tr.id_tipo_reporte
            JOIN usuarios u ON r.id_usuario = u.id_usuario
            WHERE r.id_reporte = %s
        """, (id_reporte,))
        reporte = cur.fetchone()

        # Obtener tipos de reportes para permitir cambiarlo
        cur.execute("SELECT id_tipo_reporte, nombre_tipo_reporte FROM tipos_reportes")
        tipos_reportes = cur.fetchall()

    if not reporte:
        return "Reporte no encontrado", 404

    return render_template("editar_reporte.html", reporte=reporte, tipos_reportes=tipos_reportes)

@app.route("/validar_reporte/<int:id_reporte>/<accion>", methods=["POST"])
def validar_reporte(id_reporte, accion):
    if "user_role" not in session or session["user_role"] != 2:
        return redirect(url_for("login_page"))

    db = get_db()
    nuevo_estado = "pendiente"

    if accion == "aprobar":
        nuevo_estado = "aprobado"
    elif accion == "rechazar":
        nuevo_estado = "rechazado"
    else:
        return "Acción no válida", 400

    with db.cursor() as cur:
        cur.execute("""
            UPDATE reportes
            SET estado_validacion = %s
            WHERE id_reporte = %s
        """, (nuevo_estado, id_reporte))
        db.commit()

    return redirect(url_for("biologo_dashboard"))




@app.teardown_appcontext
def teardown(exception):
    close_db()

if __name__ == '__main__':
    import os
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))

