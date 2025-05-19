from importlib.metadata import files
from flask import Flask, jsonify, request, render_template, redirect, url_for, session, flash
from db import get_db, close_db
from werkzeug.security import generate_password_hash, check_password_hash
from controllers.clientes import usuarios_bp
from db import get_db
import re
from authentication import blueprint as authentication_blueprint
import random
import os
from werkzeug.utils import secure_filename
import cloudinary
import cloudinary.uploader
import random
import string
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

load_dotenv()
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
            # 1. Buscar en empleados
            cur.execute("""
                SELECT e.id_empleado, e.id_rol, h.contrasena_hash, 'empleado' AS tipo
                FROM empleados e
                JOIN historial_contrasenas h ON e.id_empleado = h.id_empleado
                WHERE e.correo = %s
                ORDER BY h.fecha_registro DESC
                LIMIT 1
            """, (correo,))
            user = cur.fetchone()

            # 2. Si no está en empleados, buscar en clientes
            if not user:
                cur.execute("""
                    SELECT c.id_usuario, c.rol, h.contrasena_hash, 'cliente' AS tipo
                    FROM cliente c
                    JOIN historial_contrasenas h ON c.id_usuario = h.id_usuario
                    WHERE c.correo = %s
                    ORDER BY h.fecha_registro DESC
                    LIMIT 1
                """, (correo,))
                user = cur.fetchone()


        if user and check_password_hash(user[2], password):
            session["user_id"] = user[0]
            session["user_role"] = user[1]
            session["user_type"] = user[3]  # 'empleado' o 'cliente'


            role = int(user[1])  # Asegura que sea int
            session["user_role"] = role
            # Redirección basada en rol (misma lógica del registro)
            if role == 1:
                return redirect(url_for("user_dashboard"))
            elif role == 2:
                return redirect(url_for("biologo_dashboard"))
            elif role == 3:
                return redirect(url_for("moderador_index"))
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
    if (
        "user_role" in session 
        and session["user_role"] == 1
        and session.get("user_type") == "cliente"
    ):
        return render_template("user_index.html")
    return redirect(url_for("login_page"))

@app.route("/perfil")
def perfil_usuario():
    if "user_id" not in session:
        return redirect(url_for("login_page"))

    db = get_db()
    id_usuario = session["user_id"]

    with db.cursor() as cur:
        # Datos del usuario
        cur.execute("SELECT nombre, correo FROM cliente WHERE id_usuario = %s", (id_usuario,))
        usuario = cur.fetchone()

        # Avistamientos
        cur.execute("""
            SELECT 
                a.descripcion,
                a.fecha_avistamiento,
                e.nombre_comun,
                ta.nombre_tipo_alerta
            FROM avistamientos a
            JOIN especies e ON a.id_especie = e.id_especie
            LEFT JOIN alertas al ON a.alerta_id = al.id_alerta
            LEFT JOIN tipos_alertas ta ON al.id_tipo_alerta = ta.id_tipo_alerta
            WHERE a.id_usuario = %s
            ORDER BY a.fecha_avistamiento DESC
        """, (id_usuario,))
        avistamientos = cur.fetchall()

        # Reportes
        cur.execute("""
            SELECT 
                r.descripcion,
                r.fecha_reporte,
                tr.nombre_tipo_reporte,
                ta.nombre_tipo_alerta
            FROM reportes r
            JOIN tipos_reportes tr ON r.id_tipo_reporte = tr.id_tipo_reporte
            LEFT JOIN alertas al ON r.id_alerta = al.id_alerta
            LEFT JOIN tipos_alertas ta ON al.id_tipo_alerta = ta.id_tipo_alerta
            WHERE r.id_usuario = %s
            ORDER BY r.fecha_reporte DESC
        """, (id_usuario,))
        reportes = cur.fetchall()

    return render_template("perfil.html", usuario=usuario, avistamientos=avistamientos, reportes=reportes)


@app.route("/moderador/index")
def moderador_index():
    return render_template("moderador_index.html")

@app.route("/moderador/avistamientos")
def admin_avistamientos():
    return render_template("AR_admin.html")

@app.route("/moderador/noticias")
def admin_noticias():
    return render_template("noticias_pub.html")

@app.route("/moderador/usuarios")
def admin_usuarios():
    return render_template("users_dash.html")

@app.route("/moderador/pqrs")
def admin_pqrs():
    return render_template("pqrs_res.html")



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
        cur.execute("SELECT 1 FROM empleados WHERE correo = %s", (email,))
        exists = cur.fetchone() is not None
    return jsonify({"exists": exists})

@app.route("/check_username")
def check_username():
    username = request.args.get("username")
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT 1 FROM empleados WHERE nombre = %s", (username,))
        exists = cur.fetchone() is not None
    return jsonify({"exists": exists})

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        msg = None  # Inicializar el mensaje como None
        username = request.form.get("username")
        lastname = request.form.get("lastname")
        email = request.form.get("email")
        role = "1"
        password = request.form.get("password")
        confirm_password = request.form.get("confirm_password")

        if not all([username, lastname, email, role, password, confirm_password]):                        # Reemplaza la validación actual con esta
            missing_fields = []
            if not username:
                missing_fields.append("Nombre de usuario")
            if not lastname:
                missing_fields.append("Apellido")
            if not email:
                missing_fields.append("Correo electrónico")
            if not password:
                missing_fields.append("Contraseña")
            if not confirm_password:
                missing_fields.append("Confirmación de contraseña")
            
            if missing_fields:
                msg = f"Campos obligatorios faltantes: {', '.join(missing_fields)}"
            else:
                # Continuar con las demás validaciones
                if password != confirm_password:
                    msg = "Las contraseñas no coinciden"
                # ... resto del código ...
        elif password != confirm_password:
            msg = "Las contraseñas no coinciden"
        elif len(password) < 8 or not re.search(r"[A-Z]", password) or not re.search(r"[a-z]", password) or not re.search(r"\d", password) or not re.search(r"[\W_]", password):
            msg = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula, un número y un símbolo."
        else:
            db = get_db()
            with db.cursor() as cur:
                if int(role) == 1:
                    # Registrar en tabla cliente
                    cur.execute("SELECT 1 FROM cliente WHERE correo = %s", (email,))
                    if cur.fetchone():
                        msg = "El correo ya está registrado"
                    else:
                        cur.execute("SELECT 1 FROM cliente WHERE nombre = %s", (username,))
                        if cur.fetchone():
                            msg = "El nombre de usuario ya está en uso"
                        else:
                            hashed_password = generate_password_hash(password)

                            cur.execute("""
                                INSERT INTO cliente (nombre, apellido1, correo, rol)
                                VALUES (%s, %s, %s, %s)
                                RETURNING id_usuario
                            """, (username, lastname, email, role))
                            user_id = cur.fetchone()[0]

                            cur.execute("""
                                INSERT INTO historial_contrasenas (id_usuario, contrasena_hash)
                                VALUES (%s, %s)
                            """, (user_id, hashed_password))
                            db.commit()

                            session["user_id"] = user_id
                            session["user_role"] = int(role)
                            session["user_type"] = "cliente"
                            return redirect(url_for("user_dashboard"))

                else:
                    # Registrar en empleados
                    cur.execute("SELECT 1 FROM empleados WHERE correo = %s", (email,))
                    if cur.fetchone():
                        msg = "El correo ya está registrado"
                    else:
                        cur.execute("SELECT 1 FROM empleados WHERE nombre = %s", (username,))
                        if cur.fetchone():
                            msg = "El nombre de usuario ya está en uso"
                        else:
                            hashed_password = generate_password_hash(password)

                            cur.execute("""
                                INSERT INTO empleados (nombre, apellido1, correo, id_rol)
                                VALUES (%s, %s, %s, %s)
                                RETURNING id_empleado
                            """, (username, lastname, email, role))
                            user_id = cur.fetchone()[0]

                            cur.execute("""
                                INSERT INTO historial_contrasenas (id_empleado, contrasena_hash)
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
@app.route("/clientes")
def get_usuarios():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM empleados;")
        clientes = cur.fetchall()
    return jsonify(clientes)

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
        files = request.files.getlist('fotos')

        if not all([id_usuario, id_tipo_reporte, descripcion, direccion, files]) or len(files) == 0:
            with db.cursor() as cur:
                cur.execute("SELECT id_tipo_reporte, nombre_tipo_reporte FROM tipos_reportes")
                tipos_reporte = cur.fetchall()
            return render_template(
                "page-contact-us.html",
                msg="Todos los campos obligatorios deben ser completados",
                tipos_reporte=tipos_reporte
            )

        for file in files:
            if file and allowed_file(file.filename):
                upload_result = cloudinary.uploader.upload(file)
                uploaded_urls.append(upload_result['secure_url'])
            else:
                with db.cursor() as cur:
                    cur.execute("SELECT id_tipo_reporte, nombre_tipo_reporte FROM tipos_reportes")
                    tipos_reporte = cur.fetchall()
                return render_template(
                    "page-contact-us.html",
                    msg="Tipo de archivo no permitido. Solo PNG o JPG.",
                    tipos_reporte=tipos_reporte
                )

        try:
            with db.cursor() as cur:
                # Buscar el tipo de alerta correspondiente
                cur.execute("""
                    SELECT id_tipo_alerta FROM tipos_alertas WHERE nombre_tipo_alerta = %s
                """, ("en_revision_reporte",))
                tipo_alerta = cur.fetchone()

                if not tipo_alerta:
                    raise Exception("Tipo de alerta 'en_revision_reporte' no existe")

                id_tipo_alerta = tipo_alerta[0]

                # Crear la alerta y obtener su id
                cur.execute("""
                    INSERT INTO alertas (id_tipo_alerta, fecha_alerta)
                    VALUES (%s, NOW())
                    RETURNING id_alerta
                """, (id_tipo_alerta,))
                id_alerta = cur.fetchone()[0]

                # Insertar los reportes con imágenes
                for foto_url in uploaded_urls:
                    cur.execute("""
                        INSERT INTO reportes (id_usuario, id_tipo_reporte, descripcion, fecha_reporte, foto_url, id_alerta, direccion)
                        VALUES (%s, %s, %s, NOW(), %s, %s, %s)
                    """, (id_usuario, id_tipo_reporte, descripcion, foto_url, id_alerta, direccion))

            db.commit()

            # ✅ Aquí agregamos el return que faltaba
            with db.cursor() as cur:
                cur.execute("SELECT id_tipo_reporte, nombre_tipo_reporte FROM tipos_reportes")
                tipos_reporte = cur.fetchall()
            return render_template("page-contact-us.html", msg="Reporte enviado con éxito", tipos_reporte=tipos_reporte)

        except Exception as e:
            db.rollback()
            return render_template("page-contact-us.html", msg=f"Error al guardar el reporte: {e}")

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
            # Obtener reportes
            cur.execute("""
                SELECT 
                    r.id_reporte,
                    tr.nombre_tipo_reporte,
                    r.descripcion,
                    r.fecha_reporte,
                    r.foto_url,
                    c.nombre,
                    ta.nombre_tipo_alerta
                FROM reportes r
                JOIN tipos_reportes tr ON r.id_tipo_reporte = tr.id_tipo_reporte
                JOIN cliente c ON r.id_usuario = c.id_usuario
                LEFT JOIN alertas a ON r.id_alerta = a.id_alerta
                LEFT JOIN tipos_alertas ta ON a.id_tipo_alerta = ta.id_tipo_alerta
            """)
            reportes = cur.fetchall()

            # Obtener avistamientos
            cur.execute("""
                SELECT 
                    a.id_avistamiento,
                    e.nombre_comun,
                    a.descripcion,
                    a.fecha_avistamiento,
                    a.foto_url,
                    c.nombre,
                    ta.nombre_tipo_alerta
                FROM avistamientos a
                JOIN especies e ON a.id_especie = e.id_especie
                JOIN cliente c ON a.id_usuario = c.id_usuario
                LEFT JOIN alertas al ON a.alerta_id = al.id_alerta
                LEFT JOIN tipos_alertas ta ON al.id_tipo_alerta = ta.id_tipo_alerta
            """)
            avistamientos = cur.fetchall()

        return render_template("biologo_dashboard.html", reportes=reportes, avistamientos=avistamientos)
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
            SELECT 
                r.id_reporte,               -- 0
                tr.nombre_tipo_reporte,    -- 1
                r.descripcion,             -- 2
                r.fecha_reporte,           -- 3
                r.foto_url,                -- 4
                c.nombre,                  -- 5 (nombre del cliente)
                ta.nombre_tipo_alerta      -- 6 ← ESTO muestra el estado legible
            FROM reportes r
            JOIN tipos_reportes tr ON r.id_tipo_reporte = tr.id_tipo_reporte
            JOIN cliente c ON r.id_usuario = c.id_usuario
            LEFT JOIN alertas a ON r.id_alerta = a.id_alerta
            LEFT JOIN tipos_alertas ta ON a.id_tipo_alerta = ta.id_tipo_alerta
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

    if accion not in ["aprobado", "rechazo"]:
        return "Acción no válida", 400

    nombre_alerta = f"{accion}_reporte"  # genera: 'aprobado_reporte' o 'rechazo_reporte'

    try:
        with db.cursor() as cur:
            # 1. Obtener el id del tipo de alerta
            cur.execute("""
                SELECT id_tipo_alerta FROM tipos_alertas WHERE nombre_tipo_alerta = %s
            """, (nombre_alerta,))
            resultado_alerta = cur.fetchone()
            if not resultado_alerta:
                return f"No se encontró el tipo de alerta '{nombre_alerta}'", 500

            id_tipo_alerta = resultado_alerta[0]

            # 2. Crear la alerta y obtener su id
            cur.execute("""
                INSERT INTO alertas (id_tipo_alerta, fecha_alerta)
                VALUES (%s, NOW())
                RETURNING id_alerta
            """, (id_tipo_alerta,))
            id_alerta = cur.fetchone()[0]

            # 3. Asignar esa alerta al reporte
            cur.execute("""
                UPDATE reportes
                SET id_alerta = %s
                WHERE id_reporte = %s
            """, (id_alerta, id_reporte))

        db.commit()
    except Exception as e:
        db.rollback()
        return f"Error al procesar la validación del reporte: {e}", 500

    return redirect(url_for("biologo_dashboard"))

@app.route("/user/avistamiento", methods=["GET", "POST"])
def avistamiento():
    db = get_db()
    uploaded_urls = []

    if request.method == "POST":
        id_usuario = session.get("user_id")
        id_especie_str = request.form.get("id_especie")
        id_especie = int(id_especie_str) if id_especie_str and id_especie_str.isdigit() else None
        descripcion = request.form.get("descripcion")
        direccion = request.form.get("direccion")
        files = request.files.getlist('fotos')
        def parse_float_or_none(value):
            try:
                return float(value)
            except (TypeError, ValueError):
                return None

        latitud = parse_float_or_none(request.form.get("latitud"))
        longitud = parse_float_or_none(request.form.get("longitud"))


        if not id_usuario or not id_especie or not descripcion or not direccion or not files or len(files) == 0:
            with db.cursor() as cur:
                cur.execute("SELECT id_especie, nombre_comun FROM especies")
                tipos_especie = cur.fetchall()
            return render_template(
                "avistamiento.html",
                msg="Todos los campos obligatorios deben ser completados",
                tipos_especie=tipos_especie
            )

        for file in files:
            if file and allowed_file(file.filename):
                upload_result = cloudinary.uploader.upload(file)
                uploaded_urls.append(upload_result['secure_url'])
            else:
                with db.cursor() as cur:
                    cur.execute("SELECT id_especie, nombre_comun FROM especies")
                    tipos_especie = cur.fetchall()
                return render_template(
                    "avistamiento.html",
                    msg="Tipo de archivo no permitido. Solo PNG o JPG.",
                    tipos_especie=tipos_especie
                )

        try:
            with db.cursor() as cur:
                # Crear alerta en estado 'en_revision_avistamiento'
                cur.execute("SELECT id_tipo_alerta FROM tipos_alertas WHERE nombre_tipo_alerta = %s", ("en_revision_avistamiento",))
                tipo_alerta = cur.fetchone()
                if not tipo_alerta:
                    raise Exception("Tipo de alerta 'en_revision_avistamiento' no existe")
                id_tipo_alerta = tipo_alerta[0]

                cur.execute("""
                    INSERT INTO alertas (id_tipo_alerta, fecha_alerta)
                    VALUES (%s, NOW())
                    RETURNING id_alerta
                """, (id_tipo_alerta,))
                id_alerta = cur.fetchone()[0]

                # Insertar todos los avistamientos
                for foto_url in uploaded_urls:
                    cur.execute("""
                        INSERT INTO avistamientos (id_usuario, id_especie, descripcion, fecha_avistamiento, foto_url, alerta_id, ubicacion, latitud, longitud)
                        VALUES (%s, %s, %s, NOW(), %s, %s, %s, %s, %s)
                    """, (id_usuario, id_especie, descripcion, foto_url, id_alerta, direccion, latitud, longitud))

            db.commit()

            # ✅ Redirige si todo fue exitoso
            return redirect(url_for("mis_avistamientos_aprobados"))

        except Exception as e:
            db.rollback()
            with db.cursor() as cur:
                cur.execute("SELECT id_especie, nombre_comun FROM especies")
                tipos_especie = cur.fetchall()
            return render_template(
                "avistamiento.html",
                msg=f"Error al guardar el avistamiento: {e}",
                tipos_especie=tipos_especie
            )

    # GET
    with db.cursor() as cur:
        cur.execute("SELECT id_especie, nombre_comun FROM especies")
        tipos_especie = cur.fetchall()
    return render_template("avistamiento.html", tipos_especie=tipos_especie)


@app.route("/editar_avistamiento/<int:id_avistamiento>", methods=["GET", "POST"])
def editar_avistamiento(id_avistamiento):
    if "user_role" not in session or session["user_role"] != 2:
        return redirect(url_for("login_page"))

    db = get_db()

    if request.method == "POST":
        descripcion = request.form.get("descripcion")
        foto_url = request.form.get("foto_url")
        id_especie = request.form.get("id_especie")

        with db.cursor() as cur:
            cur.execute("""
                UPDATE avistamientos
                SET descripcion = %s,
                    foto_url = %s,
                    id_especie = %s
                WHERE id_avistamiento = %s
            """, (descripcion, foto_url, id_especie, id_avistamiento))
            db.commit()
        return redirect(url_for("biologo_dashboard"))

    with db.cursor() as cur:
        cur.execute("""
            SELECT a.descripcion, a.foto_url, e.nombre_comun, a.id_especie
            FROM avistamientos a
            JOIN especies e ON a.id_especie = e.id_especie
            WHERE id_avistamiento = %s
        """, (id_avistamiento,))
        avistamiento = cur.fetchone()

        cur.execute("SELECT id_especie, nombre_comun FROM especies")
        especies = cur.fetchall()

    return render_template("editar_avistamiento.html", avistamiento=avistamiento, especies=especies)

@app.route("/validar_avistamiento/<int:id_avistamiento>/<accion>", methods=["POST"])
def validar_avistamiento(id_avistamiento, accion):
    if "user_role" not in session or session["user_role"] != 2:
        return redirect(url_for("login_page"))

    db = get_db()

    if accion not in ["aprovado", "rechazo"]:
        return "Acción no válida", 400

    nombre_alerta = f"{accion}_avistamiento"

    try:
        with db.cursor() as cur:
            cur.execute("SELECT id_tipo_alerta FROM tipos_alertas WHERE nombre_tipo_alerta = %s", (nombre_alerta,))
            resultado_alerta = cur.fetchone()
            if not resultado_alerta:
                return f"No se encontró el tipo de alerta '{nombre_alerta}'", 500

            id_tipo_alerta = resultado_alerta[0]

            cur.execute("""
                INSERT INTO alertas (id_tipo_alerta, fecha_alerta)
                VALUES (%s, NOW())
                RETURNING id_alerta
            """, (id_tipo_alerta,))
            id_alerta = cur.fetchone()[0]

            cur.execute("""
                UPDATE avistamientos
                SET alerta_id = %s
                WHERE id_avistamiento = %s
            """, (id_alerta, id_avistamiento))

        db.commit()
    except Exception as e:
        db.rollback()
        return f"Error al validar avistamiento: {e}", 500

    return redirect(url_for("biologo_dashboard"))

@app.route("/mis_avistamientos_aprobados")
def mis_avistamientos_aprobados():
    if "user_id" not in session:
        return redirect(url_for("login_page"))

    db = get_db()
    id_usuario = session["user_id"]

    with db.cursor() as cur:
        cur.execute("""
            SELECT 
                a.descripcion,
                a.ubicacion,
                a.latitud,
                a.longitud,
                e.nombre_comun,
                a.foto_url,
                a.fecha_avistamiento
            FROM avistamientos a
            JOIN especies e ON a.id_especie = e.id_especie
            LEFT JOIN alertas al ON a.alerta_id = al.id_alerta
            LEFT JOIN tipos_alertas ta ON al.id_tipo_alerta = ta.id_tipo_alerta
            WHERE a.id_usuario = %s AND ta.nombre_tipo_alerta = 'aprovado_avistamiento'
        """, (id_usuario,))
        avistamientos = cur.fetchall()

    return render_template("mis_avistamientos.html", avistamientos=avistamientos)

def generate_secure_password(length=8):
    # Asegurar que incluye al menos uno de cada tipo
    lowercase = random.choice(string.ascii_lowercase)
    uppercase = random.choice(string.ascii_uppercase)
    digits = random.choice(string.digits)
    special = random.choice("!@#$%^&*()-_=+[]{}|;:,.<>?")
    
    # Generar el resto de caracteres aleatorios
    remaining_length = length - 4  # restar los 4 caracteres ya seleccionados
    all_chars = string.ascii_letters + string.digits + "!@#$%^&*()-_=+[]{}|;:,.<>?"
    remaining_chars = ''.join(random.choice(all_chars) for _ in range(remaining_length))
    
    # Combinar y mezclar todos los caracteres
    password_chars = lowercase + uppercase + digits + special + remaining_chars
    password_list = list(password_chars)
    random.shuffle(password_list)
    
    return ''.join(password_list)

def send_password_reset_email(recipient_email, new_password):
    sender_email = os.getenv("EMAIL_SENDER")
    sender_password = os.getenv("EMAIL_PASSWORD")
    
    # Si no se configuraron las variables de entorno, usar valores por defecto para desarrollo
    if not sender_email or not sender_password:
        print("ADVERTENCIA: Variables de entorno EMAIL_SENDER o EMAIL_PASSWORD no configuradas.")
        print("Configure estas variables en el archivo .env para el envío real de correos.")
        return False
    
    # Crear mensaje
    message = MIMEMultipart("alternative")
    message["Subject"] = "Recuperación de contraseña - Colibrí"
    message["From"] = sender_email
    message["To"] = recipient_email
    
    # Contenido HTML del correo
    html = f"""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; line-height: 1.6;">
        <div style="background-color: #f8f9fa; border-radius: 10px; padding: 20px; border-top: 4px solid #5e72e4;">
          <h2 style="color: #5e72e4; margin-top: 0;">Recuperación de contraseña</h2>
          
          <p>Estimado usuario de Colibrí,</p>
          
          <p>Hemos recibido una solicitud para restablecer tu contraseña.</p>
          
          <p>Tu nueva contraseña temporal es:</p>
                    <p>Tu nueva contraseña temporal es:</p>
          
          <div style="background-color: #f0f2f5; padding: 15px; border-radius: 5px; margin: 20px 0; text-align: center; font-family: monospace; font-size: 18px; letter-spacing: 1px;">
            {new_password}
          </div>
          
          <p><strong>Importante:</strong> Por seguridad, te recomendamos cambiar esta contraseña temporal después de iniciar sesión.</p>
          
          <p>Si no solicitaste este cambio, por favor contacta a soporte técnico inmediatamente.</p>
          
          <p>Saludos,<br>El equipo de Colibrí</p>
        </div>
        <div style="text-align: center; color: #6c757d; font-size: 12px; margin-top: 20px;">
          <p>Este es un correo automático, por favor no respondas a este mensaje.</p>
        </div>
      </body>
    </html>
    """
    
    # Adjuntar contenido HTML
    part = MIMEText(html, "html")
    message.attach(part)
    # Enviar correo
    try:
        server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
        server.login(sender_email, sender_password)
        server.sendmail(sender_email, recipient_email, message.as_string())
        server.quit()
        return True
    except Exception as e:
        print(f"Error al enviar correo: {str(e)}")
        return False

@app.route("/recuperarpswd", methods=["GET", "POST"])
def recuperar_password():
    msg = None
    if request.method == "POST":
        correo = request.form.get("correo")
        
        if not correo:
            msg = "Por favor, ingresa tu correo electrónico."
            return render_template("recuperar_password.html", msg=msg)
        
        db = get_db()
        try:
            # Verificar si el correo existe en la base de datos
            with db.cursor() as cur:
                # Buscar en tabla cliente
                cur.execute("SELECT id_usuario FROM cliente WHERE correo = %s", (correo,))
                user = cur.fetchone()
                user_type = "cliente"
                id_field = "id_usuario"
                
                # Si no se encuentra en cliente, buscar en empleados
                if not user:
                    msg = "No se encontró ninguna cuenta asociada a este correo electrónico."
                    return render_template("recuperar_password.html", msg=msg)
                
                # Generar nueva contraseña aleatoria
                new_password = generate_secure_password(10)  # 10 caracteres para mayor seguridad
                hashed_password = generate_password_hash(new_password)
                user_id = user[0]
                
                # Actualizar la contraseña en la base de datos
                if user_type == "cliente":
                    cur.execute("""
                        INSERT INTO historial_contrasenas (id_usuario, contrasena_hash)
                        VALUES (%s, %s)
                    """, (user_id, hashed_password))
                else:
                    cur.execute("""
                        INSERT INTO historial_contrasenas (id_empleado, contrasena_hash)
                        VALUES (%s, %s)
                    """, (user_id, hashed_password))

            # Enviar correo con la nueva contraseña
            email_sent = send_password_reset_email(correo, new_password)
            
            if not email_sent:
                db.rollback()
                msg = "No se pudo enviar el correo de recuperación. Por favor, intenta de nuevo más tarde."
                return render_template("recuperar_password.html", msg=msg)
            
            db.commit()
            msg = "Se ha enviado una nueva contraseña a tu correo electrónico. Por favor, revisa tu bandeja de entrada."
            return render_template("login.html", msg=msg)
        except Exception as e:
            db.rollback()
            msg = f"Error durante el proceso de recuperación: {str(e)}"
            return render_template("recuperar_password.html", msg=msg)
    return render_template("recuperar_password.html", msg=msg)
    

@app.teardown_appcontext
def teardown(exception):
    close_db()

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)), debug=True)



