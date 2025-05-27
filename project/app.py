from importlib.metadata import files
from flask import Flask, jsonify, request, render_template, redirect, url_for, session, flash
import re
from project.authentication import blueprint as authentication_blueprint
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
from datetime import datetime
import time
import os
from werkzeug.utils import secure_filename
from flask import request, jsonify
import uuid
import psycopg2.extras
from project.routes.noticias import noticias_bp
import sys
import os
from werkzeug.security import generate_password_hash, check_password_hash
from project.db import get_db, close_db


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
# Asegurar que la carpeta 'static/uploads' exista


# Registrar el blueprint de noticias
app.register_blueprint(noticias_bp)

# Configuración para subida de archivos
UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'static/uploads')
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
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

            # 2. Buscar en clientes si no fue encontrado
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

            # 3. Buscar en ONGs si no fue encontrado
            if not user:
                cur.execute("""
                    SELECT o.id_ong, o.rol, h.contrasena_hash, 'ong' AS tipo
                    FROM ong o
                    JOIN historial_contrasenas h ON o.id_ong = h.ong_id
                    WHERE o.email_ong = %s
                    ORDER BY h.fecha_registro DESC
                    LIMIT 1
                """, (correo,))
                user = cur.fetchone()

        if user and check_password_hash(user[2], password):
            session["user_id"] = user[0]
            session["user_role"] = user[1]
            session["user_type"] = user[3]  # 'empleado', 'cliente', 'ong'

            role = int(user[1]) if isinstance(user[1], (int, float, str)) and str(user[1]).isdigit() else user[1]

            session["user_role"] = role

            # Redirección según rol
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


@app.route("/")
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

    user_id = session["user_id"]
    db = get_db()
    with db.cursor() as cur:
        # Datos del usuario
        cur.execute("SELECT nombre, correo, apellido1 FROM cliente WHERE id_usuario = %s", (user_id,))
        usuario = cur.fetchone()

        # Avistamientos del usuario
        cur.execute("""
            SELECT a.descripcion, a.fecha_avistamiento, e.nombre_comun, ta.nombre_tipo_alerta
            FROM avistamientos a
            JOIN especies e ON a.id_especie = e.id_especie
            LEFT JOIN alertas al ON a.alerta_id = al.id_alerta
            LEFT JOIN tipos_alertas ta ON al.id_tipo_alerta = ta.id_tipo_alerta
            WHERE a.id_usuario = %s
        """, (user_id,))
        avistamientos = cur.fetchall()

        # Reportes del usuario
        cur.execute("""
            SELECT r.descripcion, r.fecha_reporte, tr.nombre_tipo_reporte, ta.nombre_tipo_alerta
            FROM reportes r
            JOIN tipos_reportes tr ON r.id_tipo_reporte = tr.id_tipo_reporte
            LEFT JOIN alertas al ON r.id_alerta = al.id_alerta
            LEFT JOIN tipos_alertas ta ON al.id_tipo_alerta = ta.id_tipo_alerta
            WHERE r.id_usuario = %s
        """, (user_id,))
        reportes = cur.fetchall()

        # ✅ PQRS abiertas para el usuario
        cur.execute("""
            SELECT id, tipo, descripcion
            FROM pqrs
            WHERE usuario_id = %s AND estado = 'inicio_proceso'
        """, (user_id,))
        pqrs_abiertas = cur.fetchall()

    return render_template(
        "perfil.html",
        usuario=usuario,
        avistamientos=avistamientos,
        reportes=reportes,
        pqrs_abiertas=pqrs_abiertas
    )



@app.route("/moderador/index")
def moderador_index():
    return render_template("moderador_index.html")

@app.route("/moderador/avistamientos")
def AR_admin():
    if "user_role" in session and session["user_role"] == 3:
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
        print("Reportes:", reportes)
        print("Avistamientos:", avistamientos)
        return render_template("AR_admin.html", reportes=reportes, avistamientos=avistamientos)
    return redirect(url_for("login_page"))

@app.route("/moderador/noticias")
def admin_noticias():
    return render_template("noticias_pub.html")

@app.route("/moderador/usuarios")
def gestionar_usuarios():
    if "user_role" in session and session["user_role"] == 3:
        db = get_db()
        with db.cursor() as cur:
            cur.execute("SELECT id_usuario, nombre, correo, rol, activo FROM cliente")
            usuarios = cur.fetchall()

            cur.execute("""
                SELECT e.id_empleado, e.nombre, e.correo, r.nombre_rol, e.activo
                FROM empleados e
                JOIN roles r ON e.id_rol = r.id_rol
            """)
            empleados = cur.fetchall()

            cur.execute("""
                SELECT id_ong, nombre_ong, contacto_ong, email_ong, activo FROM ong
            """)
            ongs = cur.fetchall()

        return render_template("users_dash.html", usuarios=usuarios, empleados=empleados, ongs=ongs)
    return redirect(url_for("login_page"))




@app.route("/eliminar_usuario/<int:id_usuario>", methods=["POST"])
def eliminar_usuario(id_usuario):
    if "user_role" in session and session["user_role"] == 3:
        db = get_db()
        with db.cursor() as cur:
            cur.execute("DELETE FROM reportes WHERE id_usuario = %s", (id_usuario,))
            cur.execute("DELETE FROM avistamientos WHERE id_usuario = %s", (id_usuario,))
            cur.execute("DELETE FROM cliente WHERE id_usuario = %s", (id_usuario,))
            db.commit()
        return redirect(url_for("gestionar_usuarios"))
    return redirect(url_for("login_page"))

@app.route("/eliminar_empleado/<int:id_empleado>", methods=["POST"])
def eliminar_empleado(id_empleado):
    if "user_role" in session and session["user_role"] == 3:
        db = get_db()
        with db.cursor() as cur:
            cur.execute("DELETE FROM empleados WHERE id_empleado = %s", (id_empleado,))
            db.commit()
        return redirect(url_for("gestionar_usuarios"))
    return redirect(url_for("login_page"))

@app.route("/eliminar_ong/<int:id_ong>", methods=["POST"])
def eliminar_ong(id_ong):
    if "user_role" in session and session["user_role"] == 3:
        db = get_db()
        with db.cursor() as cur:
            cur.execute("DELETE FROM ong WHERE id_ong = %s", (id_ong,))
            db.commit()
        return redirect(url_for("gestionar_usuarios"))
    return redirect(url_for("login_page"))


@app.route("/suspender_usuario/<int:id_usuario>", methods=["POST"])
def suspender_usuario(id_usuario):
    if "user_role" in session and session["user_role"] == 3:
        db = get_db()
        with db.cursor() as cur:
            # Obtener estado actual
            cur.execute("SELECT activo FROM cliente WHERE id_usuario = %s", (id_usuario,))
            estado = cur.fetchone()
            if estado is not None:
                nuevo_estado = not estado[0]  # Invierte: True → False, False → True
                cur.execute("UPDATE cliente SET activo = %s WHERE id_usuario = %s", (nuevo_estado, id_usuario))
                db.commit()
        return redirect(url_for("gestionar_usuarios"))
    return redirect(url_for("login_page"))

@app.route("/suspender_empleado/<int:id_empleado>", methods=["POST"])
def suspender_empleado(id_empleado):
    if "user_role" in session and session["user_role"] == 3:
        db = get_db()
        with db.cursor() as cur:
            cur.execute("SELECT activo FROM empleados WHERE id_empleado = %s", (id_empleado,))
            estado = cur.fetchone()
            if estado is not None:
                nuevo_estado = not estado[0]
                cur.execute("UPDATE empleados SET activo = %s WHERE id_empleado = %s", (nuevo_estado, id_empleado))
                db.commit()
        return redirect(url_for("gestionar_usuarios"))
    return redirect(url_for("login_page"))

@app.route("/suspender_ong/<int:id_ong>", methods=["POST"])
def suspender_ong(id_ong):
    if "user_role" in session and session["user_role"] == 3:
        db = get_db()
        with db.cursor() as cur:
            cur.execute("SELECT activo FROM ong WHERE id_ong = %s", (id_ong,))
            estado = cur.fetchone()
            if estado:
                nuevo_estado = not estado[0]
                cur.execute("UPDATE ong SET activo = %s WHERE id_ong = %s", (nuevo_estado, id_ong))
                db.commit()
        return redirect(url_for("gestionar_usuarios"))
    return redirect(url_for("login_page"))


@app.route("/moderador/pqrs")
def dashboard_pqrs():
    if session.get("user_role") != 3:  # Suponiendo 2 = empleado
        return redirect(url_for("login_page"))

    empleado_id = session["user_id"]
    db = get_db()
    with db.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute("""
            SELECT p.id, p.tipo, p.descripcion, p.estado
            FROM pqrs p
            JOIN incidencias i ON p.id = i.id_pqrs
            WHERE i.id_empleado = %s
        """, (empleado_id,))
        pqrs_list = cur.fetchall()

    return render_template("pqrs_res.html", pqrs_list=pqrs_list)



@app.route("/ong")
def ong_dashboard():
    if session.get("user_role") != 4:  # Supongamos que 4 es ONG
        return redirect(url_for("login_page"))

    tipo_especie = request.args.get("tipo_especie")
    ubicacion = request.args.get("ubicacion")
    fecha = request.args.get("fecha")

    db = get_db()
    with db.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        # 🔧 Obtener tipos para filtros
        cur.execute("SELECT id_tipo_especie, nombre_tipo_especie FROM tipos_especies")
        tipos_especies = cur.fetchall()

        # 🔧 Adaptar consulta para usar reportes y nombre_tipo_alerta como estado
        base_query = """
                SELECT 
                    r.id_reporte,
                    r.descripcion,
                    r.foto_url,
                    r.fecha_reporte AS fecha,
                    tr.nombre_tipo_reporte AS tipo,
                    r.direccion AS ubicacion,
                    ta.nombre_tipo_alerta AS estado
                FROM reportes r
                JOIN tipos_reportes tr ON r.id_tipo_reporte = tr.id_tipo_reporte
                LEFT JOIN alertas a ON r.id_alerta = a.id_alerta
                LEFT JOIN tipos_alertas ta ON a.id_tipo_alerta = ta.id_tipo_alerta
                WHERE 1=1
                -- + filtros dinámicos

        """
        params = []

        if tipo_especie:
            base_query += " AND tr.id_tipo_reporte = %s"
            params.append(tipo_especie)

        if ubicacion:
            base_query += " AND r.direccion ILIKE %s"
            params.append(f"%{ubicacion}%")

        if fecha:
            base_query += " AND r.fecha_reporte::date = %s"
            params.append(fecha)

        base_query += " ORDER BY r.fecha_reporte DESC"

        cur.execute(base_query, tuple(params))
        reportes = cur.fetchall()

    return render_template("ong_dashboard.html",
                           reportes=reportes,
                           tipos_especies=tipos_especies,
                           filtro_tipo=tipo_especie,
                           filtro_ubicacion=ubicacion,
                           filtro_fecha=fecha)

@app.route("/reporte/<int:id_reporte>/tomar", methods=["POST"])
def ong_tomar_caso(id_reporte):
    if session.get("user_role") != 4:  # Validar que es una ONG
        return redirect(url_for("login_page"))

    id_ong = session["user_id"]
    tipo_alerta = 7  # ONG_tomo_caso

    db = get_db()
    with db.cursor() as cur:
        # Insertar la alerta
        cur.execute("""
            INSERT INTO alertas (id_tipo_alerta, id_ong)
            VALUES (%s, %s)
            RETURNING id_alerta
        """, (tipo_alerta, id_ong))
        nueva_alerta = cur.fetchone()[0]

        # Asociar alerta con el reporte
        cur.execute("""
            UPDATE reportes
            SET id_alerta = %s
            WHERE id_reporte = %s
        """, (nueva_alerta, id_reporte))

        db.commit()

    return redirect(url_for("ong_dashboard"))


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

@app.route("/user/enviar_pqrs", methods=["GET"])
def debug_get_enviar_pqrs():
    print("⚠️ Se hizo GET a /user/enviar_pqrs desde algún lugar.")
    return "Esta ruta solo acepta POST", 405

@app.route("/pqrs_form", methods=["GET"])
def pqrs_form():
    if "user_id" not in session:
        return redirect(url_for("login_page"))
    return render_template("pqrs_form.html")
#### METODOS POST ####
######tienes que poner los que necesites ahi segun lo que vayas haciendo#######
@app.route("/user/enviar_pqrs", methods=["POST", "GET"])
def enviar_pqrs():
    if request.method == "GET":
    # Intercepta cualquier GET no deseado (como los que causan 405)
        return redirect(url_for("pqrs_form"))
    if "user_id" not in session:
        return redirect(url_for("login_page"))

    tipo = request.form.get("tipo")
    descripcion = request.form.get("descripcion")
    ubicacion = request.form.get("ubicacion")
    usuario_id = session["user_id"]
    estado = "recibido"

    archivo = request.files.get("url_img")
    filename = None

    # Guardar imagen si existe
    if archivo and archivo.filename:
        filename = secure_filename(f"{uuid.uuid4().hex}_{archivo.filename}")
        ruta = os.path.join(app.config["UPLOAD_FOLDER"], filename)
        archivo.save(ruta)

    # Generar ID único
    id_pqrs = str(uuid.uuid4())

    db = get_db()
    with db.cursor() as cur:
        # 1. Insertar en tabla pqrs
        cur.execute("""
            INSERT INTO pqrs (id, tipo, descripcion, estado, usuario_id)
            VALUES (%s, %s, %s, %s, %s)
        """, (id_pqrs, tipo, descripcion, estado, usuario_id))

        # 2. Insertar en tabla incidencias (si hay imagen o ubicación)
        if filename or ubicacion:
            cur.execute("""
                INSERT INTO incidencias (url_img, id_usuario, id_pqrs, ubicacion)
                VALUES (%s, %s, %s, %s)
            """, (filename, usuario_id, id_pqrs, ubicacion))

        db.commit()

    return redirect(url_for("pqrs_form"))  # o donde desees redirigir

@app.route("/asignar_empleado/<id_pqrs>", methods=["POST"])
def asignar_empleado(id_pqrs):
    empleado_id = session["user_id"]
    db = get_db()
    with db.cursor() as cur:
        cur.execute("UPDATE pqrs SET estado = 'inicio_proceso' WHERE id = %s", (id_pqrs,))
        cur.execute("UPDATE incidencias SET id_empleado = %s WHERE id_pqrs = %s", (empleado_id, id_pqrs))
        db.commit()
    return redirect(url_for("dashboard_pqrs"))

@app.route("/marcar_resuelto/<id_pqrs>", methods=["POST"])
def marcar_resuelto(id_pqrs):
    db = get_db()
    with db.cursor() as cur:
        cur.execute("UPDATE pqrs SET estado = 'resuelto' WHERE id = %s", (id_pqrs,))
        db.commit()
    return redirect(url_for("dashboard_pqrs"))


    
@app.route("/pqrs/<id_pqrs>/chat")
def chat_pqrs(id_pqrs):
    db = get_db()
    with db.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        # Verifica que el usuario esté autorizado (empleado o dueño de la PQRS)
        cur.execute("SELECT usuario_id FROM pqrs WHERE id = %s", (id_pqrs,))
        dueño = cur.fetchone()
        if not dueño:
            return "PQRS no encontrada", 404

        if session["user_type"] == "cliente" and session["user_id"] != dueño["usuario_id"]:
            return "No autorizado", 403

        cur.execute("""
            SELECT emisor, mensaje, imagen_url, fecha
            FROM chat_pqrs
            WHERE id_pqrs = %s ORDER BY fecha ASC
        """, (id_pqrs,))
        mensajes = cur.fetchall()

    return render_template("chat_pqrs.html", mensajes=mensajes, id_pqrs=id_pqrs)


@app.route("/pqrs/<id_pqrs>/enviar_mensaje", methods=["POST"])
def enviar_mensaje(id_pqrs):
    emisor = session.get("user_type")
    mensaje = request.form.get("mensaje")
    archivo = request.files.get("imagen")
    filename = None

    if archivo and archivo.filename:
        filename = secure_filename(f"{uuid.uuid4().hex}_{archivo.filename}")
        archivo.save(os.path.join(app.config["UPLOAD_FOLDER"], filename))

    db = get_db()
    with db.cursor() as cur:
        cur.execute("""
            INSERT INTO chat_pqrs (id_pqrs, emisor, mensaje, imagen_url)
            VALUES (%s, %s, %s, %s)
        """, (id_pqrs, emisor, mensaje, filename))
        db.commit()

    return redirect(url_for('chat_pqrs', id_pqrs=id_pqrs))




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
        print("Reportes:", reportes)
        print("Avistamientos:", avistamientos)
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

    tipo2 = request.args.get("tipo2")  # 'Flora' o 'Fauna'
    id_tipo_especie = request.args.get("id_tipo_especie")  # 1, 2 o 3

    query = """
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
    """
    params = [id_usuario]

    if tipo2:
        query += " AND e.tipo2 = %s"
        params.append(tipo2)

    if id_tipo_especie:
        query += " AND e.id_tipo_especie = %s"
        params.append(id_tipo_especie)

    with db.cursor() as cur:
        cur.execute(query, params)
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
    remaining_chars = ''.join(random.choice(all_chars) for _ in remaining_length)
    
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
    

@app.route('/guardar_noticia', methods=['POST'])
def guardar_noticia():
    try:
        titulo = request.form.get('titulo')
        contenido = request.form.get('contenido')
        categoria = request.form.get('categoria')
        estado = request.form.get('estado', 'borrador')
        fecha_publicacion = request.form.get('fecha_publicacion')
        id_region = request.form.get('id_region')  # si lo añades al formulario

        if fecha_publicacion:
            try:
                fecha_obj = datetime.strptime(fecha_publicacion, '%d/%m/%Y')
                fecha_publicacion = fecha_obj.strftime('%Y-%m-%d')
            except ValueError:
                fecha_publicacion = datetime.now().strftime('%Y-%m-%d')
        else:
            fecha_publicacion = datetime.now().strftime('%Y-%m-%d')

        db = get_db()
        cursor = db.cursor()

        # Insertar en tags (si no existe)
        cursor.execute("SELECT id_tags FROM tags WHERE nombre_tag = %s", (categoria,))
        tag = cursor.fetchone()
        if tag:
            id_tag = tag[0]
        else:
            cursor.execute("INSERT INTO tags (nombre_tag) VALUES (%s) RETURNING id_tags", (categoria,))
            id_tag = cursor.fetchone()[0]

        # Insertar en noticias_ambientales
        cursor.execute("""
            INSERT INTO noticias_ambientales (id_tags, id_fuentes, contenido, titulo, id_region)
            VALUES (%s, NULL, %s, %s, %s) RETURNING id_noticia
        """, (id_tag, contenido, titulo, id_region))
        id_noticia = cursor.fetchone()[0]

        # Insertar fuentes
        enlaces = request.form.getlist('enlaces[]')
        for enlace in enlaces:
            if enlace.strip():
                cursor.execute("""
                    INSERT INTO fuentes (link_fuente, tipo_fuente, titulo_fuente, fecha_fuente)
                    VALUES (%s, %s, %s, %s) RETURNING id_fuentes
                """, (enlace, 'enlace', titulo, fecha_publicacion))
                id_fuente = cursor.fetchone()[0]

                # Actualizar la noticia con la fuente (si solo manejas una)
                cursor.execute("UPDATE noticias_ambientales SET id_fuentes = %s WHERE id_noticia = %s", (id_fuente, id_noticia))

        db.commit()
        cursor.close()
        db.close()

        return jsonify({'success': True, 'message': 'Noticia guardada correctamente', 'id_noticia': id_noticia})

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return jsonify({'success': False, 'message': f'Error al guardar noticia: {str(e)}'})

@app.route("/feed_noticias")
def feed_noticias():
    db = get_db()
    with db.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute("""
            SELECT 
                n.id_noticia,
                n.titulo,
                n.contenido,
                n.fecha_publicacion,
                t.nombre_tag AS categoria,
                r.nombre_region,
                f.link_fuente,
                m.ruta AS imagen
            FROM noticias_ambientales n
            LEFT JOIN tags t ON n.id_tags = t.id_tags
            LEFT JOIN regiones r ON n.id_region = r.id_region
            LEFT JOIN fuentes f ON n.id_fuentes = f.id_fuentes
            LEFT JOIN noticia_media nm ON n.id_noticia = nm.id_noticia
            LEFT JOIN media m ON nm.id_media = m.id_media
            ORDER BY n.fecha_publicacion DESC
        """)
        noticias = cur.fetchall()

    return render_template("feed_noticias.html", noticias=noticias)

@app.route("/noticias")
def ver_noticias():
    db = get_db()
    with db.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute("""
            SELECT n.titulo, n.contenido, r.nombre_region, f.link_fuente, f.titulo_fuente
            FROM noticias_ambientales n
            LEFT JOIN regiones r ON n.id_region = r.id_region
            LEFT JOIN fuentes f ON n.id_fuentes = f.id_fuentes
            ORDER BY n.id_noticia DESC
        """)
        noticias = cur.fetchall()

    return render_template("noticias_feed.html", noticias=noticias)


@app.route("/eliminar_reporte/<int:id_reporte>", methods=["POST"])
def eliminar_reporte(id_reporte):
    db = get_db()
    with db.cursor() as cur:
        cur.execute("DELETE FROM reportes WHERE id_reporte = %s", (id_reporte,))
        db.commit()
    return redirect(url_for('AR_admin'))  # o donde se cargue el HTML AR_admin.html


@app.route("/eliminar_avistamiento/<int:id_avistamiento>", methods=["POST"])
def eliminar_avistamiento(id_avistamiento):
    db = get_db()
    with db.cursor() as cur:
        cur.execute("DELETE FROM avistamientos WHERE id_avistamiento = %s", (id_avistamiento,))
        db.commit()
    return redirect(url_for('AR_admin'))  # misma vista


@app.teardown_appcontext
def teardown(exception):
    close_db()

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)), debug=True)



