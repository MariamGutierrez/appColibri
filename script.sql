-- Script SQL completo para el sistema Colibrí con historial de contraseñas (hashes)

-- =====================
-- Tabla: Roles
-- =====================
CREATE TABLE Roles (
    id_rol SERIAL PRIMARY KEY,
    nombre_rol VARCHAR NOT NULL,
    descripcion_rol TEXT
);

-- =====================
-- Tabla: Usuarios
-- =====================
CREATE TABLE Usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR NOT NULL,
    apellido1 VARCHAR,
    apellido2 VARCHAR,
    correo VARCHAR UNIQUE NOT NULL,
    id_rol INTEGER REFERENCES Roles(id_rol),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================
-- Tabla: Historial_contrasenas
-- =====================
CREATE TABLE Historial_contrasenas (
    id_historial SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES Usuarios(id_usuario) ON DELETE CASCADE,
    contrasena_hash TEXT NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Función para mantener solo las 5 contraseñas más recientes por usuario
CREATE OR REPLACE FUNCTION limitar_historial_contrasenas() RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM Historial_contrasenas
    WHERE id_usuario = NEW.id_usuario
    AND id_historial NOT IN (
        SELECT id_historial FROM Historial_contrasenas
        WHERE id_usuario = NEW.id_usuario
        ORDER BY fecha_registro DESC
        LIMIT 5
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_limitar_historial
AFTER INSERT ON Historial_contrasenas
FOR EACH ROW EXECUTE FUNCTION limitar_historial_contrasenas();

-- =====================
-- Tabla: Permisos
-- =====================
CREATE TABLE Permisos (
    id_permiso SERIAL PRIMARY KEY,
    nombre_permiso VARCHAR NOT NULL
);

CREATE TABLE Roles_permisos (
    id_rol INTEGER REFERENCES Roles(id_rol),
    id_permiso INTEGER REFERENCES Permisos(id_permiso),
    PRIMARY KEY (id_rol, id_permiso)
);

-- =====================
-- Tabla: Tipos_reportes
-- =====================
CREATE TABLE Tipos_reportes (
    id_tipo_reporte SERIAL PRIMARY KEY,
    nombre_tipo_reporte VARCHAR,
    descripcion_tipo_reporte TEXT
);

-- =====================
-- Tabla: Reportes
-- =====================
CREATE TABLE Reportes (
    id_reporte SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES Usuarios(id_usuario),
    id_tipo_reporte INTEGER REFERENCES Tipos_reportes(id_tipo_reporte),
    descripcion TEXT,
    fecha_reporte TIMESTAMP,
    foto_url VARCHAR,
    id_alerta INTEGER
);

-- =====================
-- Tabla: Alertas, Tipos_alertas
-- =====================
CREATE TABLE Tipos_alertas (
    id_tipo_alerta SERIAL PRIMARY KEY,
    nombre_tipo_alerta VARCHAR,
    descripcion_tipo_alerta TEXT
);

CREATE TABLE Alertas (
    id_alerta SERIAL PRIMARY KEY,
    id_tipo_alerta INTEGER REFERENCES Tipos_alertas(id_tipo_alerta),
    fecha_alerta TIMESTAMP,
    id_ong INTEGER
);

-- =====================
-- Tabla: Especies, Ecosistema, Regiones
-- =====================
CREATE TABLE Ecosistema (
    id_ecosistema SERIAL PRIMARY KEY,
    nombre_ecosistema VARCHAR,
    descripcion_ecosistema TEXT
);

CREATE TABLE Regiones (
    id_region SERIAL PRIMARY KEY,
    nombre_region VARCHAR,
    descripcion_region TEXT,
    id_tags INTEGER
);

CREATE TABLE Tipos_especies (
    id_tipo_especie SERIAL PRIMARY KEY,
    nombre_tipo_especie VARCHAR,
    descripcion_tipo_especie TEXT
);

CREATE TABLE Especies (
    id_especie SERIAL PRIMARY KEY,
    id_ecosistema INTEGER REFERENCES Ecosistema(id_ecosistema),
    id_tipo_especie INTEGER REFERENCES Tipos_especies(id_tipo_especie),
    nombre_comun VARCHAR,
    nombre_cientifico VARCHAR,
    descripcion TEXT,
    id_region INTEGER REFERENCES Regiones(id_region)
);

-- =====================
-- Tabla: Avistamientos
-- =====================
CREATE TABLE Avistamientos (
    id_avistamiento SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES Usuarios(id_usuario),
    id_especie INTEGER REFERENCES Especies(id_especie),
    latitud DECIMAL,
    longitud DECIMAL,
    fecha_avistamiento TIMESTAMP
);

-- =====================
-- Tabla: ONG, Tipos_ONG, Acciones
-- =====================
CREATE TABLE Tipos_ong (
    id_tipo_ong SERIAL PRIMARY KEY,
    nombre_tipo_ong VARCHAR
);

CREATE TABLE Ong (
    id_ong SERIAL PRIMARY KEY,
    nombre_ong VARCHAR,
    contacto_ong VARCHAR,
    direccion_ong TEXT,
    email_ong VARCHAR,
    telefono_ong VARCHAR,
    id_tipo_ong INTEGER REFERENCES Tipos_ong(id_tipo_ong)
);

CREATE TABLE Tipos_accion_ong (
    id_tipo_accion SERIAL PRIMARY KEY,
    nombre_accion VARCHAR
);

CREATE TABLE Acciones_ong_reportes (
    id_accion SERIAL PRIMARY KEY,
    id_reporte INTEGER REFERENCES Reportes(id_reporte),
    id_ong INTEGER REFERENCES Ong(id_ong),
    id_tipo_accion INTEGER REFERENCES Tipos_accion_ong(id_tipo_accion),
    fecha_accion TIMESTAMP
);

-- =====================
-- Tabla: Noticias, Educación, Comentarios
-- =====================
CREATE TABLE Tags (
    id_tags SERIAL PRIMARY KEY,
    nombre_tag VARCHAR
);

CREATE TABLE Fuentes (
    id_fuentes SERIAL PRIMARY KEY,
    titulo_fuente VARCHAR,
    tipo_fuente TEXT,
    link_fuente VARCHAR,
    id_contenido_fuentes INTEGER,
    autor_fuente VARCHAR,
    editorial VARCHAR,
    fecha_fuente TIMESTAMP
);

CREATE TABLE Contenido_Fuentes (
    id_contenido_fuentes SERIAL PRIMARY KEY,
    conclusiones_fuente VARCHAR,
    resumen_fuente TEXT,
    anexos_fuente VARCHAR,
    tiempo_insercion TIMESTAMP
);

CREATE TABLE Noticias_ambientales (
    id_noticia SERIAL PRIMARY KEY,
    id_tags INTEGER REFERENCES Tags(id_tags),
    id_fuentes INTEGER REFERENCES Fuentes(id_fuentes),
    contenido TEXT,
    titulo VARCHAR
);

CREATE TABLE Educacion_ambiental (
    id_educacion SERIAL PRIMARY KEY,
    id_region INTEGER REFERENCES Regiones(id_region),
    id_tags INTEGER REFERENCES Tags(id_tags),
    id_especies INTEGER,
    id_fuentes INTEGER REFERENCES Fuentes(id_fuentes),
    contenido TEXT,
    titulo VARCHAR
);

CREATE TABLE Comentarios_reportes (
    id_comentario SERIAL PRIMARY KEY,
    id_reporte INTEGER REFERENCES Reportes(id_reporte),
    id_usuario INTEGER REFERENCES Usuarios(id_usuario),
    comentario TEXT,
    fecha_comentario TIMESTAMP
);

-- =====================
-- Notificaciones y Preferencias
-- =====================
CREATE TABLE Notificaciones_alertas (
    id_notificacion SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES Usuarios(id_usuario),
    id_alerta INTEGER REFERENCES Alertas(id_alerta),
    estado_notificacion VARCHAR,
    fecha_notificacion TIMESTAMP
);

CREATE TABLE Preferencias_notificacion (
    id_preferencia SERIAL PRIMARY KEY,
    id_tipo_alerta INTEGER REFERENCES Tipos_alertas(id_tipo_alerta),
    id_usuario INTEGER REFERENCES Usuarios(id_usuario),
    frecuencia_notificacion VARCHAR
);

-- =====================
-- Fotos de especies
-- =====================
CREATE TABLE Fotos_especies (
    id_foto SERIAL PRIMARY KEY,
    id_especie INTEGER REFERENCES Especies(id_especie),
    url_foto VARCHAR,
    fecha_foto TIMESTAMP
);
-- =====================
-- Tabla: PQRS
-- =====================
CREATE TABLE PQRS (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR NOT NULL CHECK (tipo IN ('petición', 'queja', 'reclamo', 'sugerencia')),
    descripcion TEXT NOT NULL,
    estado VARCHAR NOT NULL,
    usuario_id INTEGER NOT NULL REFERENCES Usuarios(id_usuario) ON DELETE CASCADE
);
