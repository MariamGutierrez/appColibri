--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: limitar_historial_contrasenas(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.limitar_historial_contrasenas() RETURNS trigger
    LANGUAGE plpgsql
    AS $$                                                    
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
$$;


ALTER FUNCTION public.limitar_historial_contrasenas() OWNER TO postgres;

--
-- Name: limpiar_fallos(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.limpiar_fallos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.exito = TRUE THEN
        DELETE FROM intentos_login
        WHERE id_usuario = NEW.id_usuario AND exito = FALSE;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.limpiar_fallos() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acciones_ong_reportes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acciones_ong_reportes (
    id_accion integer NOT NULL,
    id_reporte integer,
    id_ong integer,
    id_tipo_accion integer,
    fecha_accion timestamp without time zone
);


ALTER TABLE public.acciones_ong_reportes OWNER TO postgres;

--
-- Name: acciones_ong_reportes_id_accion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.acciones_ong_reportes_id_accion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.acciones_ong_reportes_id_accion_seq OWNER TO postgres;

--
-- Name: acciones_ong_reportes_id_accion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.acciones_ong_reportes_id_accion_seq OWNED BY public.acciones_ong_reportes.id_accion;


--
-- Name: alertas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alertas (
    id_alerta integer NOT NULL,
    id_tipo_alerta integer,
    fecha_alerta timestamp without time zone,
    id_ong integer
);


ALTER TABLE public.alertas OWNER TO postgres;

--
-- Name: alertas_id_alerta_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alertas_id_alerta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alertas_id_alerta_seq OWNER TO postgres;

--
-- Name: alertas_id_alerta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alertas_id_alerta_seq OWNED BY public.alertas.id_alerta;


--
-- Name: avistamientos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.avistamientos (
    id_avistamiento integer NOT NULL,
    id_usuario integer,
    id_especie integer,
    latitud numeric,
    longitud numeric,
    fecha_avistamiento timestamp without time zone,
    ubicacion character varying(255),
    alerta_id integer,
    descripcion character varying,
    foto_url character varying
);


ALTER TABLE public.avistamientos OWNER TO postgres;

--
-- Name: avistamientos_id_avistamiento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.avistamientos_id_avistamiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.avistamientos_id_avistamiento_seq OWNER TO postgres;

--
-- Name: avistamientos_id_avistamiento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.avistamientos_id_avistamiento_seq OWNED BY public.avistamientos.id_avistamiento;


--
-- Name: chat_pqrs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_pqrs (
    id integer NOT NULL,
    id_pqrs character varying,
    emisor character varying NOT NULL,
    mensaje text,
    imagen_url text,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.chat_pqrs OWNER TO postgres;

--
-- Name: chat_pqrs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_pqrs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.chat_pqrs_id_seq OWNER TO postgres;

--
-- Name: chat_pqrs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_pqrs_id_seq OWNED BY public.chat_pqrs.id;


--
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    id_usuario integer NOT NULL,
    nombre character varying NOT NULL,
    apellido1 character varying,
    apellido2 character varying,
    correo character varying NOT NULL,
    rol character varying DEFAULT 'Visitante'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    activo boolean DEFAULT true
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- Name: cliente_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cliente_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_id_usuario_seq OWNER TO postgres;

--
-- Name: cliente_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cliente_id_usuario_seq OWNED BY public.cliente.id_usuario;


--
-- Name: comentarios_reportes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comentarios_reportes (
    id_comentario integer NOT NULL,
    id_reporte integer,
    id_usuario integer,
    comentario text,
    fecha_comentario timestamp without time zone
);


ALTER TABLE public.comentarios_reportes OWNER TO postgres;

--
-- Name: comentarios_reportes_id_comentario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comentarios_reportes_id_comentario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comentarios_reportes_id_comentario_seq OWNER TO postgres;

--
-- Name: comentarios_reportes_id_comentario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comentarios_reportes_id_comentario_seq OWNED BY public.comentarios_reportes.id_comentario;


--
-- Name: ecosistema; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ecosistema (
    id_ecosistema integer NOT NULL,
    nombre_ecosistema character varying,
    descripcion_ecosistema text
);


ALTER TABLE public.ecosistema OWNER TO postgres;

--
-- Name: ecosistema_id_ecosistema_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ecosistema_id_ecosistema_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ecosistema_id_ecosistema_seq OWNER TO postgres;

--
-- Name: ecosistema_id_ecosistema_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ecosistema_id_ecosistema_seq OWNED BY public.ecosistema.id_ecosistema;


--
-- Name: educacion_ambiental; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.educacion_ambiental (
    id_educacion integer NOT NULL,
    id_region integer,
    id_tags integer,
    id_especies integer,
    id_fuentes integer,
    contenido text,
    titulo character varying
);


ALTER TABLE public.educacion_ambiental OWNER TO postgres;

--
-- Name: educacion_ambiental_id_educacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.educacion_ambiental_id_educacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.educacion_ambiental_id_educacion_seq OWNER TO postgres;

--
-- Name: educacion_ambiental_id_educacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.educacion_ambiental_id_educacion_seq OWNED BY public.educacion_ambiental.id_educacion;


--
-- Name: empleados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.empleados (
    id_empleado integer NOT NULL,
    nombre character varying,
    apellido1 character varying,
    apellido2 character varying,
    correo character varying,
    id_rol integer,
    activo boolean DEFAULT true
);


ALTER TABLE public.empleados OWNER TO postgres;

--
-- Name: empleados_id_empleado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.empleados ALTER COLUMN id_empleado ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.empleados_id_empleado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: especies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.especies (
    id_especie integer NOT NULL,
    id_ecosistema integer,
    id_tipo_especie integer,
    nombre_comun character varying,
    nombre_cientifico character varying,
    descripcion text,
    id_region integer,
    tipo2 character varying
);


ALTER TABLE public.especies OWNER TO postgres;

--
-- Name: especies_id_especie_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.especies_id_especie_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.especies_id_especie_seq OWNER TO postgres;

--
-- Name: especies_id_especie_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.especies_id_especie_seq OWNED BY public.especies.id_especie;


--
-- Name: especies_regiones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.especies_regiones (
    especies_id_especie integer NOT NULL,
    regiones_id_region integer NOT NULL
);


ALTER TABLE public.especies_regiones OWNER TO postgres;

--
-- Name: especies_regiones_especies_id_especie_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.especies_regiones_especies_id_especie_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.especies_regiones_especies_id_especie_seq OWNER TO postgres;

--
-- Name: especies_regiones_especies_id_especie_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.especies_regiones_especies_id_especie_seq OWNED BY public.especies_regiones.especies_id_especie;


--
-- Name: especies_regiones_regiones_id_region_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.especies_regiones_regiones_id_region_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.especies_regiones_regiones_id_region_seq OWNER TO postgres;

--
-- Name: especies_regiones_regiones_id_region_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.especies_regiones_regiones_id_region_seq OWNED BY public.especies_regiones.regiones_id_region;


--
-- Name: fotos_especies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fotos_especies (
    id_foto integer NOT NULL,
    id_especie integer,
    url_foto character varying,
    fecha_foto timestamp without time zone
);


ALTER TABLE public.fotos_especies OWNER TO postgres;

--
-- Name: fotos_especies_id_foto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fotos_especies_id_foto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fotos_especies_id_foto_seq OWNER TO postgres;

--
-- Name: fotos_especies_id_foto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fotos_especies_id_foto_seq OWNED BY public.fotos_especies.id_foto;


--
-- Name: fuentes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fuentes (
    id_fuentes integer NOT NULL,
    titulo_fuente character varying,
    tipo_fuente text,
    link_fuente character varying,
    id_contenido_fuentes integer,
    autor_fuente character varying,
    editorial character varying,
    fecha_fuente timestamp without time zone
);


ALTER TABLE public.fuentes OWNER TO postgres;

--
-- Name: fuentes_id_fuentes_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fuentes_id_fuentes_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fuentes_id_fuentes_seq OWNER TO postgres;

--
-- Name: fuentes_id_fuentes_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fuentes_id_fuentes_seq OWNED BY public.fuentes.id_fuentes;


--
-- Name: historial_contrasenas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.historial_contrasenas (
    id_historial integer NOT NULL,
    id_usuario integer,
    contrasena_hash text NOT NULL,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_empleado integer,
    ong_id integer,
    CONSTRAINT chk_usuario_empleado_ong CHECK ((((((id_usuario IS NOT NULL))::integer + ((id_empleado IS NOT NULL))::integer) + ((ong_id IS NOT NULL))::integer) = 1))
);


ALTER TABLE public.historial_contrasenas OWNER TO postgres;

--
-- Name: historial_contrasenas_id_historial_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.historial_contrasenas_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.historial_contrasenas_id_historial_seq OWNER TO postgres;

--
-- Name: historial_contrasenas_id_historial_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.historial_contrasenas_id_historial_seq OWNED BY public.historial_contrasenas.id_historial;


--
-- Name: incidencias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.incidencias (
    id_incidencias integer NOT NULL,
    url_img "char",
    id_usuario integer NOT NULL,
    id_pqrs character varying NOT NULL,
    id_empleado integer DEFAULT 6,
    correo "char",
    ubicacion "char"
);


ALTER TABLE public.incidencias OWNER TO postgres;

--
-- Name: incidencias_id_incidencias_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.incidencias ALTER COLUMN id_incidencias ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.incidencias_id_incidencias_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: incidencias_id_pqrs_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.incidencias_id_pqrs_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.incidencias_id_pqrs_seq OWNER TO postgres;

--
-- Name: incidencias_id_pqrs_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.incidencias_id_pqrs_seq OWNED BY public.incidencias.id_pqrs;


--
-- Name: incidencias_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.incidencias_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.incidencias_id_usuario_seq OWNER TO postgres;

--
-- Name: incidencias_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.incidencias_id_usuario_seq OWNED BY public.incidencias.id_usuario;


--
-- Name: intentos_login; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.intentos_login (
    id_intento integer NOT NULL,
    id_usuario integer NOT NULL,
    exito boolean NOT NULL,
    fecha_intento timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ip_origen character varying(50),
    user_agent text
);


ALTER TABLE public.intentos_login OWNER TO postgres;

--
-- Name: intentos_login_id_intento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.intentos_login_id_intento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.intentos_login_id_intento_seq OWNER TO postgres;

--
-- Name: intentos_login_id_intento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.intentos_login_id_intento_seq OWNED BY public.intentos_login.id_intento;


--
-- Name: noticias_ambientales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.noticias_ambientales (
    id_noticia integer NOT NULL,
    id_tags integer,
    id_fuentes integer,
    contenido text,
    titulo character varying,
    id_region integer
);


ALTER TABLE public.noticias_ambientales OWNER TO postgres;

--
-- Name: noticias_ambientales_id_noticia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.noticias_ambientales_id_noticia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.noticias_ambientales_id_noticia_seq OWNER TO postgres;

--
-- Name: noticias_ambientales_id_noticia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.noticias_ambientales_id_noticia_seq OWNED BY public.noticias_ambientales.id_noticia;


--
-- Name: notificaciones_alertas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notificaciones_alertas (
    id_notificacion integer NOT NULL,
    id_usuario integer,
    id_alerta integer,
    estado_notificacion character varying,
    fecha_notificacion timestamp without time zone
);


ALTER TABLE public.notificaciones_alertas OWNER TO postgres;

--
-- Name: notificaciones_alertas_id_notificacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notificaciones_alertas_id_notificacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notificaciones_alertas_id_notificacion_seq OWNER TO postgres;

--
-- Name: notificaciones_alertas_id_notificacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notificaciones_alertas_id_notificacion_seq OWNED BY public.notificaciones_alertas.id_notificacion;


--
-- Name: ong; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ong (
    id_ong integer NOT NULL,
    nombre_ong character varying,
    contacto_ong character varying,
    direccion_ong text,
    email_ong character varying,
    telefono_ong character varying,
    id_tipo_ong integer,
    rol character varying DEFAULT 4,
    activo boolean DEFAULT true
);


ALTER TABLE public.ong OWNER TO postgres;

--
-- Name: ong_id_ong_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ong_id_ong_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ong_id_ong_seq OWNER TO postgres;

--
-- Name: ong_id_ong_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ong_id_ong_seq OWNED BY public.ong.id_ong;


--
-- Name: permisos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permisos (
    id_permiso integer NOT NULL,
    nombre_permiso character varying NOT NULL
);


ALTER TABLE public.permisos OWNER TO postgres;

--
-- Name: permisos_id_permiso_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permisos_id_permiso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permisos_id_permiso_seq OWNER TO postgres;

--
-- Name: permisos_id_permiso_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permisos_id_permiso_seq OWNED BY public.permisos.id_permiso;


--
-- Name: pqrs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pqrs (
    id character varying NOT NULL,
    tipo character varying NOT NULL,
    descripcion text NOT NULL,
    estado character varying NOT NULL,
    usuario_id integer NOT NULL
);


ALTER TABLE public.pqrs OWNER TO postgres;

--
-- Name: pqrs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pqrs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pqrs_id_seq OWNER TO postgres;

--
-- Name: pqrs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pqrs_id_seq OWNED BY public.pqrs.id;


--
-- Name: preferencias_notificacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.preferencias_notificacion (
    id_preferencia integer NOT NULL,
    id_notificacion integer,
    id_usuario integer,
    frecuencia_notificacion character varying
);


ALTER TABLE public.preferencias_notificacion OWNER TO postgres;

--
-- Name: preferencias_notificacion_id_preferencia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.preferencias_notificacion_id_preferencia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.preferencias_notificacion_id_preferencia_seq OWNER TO postgres;

--
-- Name: preferencias_notificacion_id_preferencia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.preferencias_notificacion_id_preferencia_seq OWNED BY public.preferencias_notificacion.id_preferencia;


--
-- Name: regiones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.regiones (
    id_region integer NOT NULL,
    nombre_region character varying,
    descripcion_region text,
    id_tags integer
);


ALTER TABLE public.regiones OWNER TO postgres;

--
-- Name: regiones_id_region_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.regiones_id_region_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.regiones_id_region_seq OWNER TO postgres;

--
-- Name: regiones_id_region_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.regiones_id_region_seq OWNED BY public.regiones.id_region;


--
-- Name: reportes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reportes (
    id_reporte integer NOT NULL,
    id_usuario integer,
    id_tipo_reporte integer,
    descripcion text,
    fecha_reporte timestamp without time zone,
    foto_url character varying,
    id_alerta integer,
    direccion text
);


ALTER TABLE public.reportes OWNER TO postgres;

--
-- Name: reportes_id_reporte_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reportes_id_reporte_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reportes_id_reporte_seq OWNER TO postgres;

--
-- Name: reportes_id_reporte_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reportes_id_reporte_seq OWNED BY public.reportes.id_reporte;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id_rol integer NOT NULL,
    nombre_rol character varying NOT NULL,
    descripcion_rol text
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_rol_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_rol_seq OWNER TO postgres;

--
-- Name: roles_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_rol_seq OWNED BY public.roles.id_rol;


--
-- Name: roles_permisos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles_permisos (
    id_rol integer NOT NULL,
    id_permiso integer NOT NULL
);


ALTER TABLE public.roles_permisos OWNER TO postgres;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tags (
    id_tags integer NOT NULL,
    nombre_tag character varying
);


ALTER TABLE public.tags OWNER TO postgres;

--
-- Name: tags_id_tags_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tags_id_tags_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tags_id_tags_seq OWNER TO postgres;

--
-- Name: tags_id_tags_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tags_id_tags_seq OWNED BY public.tags.id_tags;


--
-- Name: tipos_accion_ong; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_accion_ong (
    id_tipo_accion integer NOT NULL,
    nombre_accion character varying
);


ALTER TABLE public.tipos_accion_ong OWNER TO postgres;

--
-- Name: tipos_accion_ong_id_tipo_accion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipos_accion_ong_id_tipo_accion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipos_accion_ong_id_tipo_accion_seq OWNER TO postgres;

--
-- Name: tipos_accion_ong_id_tipo_accion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipos_accion_ong_id_tipo_accion_seq OWNED BY public.tipos_accion_ong.id_tipo_accion;


--
-- Name: tipos_alertas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_alertas (
    id_tipo_alerta integer NOT NULL,
    nombre_tipo_alerta character varying,
    descripcion_tipo_alerta text
);


ALTER TABLE public.tipos_alertas OWNER TO postgres;

--
-- Name: tipos_alertas_id_tipo_alerta_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipos_alertas_id_tipo_alerta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipos_alertas_id_tipo_alerta_seq OWNER TO postgres;

--
-- Name: tipos_alertas_id_tipo_alerta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipos_alertas_id_tipo_alerta_seq OWNED BY public.tipos_alertas.id_tipo_alerta;


--
-- Name: tipos_especies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_especies (
    id_tipo_especie integer NOT NULL,
    nombre_tipo_especie character varying,
    descripcion_tipo_especie text
);


ALTER TABLE public.tipos_especies OWNER TO postgres;

--
-- Name: tipos_especies_id_tipo_especie_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipos_especies_id_tipo_especie_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipos_especies_id_tipo_especie_seq OWNER TO postgres;

--
-- Name: tipos_especies_id_tipo_especie_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipos_especies_id_tipo_especie_seq OWNED BY public.tipos_especies.id_tipo_especie;


--
-- Name: tipos_ong; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_ong (
    id_tipo_ong integer NOT NULL,
    nombre_tipo_ong character varying
);


ALTER TABLE public.tipos_ong OWNER TO postgres;

--
-- Name: tipos_ong_id_tipo_ong_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipos_ong_id_tipo_ong_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipos_ong_id_tipo_ong_seq OWNER TO postgres;

--
-- Name: tipos_ong_id_tipo_ong_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipos_ong_id_tipo_ong_seq OWNED BY public.tipos_ong.id_tipo_ong;


--
-- Name: tipos_reportes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_reportes (
    id_tipo_reporte integer NOT NULL,
    nombre_tipo_reporte character varying,
    descripcion_tipo_reporte text
);


ALTER TABLE public.tipos_reportes OWNER TO postgres;

--
-- Name: tipos_reportes_id_tipo_reporte_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipos_reportes_id_tipo_reporte_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipos_reportes_id_tipo_reporte_seq OWNER TO postgres;

--
-- Name: tipos_reportes_id_tipo_reporte_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipos_reportes_id_tipo_reporte_seq OWNED BY public.tipos_reportes.id_tipo_reporte;


--
-- Name: acciones_ong_reportes id_accion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acciones_ong_reportes ALTER COLUMN id_accion SET DEFAULT nextval('public.acciones_ong_reportes_id_accion_seq'::regclass);


--
-- Name: alertas id_alerta; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas ALTER COLUMN id_alerta SET DEFAULT nextval('public.alertas_id_alerta_seq'::regclass);


--
-- Name: avistamientos id_avistamiento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avistamientos ALTER COLUMN id_avistamiento SET DEFAULT nextval('public.avistamientos_id_avistamiento_seq'::regclass);


--
-- Name: chat_pqrs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_pqrs ALTER COLUMN id SET DEFAULT nextval('public.chat_pqrs_id_seq'::regclass);


--
-- Name: cliente id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id_usuario SET DEFAULT nextval('public.cliente_id_usuario_seq'::regclass);


--
-- Name: comentarios_reportes id_comentario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comentarios_reportes ALTER COLUMN id_comentario SET DEFAULT nextval('public.comentarios_reportes_id_comentario_seq'::regclass);


--
-- Name: ecosistema id_ecosistema; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ecosistema ALTER COLUMN id_ecosistema SET DEFAULT nextval('public.ecosistema_id_ecosistema_seq'::regclass);


--
-- Name: educacion_ambiental id_educacion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.educacion_ambiental ALTER COLUMN id_educacion SET DEFAULT nextval('public.educacion_ambiental_id_educacion_seq'::regclass);


--
-- Name: especies id_especie; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especies ALTER COLUMN id_especie SET DEFAULT nextval('public.especies_id_especie_seq'::regclass);


--
-- Name: especies_regiones especies_id_especie; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especies_regiones ALTER COLUMN especies_id_especie SET DEFAULT nextval('public.especies_regiones_especies_id_especie_seq'::regclass);


--
-- Name: especies_regiones regiones_id_region; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especies_regiones ALTER COLUMN regiones_id_region SET DEFAULT nextval('public.especies_regiones_regiones_id_region_seq'::regclass);


--
-- Name: fotos_especies id_foto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fotos_especies ALTER COLUMN id_foto SET DEFAULT nextval('public.fotos_especies_id_foto_seq'::regclass);


--
-- Name: fuentes id_fuentes; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fuentes ALTER COLUMN id_fuentes SET DEFAULT nextval('public.fuentes_id_fuentes_seq'::regclass);


--
-- Name: historial_contrasenas id_historial; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_contrasenas ALTER COLUMN id_historial SET DEFAULT nextval('public.historial_contrasenas_id_historial_seq'::regclass);


--
-- Name: incidencias id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias ALTER COLUMN id_usuario SET DEFAULT nextval('public.incidencias_id_usuario_seq'::regclass);


--
-- Name: incidencias id_pqrs; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias ALTER COLUMN id_pqrs SET DEFAULT nextval('public.incidencias_id_pqrs_seq'::regclass);


--
-- Name: intentos_login id_intento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intentos_login ALTER COLUMN id_intento SET DEFAULT nextval('public.intentos_login_id_intento_seq'::regclass);


--
-- Name: noticias_ambientales id_noticia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticias_ambientales ALTER COLUMN id_noticia SET DEFAULT nextval('public.noticias_ambientales_id_noticia_seq'::regclass);


--
-- Name: notificaciones_alertas id_notificacion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones_alertas ALTER COLUMN id_notificacion SET DEFAULT nextval('public.notificaciones_alertas_id_notificacion_seq'::regclass);


--
-- Name: ong id_ong; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ong ALTER COLUMN id_ong SET DEFAULT nextval('public.ong_id_ong_seq'::regclass);


--
-- Name: permisos id_permiso; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permisos ALTER COLUMN id_permiso SET DEFAULT nextval('public.permisos_id_permiso_seq'::regclass);


--
-- Name: pqrs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pqrs ALTER COLUMN id SET DEFAULT nextval('public.pqrs_id_seq'::regclass);


--
-- Name: preferencias_notificacion id_preferencia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.preferencias_notificacion ALTER COLUMN id_preferencia SET DEFAULT nextval('public.preferencias_notificacion_id_preferencia_seq'::regclass);


--
-- Name: regiones id_region; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.regiones ALTER COLUMN id_region SET DEFAULT nextval('public.regiones_id_region_seq'::regclass);


--
-- Name: reportes id_reporte; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes ALTER COLUMN id_reporte SET DEFAULT nextval('public.reportes_id_reporte_seq'::regclass);


--
-- Name: roles id_rol; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id_rol SET DEFAULT nextval('public.roles_id_rol_seq'::regclass);


--
-- Name: tags id_tags; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags ALTER COLUMN id_tags SET DEFAULT nextval('public.tags_id_tags_seq'::regclass);


--
-- Name: tipos_accion_ong id_tipo_accion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_accion_ong ALTER COLUMN id_tipo_accion SET DEFAULT nextval('public.tipos_accion_ong_id_tipo_accion_seq'::regclass);


--
-- Name: tipos_alertas id_tipo_alerta; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_alertas ALTER COLUMN id_tipo_alerta SET DEFAULT nextval('public.tipos_alertas_id_tipo_alerta_seq'::regclass);


--
-- Name: tipos_especies id_tipo_especie; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_especies ALTER COLUMN id_tipo_especie SET DEFAULT nextval('public.tipos_especies_id_tipo_especie_seq'::regclass);


--
-- Name: tipos_ong id_tipo_ong; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_ong ALTER COLUMN id_tipo_ong SET DEFAULT nextval('public.tipos_ong_id_tipo_ong_seq'::regclass);


--
-- Name: tipos_reportes id_tipo_reporte; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_reportes ALTER COLUMN id_tipo_reporte SET DEFAULT nextval('public.tipos_reportes_id_tipo_reporte_seq'::regclass);


--
-- Data for Name: acciones_ong_reportes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.acciones_ong_reportes (id_accion, id_reporte, id_ong, id_tipo_accion, fecha_accion) FROM stdin;
\.


--
-- Data for Name: alertas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alertas (id_alerta, id_tipo_alerta, fecha_alerta, id_ong) FROM stdin;
2	2	2025-05-18 04:08:08.971238	\N
3	1	2025-05-18 04:10:12.852404	\N
4	2	2025-05-18 04:15:43.44447	\N
5	2	2025-05-18 04:15:47.816989	\N
6	1	2025-05-18 04:15:53.105278	\N
7	2	2025-05-18 04:15:56.639927	\N
8	1	2025-05-18 19:06:50.708477	\N
9	4	2025-05-19 01:43:55.703916	\N
10	1	2025-05-19 02:00:30.559513	\N
11	2	2025-05-19 02:00:36.975142	\N
12	2	2025-05-19 02:00:38.77908	\N
13	3	2025-05-19 02:01:22.052631	\N
14	3	2025-05-19 02:04:34.90545	\N
15	1	2025-05-19 02:08:38.712897	\N
16	1	2025-05-19 02:08:46.308128	\N
17	1	2025-05-19 02:08:48.784269	\N
18	6	2025-05-19 02:15:31.837666	\N
19	3	2025-05-19 02:27:08.438156	\N
20	4	2025-05-19 02:29:12.579749	\N
21	6	2025-05-19 02:30:43.351453	\N
25	4	2025-05-19 02:45:40.66302	\N
26	4	2025-05-19 02:46:24.63201	\N
27	5	2025-05-19 02:46:45.022828	\N
28	6	2025-05-19 02:46:49.725545	\N
29	4	2025-05-19 02:50:05.457718	\N
30	6	2025-05-19 02:50:26.864219	\N
31	5	2025-05-19 04:01:51.668808	\N
32	5	2025-05-19 04:01:55.975351	\N
33	5	2025-05-19 04:01:59.16272	\N
34	4	2025-05-20 06:43:39.173435	\N
35	6	2025-05-20 06:44:03.905253	\N
36	7	\N	1
37	4	2025-05-20 21:29:34.865438	\N
38	6	2025-05-20 21:30:33.768262	\N
39	3	2025-05-20 21:34:58.901094	\N
40	7	\N	1
41	4	2025-05-20 23:24:33.269402	\N
42	6	2025-05-20 23:25:39.626203	\N
43	3	2025-05-20 23:31:42.16344	\N
\.


--
-- Data for Name: avistamientos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.avistamientos (id_avistamiento, id_usuario, id_especie, latitud, longitud, fecha_avistamiento, ubicacion, alerta_id, descripcion, foto_url) FROM stdin;
2	1	7	\N	\N	2025-05-19 01:43:55.703916	bulevar 42	18	Es un colibri lol	https://res.cloudinary.com/dhaneunlu/image/upload/v1747637034/gsxfh7hijdlwa3xyxvzq.jpg
3	1	7	\N	\N	2025-05-19 02:29:12.579749	plaza	21	Es un colibri	https://res.cloudinary.com/dhaneunlu/image/upload/v1747639751/v511duqdofrkbkgkhcbb.jpg
7	1	10	4.6545436	-74.0284874	2025-05-20 06:43:39.173435	Las Moyas	35	Frailejon hernesto perez jsjs	https://res.cloudinary.com/dhaneunlu/image/upload/v1747741418/yg0sjj59cs4a8eqdsciz.jpg
8	3	5	\N	\N	2025-05-20 21:29:34.865438	Universidad Manuela Beltr├ín	38	Tigresito 	https://res.cloudinary.com/dhaneunlu/image/upload/v1747794572/nf0kled4aejcxcmeuz0c.jpg
9	7	9	6.2697324	-75.6025597	2025-05-20 23:24:33.269402	Medellin	42	Gael\r\nHola soy de medellin colombia, tengo 13, Soy adoptado	https://res.cloudinary.com/dhaneunlu/image/upload/v1747801472/errpihlafickqjwalmtw.jpg
\.


--
-- Data for Name: chat_pqrs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_pqrs (id, id_pqrs, emisor, mensaje, imagen_url, fecha) FROM stdin;
1	457d26b9-1d09-4704-83f0-af5b9d79fef9	empleado	que pasho?	\N	2025-05-20 16:03:16.911402
2	457d26b9-1d09-4704-83f0-af5b9d79fef9	cliente	no me sirve pipi 	81db669d10d64ca6b14752b04151adbd_db3d4cec5f816ee21e6688d82b8244a9.jpg	2025-05-20 16:12:37.976552
3	ef9d9e1a-4360-4f15-b7b0-2b0f5afc7479	cliente	├æao	\N	2025-05-20 21:17:03.248986
4	ef9d9e1a-4360-4f15-b7b0-2b0f5afc7479	empleado	Callen esa gente ruidosa luego se quejan de uno	\N	2025-05-20 21:17:04.211219
5	ef9d9e1a-4360-4f15-b7b0-2b0f5afc7479	cliente	ojala siiii	\N	2025-05-20 21:17:21.039106
6	ef9d9e1a-4360-4f15-b7b0-2b0f5afc7479	cliente	si una tortuga me robo a mi novia que hago? :c\r\n	\N	2025-05-20 21:17:55.314712
7	ef9d9e1a-4360-4f15-b7b0-2b0f5afc7479	empleado	Echale sal a la tortuga y azucar a la novia	30d2407f850549bdace2279166f9ebc3_17z0nhnt2v__WW214751.jpg	2025-05-20 21:18:32.834207
8	ef9d9e1a-4360-4f15-b7b0-2b0f5afc7479	cliente	pipi	0b897a24ada94578b2fa1f08128cf898_Obab.webp	2025-05-20 21:19:14.26721
9	291eb4b2-e136-48e2-b3d4-41e92b0f81f7	cliente	hola quisiera que pusieran mas especies en el formulario	\N	2025-05-20 21:37:39.213276
10	291eb4b2-e136-48e2-b3d4-41e92b0f81f7	empleado	Claro que si estimado usuario	\N	2025-05-20 21:37:56.603239
11	d0da8452-2caa-4333-80c9-1f5727b9d67e	cliente	>:(	63d300b9240543958750592de9250d86_descarga_11.jpg	2025-05-20 23:32:20.669318
12	d0da8452-2caa-4333-80c9-1f5727b9d67e	empleado	(Òüú ┬░ðö ┬░;)Òüú	\N	2025-05-20 23:33:02.084562
13	d0da8452-2caa-4333-80c9-1f5727b9d67e	cliente		4742de1fe2114607b63c5280a7d55108_descarga_12.jpg	2025-05-20 23:33:16.750702
14	d0da8452-2caa-4333-80c9-1f5727b9d67e	cliente		edc8001c1997464a909ee26b8e99faec_FB_IMG_1588006224403.jpg	2025-05-20 23:33:36.025308
15	d0da8452-2caa-4333-80c9-1f5727b9d67e	empleado		b534dc2dd0b5409a943058776e671947_7d9188695009bbf734c043a62c26c0fa.jpg	2025-05-20 23:33:40.596491
16	d0da8452-2caa-4333-80c9-1f5727b9d67e	cliente		310700a797d14a85a246c59e1f64fe95_d.gif	2025-05-20 23:34:12.085531
17	d0da8452-2caa-4333-80c9-1f5727b9d67e	empleado	(Ôê¬.Ôê¬ )...zzz	\N	2025-05-20 23:34:40.030035
18	d0da8452-2caa-4333-80c9-1f5727b9d67e	cliente		1e20e8e7ccb54842b3a5344fc7a58801_rainbow_sheep.gif	2025-05-20 23:34:49.05861
19	d0da8452-2caa-4333-80c9-1f5727b9d67e	cliente		a56e429a5f0a44fab0160ecadcf0d703_leche_no_es_cum.png	2025-05-20 23:35:34.129737
20	d0da8452-2caa-4333-80c9-1f5727b9d67e	empleado	(ÒÇé>´©┐<)_╬©	\N	2025-05-20 23:36:46.600578
\.


--
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cliente (id_usuario, nombre, apellido1, apellido2, correo, rol, created_at, activo) FROM stdin;
1	Hugo	Vlad	\N	mokingbird@gmail.com	1	2025-05-18 00:05:01.782647	t
4	Erika	Krum	\N	nisaco2281@bamsrad.com	1	2025-05-19 06:28:28.581399	t
5	Catalina	Quijano	\N	xameb56357@daupload.com	1	2025-05-19 13:07:31.791078	t
3	Kaliman	Saib	\N	kaliman@example.com	1	2025-05-19 05:46:12.48731	f
6	Daniel	Mora	\N	colibri@gmail.com	1	2025-05-20 21:31:45.710134	t
7	tu	mama	\N	tumama@gmail.com	1	2025-05-20 23:13:32.980262	t
\.


--
-- Data for Name: comentarios_reportes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comentarios_reportes (id_comentario, id_reporte, id_usuario, comentario, fecha_comentario) FROM stdin;
\.


--
-- Data for Name: ecosistema; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ecosistema (id_ecosistema, nombre_ecosistema, descripcion_ecosistema) FROM stdin;
1	Bosque Tropical	Ecosistema c├ílido y h├║medo con gran biodiversidad, ubicado en zonas ecuatoriales.
2	Desierto	Regi├│n ├írida con escasas precipitaciones, vegetaci├│n adaptada y temperaturas extremas.
3	Pradera	Terreno abierto con pastos abundantes, ideal para herb├¡voros, con lluvias moderadas.
4	Humedal	├ürea saturada de agua que alberga flora y fauna acu├ítica.
5	Manglar	Ecosistema costero tropical con ├írboles tolerantes a la sal, clave para proteger costas.
6	Tundra	Zona fr├¡a con suelo congelado gran parte del a├▒o, vegetaci├│n baja y clima extremo.
7	Bosque Templado	Bosques con estaciones marcadas, ├írboles caducifolios y fauna variada.
8	Arrecife de Coral	Estructuras marinas construidas por corales, h├íbitat biodiverso en mares tropicales.
9	Sabana	Llanuras c├ílidas con ├írboles dispersos y lluvias estacionales.
10	Selva Nublada	Ecosistema monta├▒oso h├║medo con niebla constante y vegetaci├│n exuberante.
\.


--
-- Data for Name: educacion_ambiental; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.educacion_ambiental (id_educacion, id_region, id_tags, id_especies, id_fuentes, contenido, titulo) FROM stdin;
\.


--
-- Data for Name: empleados; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.empleados (id_empleado, nombre, apellido1, apellido2, correo, id_rol, activo) FROM stdin;
3	Vivian	Minovia	\N	mokingbird2@gmail.com	2	t
6	Harumasa	Asaba	\N	asaba@hands.gov	3	t
4	Zhu	Yuan	\N	pubsec@gmail.com	2	t
\.


--
-- Data for Name: especies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.especies (id_especie, id_ecosistema, id_tipo_especie, nombre_comun, nombre_cientifico, descripcion, id_region, tipo2) FROM stdin;
1	1	1	Delf├¡n rosado	Inia geoffrensis	Cet├íceo de agua dulce que habita r├¡os de la Amazon├¡a. En peligro debido a la contaminaci├│n y la pesca.	1	Fauna
2	2	2	Zorro de p├íramo	Lycalopex culpaeus	Carn├¡voro que habita ecosistemas de alta monta├▒a en la regi├│n andina.	2	Fauna
3	3	1	Caim├ín aguja	Crocodylus acutus	Reptil que vive en manglares y zonas h├║medas del Caribe colombiano.	3	Fauna
4	4	3	Rana toro africana	Pyxicephalus adspersus	Especie invasora introducida accidentalmente que compite con especies nativas.	2	Fauna
5	5	1	Jaguar	Panthera onca	Felino en peligro de extinci├│n que habita selvas h├║medas del Pac├¡fico colombiano.	4	Fauna
6	6	2	Garza blanca	Ardea alba	Ave com├║n en humedales y cuerpos de agua del pa├¡s.	5	Fauna
7	2	2	Colibr├¡	Trochilidae spp.	Peque├▒a ave polinizadora muy com├║n en los Andes.	2	Fauna
8	3	3	Pez le├│n	Pterois volitans	Especie marina invasora presente en la regi├│n insular y Caribe.	6	Fauna
9	1	1	Orqu├¡dea de la Amazon├¡a	Cattleya trianae	Planta ep├¡fita en peligro de extinci├│n, end├®mica de la selva tropical h├║meda.	1	Flora
10	10	2	Frailej├│n	Espeletia grandiflora	Planta emblem├ítica de los p├íramos andinos, fundamental para la regulaci├│n h├¡drica.	2	Flora
11	3	2	Pasto estrella	Cynodon nlemfuensis	Hierba com├║n en praderas, utilizada en ganader├¡a por su r├ípido crecimiento.	5	Flora
12	5	3	Jacinto de agua	Eichhornia crassipes	Planta acu├ítica invasora que afecta ecosistemas de humedales y cuerpos de agua.	4	Flora
13	7	1	Manglar rojo	Rhizophora mangle	├ürbol caracter├¡stico de ecosistemas costeros tropicales, vital para la fauna marina.	3	Flora
\.


--
-- Data for Name: especies_regiones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.especies_regiones (especies_id_especie, regiones_id_region) FROM stdin;
\.


--
-- Data for Name: fotos_especies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fotos_especies (id_foto, id_especie, url_foto, fecha_foto) FROM stdin;
\.


--
-- Data for Name: fuentes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fuentes (id_fuentes, titulo_fuente, tipo_fuente, link_fuente, id_contenido_fuentes, autor_fuente, editorial, fecha_fuente) FROM stdin;
1	Polic├¡a instala dispensadores con comida para gatos abandonados en Mompox	enlace	https://www.elespectador.com/la-red-zoocial/gatos/policia-instala-dispensadores-con-comida-para-gatos-abandonados-en-mompox-noticias-hoy/	\N	\N	\N	2023-07-25 00:00:00
2	┬┐Cu├íles animales viven en la Amazon├¡a? Este y otros 8 datos sobre la Amazon├¡a	enlace	https://www.worldwildlife.org/descubre-wwf/historias/cuales-animales-viven-en-la-amazonia-este-y-otros-8-datos-sobre-la-amazonia	\N	\N	\N	2025-05-06 00:00:00
\.


--
-- Data for Name: historial_contrasenas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.historial_contrasenas (id_historial, id_usuario, contrasena_hash, fecha_registro, id_empleado, ong_id) FROM stdin;
1	1	scrypt:32768:8:1$2HTk3ZP6YTpzqkAL$5cc067a5c9c69951a075e753e51d2733e4c7e6643b7cfc4117f188ef3f716bf08686ce62b3b2a7f6c435f48b4cbfd9b1f39230c6c9badf97b5f1fcd5f5453094	2025-05-18 00:05:01.782647	\N	\N
4	\N	scrypt:32768:8:1$24NEXGtNbqbzndGL$84375f689f46b0352083528bbc1ee59546b587dc7e95a025e932d89e841cc30fb89624ad4a1fbb81ddef9f97b8aa1bc86bba75802b56a1fae0ded9da53086c8f	2025-05-18 02:14:10.326229	3	\N
5	\N	scrypt:32768:8:1$Fphx0ymgINqg4ByD$4510d46c57ede0021c9215d81ed2c52975f1ab5f805b0b33516ce4abf637bd316bde8e22d4cca3e85c1131a15faee0f655ed3365c2cb63e6aa63eb8a30bebf78	2025-05-18 02:21:42.626766	4	\N
8	\N	32768:8:1$blAV6lZseM1Eesze$e64a4b88b0f7e337783b5eca0105b3209f9c7b32ba4e7a5e1256bd36cc276c107af6b502a73ebe43faecec8ecd2eca2b8b67397df97439d874af3cbdc87906d4	2025-05-19 03:18:35.677347	6	\N
9	\N	scrypt:32768:8:1$pB1wuftgOyfUXI8Q$49250068e778039d169ad3074cbb8029e67e64a958b5bb5c5ed8578f36f56ca3424dd5a1e3fc29c05146794f41160f055a436f04164de83540fcacdd65fe8c16	2025-05-19 03:21:08.905332	6	\N
10	3	scrypt:32768:8:1$F91D8CR23BcGM5D9$197d56322cc7811b484567b535bc7a75f0cfeb55873a9172742a729508cf3af0a642f2f4a45bac1cd44840987836eb2117836d037145d50b99590c32327ce375	2025-05-19 05:46:12.48731	\N	\N
13	4	scrypt:32768:8:1$dlK0TERHXR7iv07e$2d0d5006287b9e33419f09dd13b0e041fca16c694c31a068ac299718fb40073aac30e78c2d307858ebb79177322b7dff2cac4dd1b10305a74884d489759c1877	2025-05-19 06:28:28.581399	\N	\N
16	5	scrypt:32768:8:1$LvbihhpOXbcYalnV$c0c624cb412692139c866216202ff331402fd732130c21f17fd5af5e89c6c3cdebbac3018b81438fa110d7dc515aa828251a078322fc89427a8573573e9fc6e9	2025-05-19 13:07:31.791078	\N	\N
17	5	scrypt:32768:8:1$Kk3gKfQFm0dicJiq$c454b21bb324c719635150064122afbdd537aadc69d3719827f936cc0be53f627605a41ad34c78a57be17d1912b9d5db726ff37be18259a5bcc3f55f1fefdb03	2025-05-19 13:08:34.854342	\N	\N
12	\N	scrypt:32768:8:1$4jzul4EErVMrwlJ5$f9fefbd0d5f40353c2f54aa9bf60f62df8ecc0c9b82909ee2443a92a63e9d2def7ad2bfe693c4e1d11c5186fcc5cdf40bb94c60c8224cca1f8043c814517b423	2025-05-19 06:01:02.624825	\N	1
18	6	scrypt:32768:8:1$36YFk93hTtWnh1TE$59171e33385064728fc9da2ad9a5bcbf98d90bc9b9676570cb0d08a86f91f3453d3b6e7ad238c768890b3f0b933766d51c59222ee57e22cd91bb57c00c1af8ed	2025-05-20 21:31:45.710134	\N	\N
19	7	scrypt:32768:8:1$6bOswITOEDrP9wWK$20a6ef5ed2182b67cf5a9c22390f29ee122b3668adb847bbb93e988a1317819341bb0d6fb6a05b1514b9d956a1a936974436808805d2b73626b3bae76ece9339	2025-05-20 23:13:32.980262	\N	\N
\.


--
-- Data for Name: incidencias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.incidencias (id_incidencias, url_img, id_usuario, id_pqrs, id_empleado, correo, ubicacion) FROM stdin;
1	c	1	457d26b9-1d09-4704-83f0-af5b9d79fef9	6	\N	\N
2	a	1	ef9d9e1a-4360-4f15-b7b0-2b0f5afc7479	6	\N	\N
3	f	1	291eb4b2-e136-48e2-b3d4-41e92b0f81f7	6	\N	\N
4	b	7	d0da8452-2caa-4333-80c9-1f5727b9d67e	6	\N	\N
\.


--
-- Data for Name: intentos_login; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.intentos_login (id_intento, id_usuario, exito, fecha_intento, ip_origen, user_agent) FROM stdin;
\.


--
-- Data for Name: noticias_ambientales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.noticias_ambientales (id_noticia, id_tags, id_fuentes, contenido, titulo, id_region) FROM stdin;
1	1	1	Aunque hace muchos a├▒os los gatos eran considerados como ÔÇ£diosesÔÇØ, sobre todo en el antiguo Egipto, gracias a su fuerza, inteligencia y velocidad, hoy el panorama que vemos es distinto.\r\n\r\nDe acuerdo con la senadora Andrea Padilla, m├ís de tres millones de gatos (y tambi├®n perros) se encuentran en situaci├│n de calle en el pa├¡s, siendo la costa caribe una de las zonas m├ís cr├¡ticas para ellos.\r\n\r\nPor esta raz├│n, la Polic├¡a de la estaci├│n del municipio de Mompox, Bol├¡var, le hicieron frente a una situaci├│n que se hab├¡a vuelto cotidiana para muchas personas, pero inaceptable para ellos: el abandono de varios gatos en el cementerio principal.\r\n\r\nDe acuerdo con la instituci├│n, m├ís de 150 gatos fueron dejados en ese inadecuado escenario para vivir, ÔÇ£al final ellos tuvieron que, con su fuerza, convertir este lugar en su hogarÔÇØ, indica la Polic├¡a Nacional.\r\n\r\nAnte estos desgarradores hechos, los uniformados pusieron en marcha una estrategia para que a estos animalitos no les falte comida, pero, sobre todo, protegerla de la lluvia y de la humedad.\r\n\r\nSe trata de la instalaci├│n de varios tubos en PVC ubicados en partes estrat├®gicas del cementerio que ser├ín llenados por comida y esta ir├í bajando a medida que se vaya consumiendo. Adem├ís de ayudar a los animales, tambi├®n se utilizar├í material reciclable para la construcci├│n de estos comederos y bebederos.\r\n\r\nÔÇ£Hoy, con la satisfacci├│n de haber sido parte de esta iniciativa, queda el sin sabor de ver como las personas son capaces de sacar de sus casas y botar a un animal, quit├índole la oportunidad de tener un refugio, un hogar, una familia. Porque s├¡, en eso nos convertimos para ellos, su familiaÔÇØ, indica la instituci├│n a trav├®s de un comunicado e invita a que las personas donen concentrado para alimentar a los animales.\r\n\r\nAsimismo, la entidad tambi├®n indic├│ que trabajar├í en la promoci├│n de jornadas de esterilizaci├│n por el bienestar de los felinos para que no siga creciendo el n├║mero de gatos en estas condiciones.\r\n\r\n┬┐Por qu├® hay tantos gatos en el cementerio de Mompox?\r\nEste inspirador pueblo siempre ha dado de qu├® hablar gracias a las historias que se encuentran en los libros de Gabriel Garc├¡a M├írquez. Sin embargo, hay otra historia que alimenta la curiosidad de las personas que suelen visitar este municipio: la presencia de gatos en el cementerio.\r\n\r\nDe acuerdo con el diario El Heraldo, desde la muerte de Alfredo Serrano, hijo de un exalcalde, varios felinos se pasean entre las tumbas de quienes portan este apellido.\r\n\r\nSeg├║n explica el diario, los Serrano son una familia nacida y radicada en ese municipio, en el departamento de Bol├¡var, y sienten orgullo del reconocimiento que ha generado su apellido ante la custodia de los felinos. ÔÇ£A nosotros no nos incomoda, al contrario, nos parece estupendo porque eso nos da un mayor reconocimientoÔÇØ, dijo a AFP V├¡ctor Serrano, habitante del municipio.\r\n\r\nAl parecer, todo inici├│ cuando un gato negro se pos├│ encima de la tumba de Alfredo Serrano y se qued├│ a vivir all├¡ gracias a que el padre de Alfredo comenz├│ a dejarle comida. ÔÇ£Nosotros quedamos asistiendo a la b├│veda de ├®l, al cementerio ├¡bamos casi todas las tardesÔÇØ, agrega Victor.\r\n\r\nLuego de varios a├▒os, muchos gatos llegaron a vivir en el lugar, incluso, algunos han sido abandonados. De esta forma, viven bajo los cuidados de las autoridades y los habitantes del municipio, quienes tambi├®n se muestran preocupados por el tema de salud p├║blica debido a las altas tasas de reproducci├│n que podr├¡an llegar a tener estos animales.	Polic├¡a instala dispensadores con comida para gatos abandonados en Mompox	2
2	2	2	Tanto los bosques como los sistemas de agua dulce de la Amazon├¡a est├ín en riesgo. Desde el a├▒o 2000, las precipitaciones en la selva amaz├│nica han disminuido un 69%. Y si el ritmo actual de deforestaci├│n contin├║a, WWF estima que el 27% del bioma amaz├│nico se quedar├í sin ├írboles para el a├▒o 2030. Proteger y conservar la Amazon├¡a no es una tarea f├ícil, pero WWF ha estado trabajando para salvar este importante sitio.	┬┐Cu├íles animales viven en la Amazon├¡a? Este y otros 8 datos sobre la Amazon├¡a	5
\.


--
-- Data for Name: notificaciones_alertas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notificaciones_alertas (id_notificacion, id_usuario, id_alerta, estado_notificacion, fecha_notificacion) FROM stdin;
\.


--
-- Data for Name: ong; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ong (id_ong, nombre_ong, contacto_ong, direccion_ong, email_ong, telefono_ong, id_tipo_ong, rol, activo) FROM stdin;
1	Cruz Roja	Juan P├®rez	Av. Siempre Viva 123	cruzroja@example.com	555-1234	6	4	t
2	Educando Juntos	Laura G├│mez	Calle Educaci├│n 45	educando@example.com	555-2345	2	4	t
4	EcoVida	Carlos R├¡os	Bosque Central 99	ecovida@example.com	555-4567	3	4	t
5	Manos Unidas	Elena D├¡az	Calle Ayuda 12	manosunidas@example.com	555-5678	4	4	t
7	Cultura Viva	Andrea Ruiz	Teatro Central 7	cultura@example.com	555-7890	7	4	t
6	Patitas Felices	Mario Casta├▒o	Av. Mascotas 21	patitas@example.com	555-6789	5	4	t
\.


--
-- Data for Name: permisos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permisos (id_permiso, nombre_permiso) FROM stdin;
\.


--
-- Data for Name: pqrs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pqrs (id, tipo, descripcion, estado, usuario_id) FROM stdin;
457d26b9-1d09-4704-83f0-af5b9d79fef9	queja	etfgegsrghrfge	resuelto	1
291eb4b2-e136-48e2-b3d4-41e92b0f81f7	petici├│n	Pongan mas opciones de especies y mas notas :)	resuelto	1
ef9d9e1a-4360-4f15-b7b0-2b0f5afc7479	queja	No me parece :c	resuelto	1
d0da8452-2caa-4333-80c9-1f5727b9d67e	queja	No habia ningun Gael en medellin colombia que fuese adoptado :(	resuelto	7
\.


--
-- Data for Name: preferencias_notificacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.preferencias_notificacion (id_preferencia, id_notificacion, id_usuario, frecuencia_notificacion) FROM stdin;
\.


--
-- Data for Name: regiones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.regiones (id_region, nombre_region, descripcion_region, id_tags) FROM stdin;
1	Amazon├¡a	Regi├│n selv├ítica ubicada al sur del pa├¡s, caracterizada por su alta biodiversidad y clima h├║medo.	\N
2	Andina	Regi├│n monta├▒osa atravesada por la cordillera de los Andes; concentra gran parte de la poblaci├│n y biodiversidad.	\N
3	Caribe	Regi├│n costera al norte, con playas, manglares y una gran riqueza cultural.	\N
4	Pac├¡fica	Regi├│n h├║meda y biodiversa a lo largo de la costa del oc├®ano Pac├¡fico, con selvas tropicales y alta pluviosidad.	\N
5	Orinoqu├¡a	Regi├│n de llanuras al oriente del pa├¡s, caracterizada por sabanas, r├¡os y ganader├¡a extensiva.	\N
6	Insular	Regi├│n compuesta por islas como San Andr├®s, Providencia y Santa Catalina, con ecosistemas marinos ├║nicos.	\N
\.


--
-- Data for Name: reportes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reportes (id_reporte, id_usuario, id_tipo_reporte, descripcion, fecha_reporte, foto_url, id_alerta, direccion) FROM stdin;
5	1	2	vi una mariposita herida en la plaza	2025-05-19 02:27:08.438156	https://res.cloudinary.com/dhaneunlu/image/upload/v1747639627/k1s0yyh0u6ktdlll4a9u.jpg	36	plaza
6	1	2	se encontro un gato herido	2025-05-20 21:34:58.901094	https://res.cloudinary.com/dhaneunlu/image/upload/v1747794896/afgadhqghb33wfvwxzeq.jpg	40	Bulevar 42
7	7	1	My inaceptable reaction cuando	2025-05-20 23:31:42.16344	https://res.cloudinary.com/dhaneunlu/image/upload/v1747801901/znh4swc4setumcqquaha.jpg	43	Carrera 71, Pontevedra, UPZ La Floresta, Localidad Suba, Bogot├í, Bogot├í, Distrito Capital, RAP (Especial) Central, 111121, Colombia
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id_rol, nombre_rol, descripcion_rol) FROM stdin;
1	visitante	\N
2	biologo	\N
3	moderador	\N
4	ONG	\N
5	admin	\N
\.


--
-- Data for Name: roles_permisos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles_permisos (id_rol, id_permiso) FROM stdin;
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tags (id_tags, nombre_tag) FROM stdin;
1	Comunidad y Participaci├│n
2	Conservaci├│n
\.


--
-- Data for Name: tipos_accion_ong; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_accion_ong (id_tipo_accion, nombre_accion) FROM stdin;
\.


--
-- Data for Name: tipos_alertas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_alertas (id_tipo_alerta, nombre_tipo_alerta, descripcion_tipo_alerta) FROM stdin;
1	rechazo_reporte	\N
2	aprobado_reporte	\N
3	en_revision_reporte	\N
4	en_revision_avistamiento	\N
5	rechazo_avistamiento	\N
6	aprovado_avistamiento	\N
7	ONG_tomo_caso	\N
8	reporte_eliminado	\N
9	avistamiento_eliminado	\N
10	suspendido	\N
11	cuenta borrada	\N
\.


--
-- Data for Name: tipos_especies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_especies (id_tipo_especie, nombre_tipo_especie, descripcion_tipo_especie) FROM stdin;
1	En peligro	Especies cuya poblaci├│n ha disminuido dr├ísticamente y se encuentran en riesgo de extinci├│n.
2	Com├║n	Especies que se encuentran frecuentemente en su h├íbitat natural y no enfrentan amenazas significativas.
3	Invasora	Especies no nativas que se han establecido en un nuevo ecosistema, desplazando a especies locales.
\.


--
-- Data for Name: tipos_ong; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_ong (id_tipo_ong, nombre_tipo_ong) FROM stdin;
1	Salud
2	Educaci├│n
3	Medio Ambiente
4	Desarrollo Social
5	Protecci├│n Animal
6	Asistencia Humanitaria
7	Cultura y Recreaci├│n
\.


--
-- Data for Name: tipos_reportes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_reportes (id_tipo_reporte, nombre_tipo_reporte, descripcion_tipo_reporte) FROM stdin;
1	abejas/palomas	solo se puede tratar por localidades
2	perros/gatos	se atienden casos individuales
\.


--
-- Name: acciones_ong_reportes_id_accion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.acciones_ong_reportes_id_accion_seq', 1, false);


--
-- Name: alertas_id_alerta_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alertas_id_alerta_seq', 43, true);


--
-- Name: avistamientos_id_avistamiento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.avistamientos_id_avistamiento_seq', 9, true);


--
-- Name: chat_pqrs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_pqrs_id_seq', 20, true);


--
-- Name: cliente_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cliente_id_usuario_seq', 7, true);


--
-- Name: comentarios_reportes_id_comentario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comentarios_reportes_id_comentario_seq', 1, false);


--
-- Name: ecosistema_id_ecosistema_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ecosistema_id_ecosistema_seq', 10, true);


--
-- Name: educacion_ambiental_id_educacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.educacion_ambiental_id_educacion_seq', 1, false);


--
-- Name: empleados_id_empleado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.empleados_id_empleado_seq', 6, true);


--
-- Name: especies_id_especie_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.especies_id_especie_seq', 8, true);


--
-- Name: especies_regiones_especies_id_especie_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.especies_regiones_especies_id_especie_seq', 1, false);


--
-- Name: especies_regiones_regiones_id_region_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.especies_regiones_regiones_id_region_seq', 1, false);


--
-- Name: fotos_especies_id_foto_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fotos_especies_id_foto_seq', 1, false);


--
-- Name: fuentes_id_fuentes_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fuentes_id_fuentes_seq', 2, true);


--
-- Name: historial_contrasenas_id_historial_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.historial_contrasenas_id_historial_seq', 19, true);


--
-- Name: incidencias_id_incidencias_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.incidencias_id_incidencias_seq', 4, true);


--
-- Name: incidencias_id_pqrs_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.incidencias_id_pqrs_seq', 1, false);


--
-- Name: incidencias_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.incidencias_id_usuario_seq', 1, false);


--
-- Name: intentos_login_id_intento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.intentos_login_id_intento_seq', 1, false);


--
-- Name: noticias_ambientales_id_noticia_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.noticias_ambientales_id_noticia_seq', 2, true);


--
-- Name: notificaciones_alertas_id_notificacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notificaciones_alertas_id_notificacion_seq', 1, false);


--
-- Name: ong_id_ong_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ong_id_ong_seq', 1, false);


--
-- Name: permisos_id_permiso_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permisos_id_permiso_seq', 1, false);


--
-- Name: pqrs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pqrs_id_seq', 1, false);


--
-- Name: preferencias_notificacion_id_preferencia_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.preferencias_notificacion_id_preferencia_seq', 1, false);


--
-- Name: regiones_id_region_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.regiones_id_region_seq', 6, true);


--
-- Name: reportes_id_reporte_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reportes_id_reporte_seq', 7, true);


--
-- Name: roles_id_rol_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_rol_seq', 5, true);


--
-- Name: tags_id_tags_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tags_id_tags_seq', 2, true);


--
-- Name: tipos_accion_ong_id_tipo_accion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_accion_ong_id_tipo_accion_seq', 1, false);


--
-- Name: tipos_alertas_id_tipo_alerta_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_alertas_id_tipo_alerta_seq', 3, true);


--
-- Name: tipos_especies_id_tipo_especie_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_especies_id_tipo_especie_seq', 1, false);


--
-- Name: tipos_ong_id_tipo_ong_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_ong_id_tipo_ong_seq', 1, false);


--
-- Name: tipos_reportes_id_tipo_reporte_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_reportes_id_tipo_reporte_seq', 2, true);


--
-- Name: acciones_ong_reportes acciones_ong_reportes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acciones_ong_reportes
    ADD CONSTRAINT acciones_ong_reportes_pkey PRIMARY KEY (id_accion);


--
-- Name: alertas alertas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_pkey PRIMARY KEY (id_alerta);


--
-- Name: avistamientos avistamientos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avistamientos
    ADD CONSTRAINT avistamientos_pkey PRIMARY KEY (id_avistamiento);


--
-- Name: chat_pqrs chat_pqrs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_pqrs
    ADD CONSTRAINT chat_pqrs_pkey PRIMARY KEY (id);


--
-- Name: comentarios_reportes comentarios_reportes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comentarios_reportes
    ADD CONSTRAINT comentarios_reportes_pkey PRIMARY KEY (id_comentario);


--
-- Name: ecosistema ecosistema_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ecosistema
    ADD CONSTRAINT ecosistema_pkey PRIMARY KEY (id_ecosistema);


--
-- Name: educacion_ambiental educacion_ambiental_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.educacion_ambiental
    ADD CONSTRAINT educacion_ambiental_pkey PRIMARY KEY (id_educacion);


--
-- Name: especies especies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especies
    ADD CONSTRAINT especies_pkey PRIMARY KEY (id_especie);


--
-- Name: fotos_especies fotos_especies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fotos_especies
    ADD CONSTRAINT fotos_especies_pkey PRIMARY KEY (id_foto);


--
-- Name: fuentes fuentes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fuentes
    ADD CONSTRAINT fuentes_pkey PRIMARY KEY (id_fuentes);


--
-- Name: historial_contrasenas historial_contrasenas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_contrasenas
    ADD CONSTRAINT historial_contrasenas_pkey PRIMARY KEY (id_historial);


--
-- Name: empleados id_empleado; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT id_empleado PRIMARY KEY (id_empleado);


--
-- Name: incidencias id_incidencias; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT id_incidencias PRIMARY KEY (id_incidencias);


--
-- Name: preferencias_notificacion id_preferencia_notificaciones; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.preferencias_notificacion
    ADD CONSTRAINT id_preferencia_notificaciones PRIMARY KEY (id_preferencia);


--
-- Name: intentos_login intentos_login_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intentos_login
    ADD CONSTRAINT intentos_login_pkey PRIMARY KEY (id_intento);


--
-- Name: noticias_ambientales noticias_ambientales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticias_ambientales
    ADD CONSTRAINT noticias_ambientales_pkey PRIMARY KEY (id_noticia);


--
-- Name: notificaciones_alertas notificaciones_alertas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones_alertas
    ADD CONSTRAINT notificaciones_alertas_pkey PRIMARY KEY (id_notificacion);


--
-- Name: ong ong_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ong
    ADD CONSTRAINT ong_pkey PRIMARY KEY (id_ong);


--
-- Name: permisos permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_pkey PRIMARY KEY (id_permiso);


--
-- Name: pqrs pqrs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pqrs
    ADD CONSTRAINT pqrs_pkey PRIMARY KEY (id);


--
-- Name: regiones regiones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.regiones
    ADD CONSTRAINT regiones_pkey PRIMARY KEY (id_region);


--
-- Name: reportes reportes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_pkey PRIMARY KEY (id_reporte);


--
-- Name: roles_permisos roles_permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_pkey PRIMARY KEY (id_rol, id_permiso);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id_rol);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id_tags);


--
-- Name: tipos_accion_ong tipos_accion_ong_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_accion_ong
    ADD CONSTRAINT tipos_accion_ong_pkey PRIMARY KEY (id_tipo_accion);


--
-- Name: tipos_alertas tipos_alertas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_alertas
    ADD CONSTRAINT tipos_alertas_pkey PRIMARY KEY (id_tipo_alerta);


--
-- Name: tipos_especies tipos_especies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_especies
    ADD CONSTRAINT tipos_especies_pkey PRIMARY KEY (id_tipo_especie);


--
-- Name: tipos_ong tipos_ong_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_ong
    ADD CONSTRAINT tipos_ong_pkey PRIMARY KEY (id_tipo_ong);


--
-- Name: tipos_reportes tipos_reportes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_reportes
    ADD CONSTRAINT tipos_reportes_pkey PRIMARY KEY (id_tipo_reporte);


--
-- Name: especies unique_nombre_cientifico; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especies
    ADD CONSTRAINT unique_nombre_cientifico UNIQUE (nombre_cientifico);


--
-- Name: cliente usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- Name: cliente usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);


--
-- Name: intentos_login tr_limpia_fallos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_limpia_fallos AFTER INSERT ON public.intentos_login FOR EACH ROW EXECUTE FUNCTION public.limpiar_fallos();


--
-- Name: acciones_ong_reportes acciones_ong_reportes_id_ong_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acciones_ong_reportes
    ADD CONSTRAINT acciones_ong_reportes_id_ong_fkey FOREIGN KEY (id_ong) REFERENCES public.ong(id_ong);


--
-- Name: acciones_ong_reportes acciones_ong_reportes_id_reporte_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acciones_ong_reportes
    ADD CONSTRAINT acciones_ong_reportes_id_reporte_fkey FOREIGN KEY (id_reporte) REFERENCES public.reportes(id_reporte);


--
-- Name: acciones_ong_reportes acciones_ong_reportes_id_tipo_accion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acciones_ong_reportes
    ADD CONSTRAINT acciones_ong_reportes_id_tipo_accion_fkey FOREIGN KEY (id_tipo_accion) REFERENCES public.tipos_accion_ong(id_tipo_accion);


--
-- Name: alertas alertas_id_tipo_alerta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_id_tipo_alerta_fkey FOREIGN KEY (id_tipo_alerta) REFERENCES public.tipos_alertas(id_tipo_alerta);


--
-- Name: avistamientos avistamientos_id_especie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avistamientos
    ADD CONSTRAINT avistamientos_id_especie_fkey FOREIGN KEY (id_especie) REFERENCES public.especies(id_especie);


--
-- Name: avistamientos avistamientos_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avistamientos
    ADD CONSTRAINT avistamientos_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.cliente(id_usuario);


--
-- Name: chat_pqrs chat_pqrs_id_pqrs_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_pqrs
    ADD CONSTRAINT chat_pqrs_id_pqrs_fkey FOREIGN KEY (id_pqrs) REFERENCES public.pqrs(id);


--
-- Name: comentarios_reportes comentarios_reportes_id_reporte_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comentarios_reportes
    ADD CONSTRAINT comentarios_reportes_id_reporte_fkey FOREIGN KEY (id_reporte) REFERENCES public.reportes(id_reporte);


--
-- Name: comentarios_reportes comentarios_reportes_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comentarios_reportes
    ADD CONSTRAINT comentarios_reportes_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.cliente(id_usuario);


--
-- Name: educacion_ambiental educacion_ambiental_id_fuentes_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.educacion_ambiental
    ADD CONSTRAINT educacion_ambiental_id_fuentes_fkey FOREIGN KEY (id_fuentes) REFERENCES public.fuentes(id_fuentes);


--
-- Name: educacion_ambiental educacion_ambiental_id_region_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.educacion_ambiental
    ADD CONSTRAINT educacion_ambiental_id_region_fkey FOREIGN KEY (id_region) REFERENCES public.regiones(id_region);


--
-- Name: educacion_ambiental educacion_ambiental_id_tags_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.educacion_ambiental
    ADD CONSTRAINT educacion_ambiental_id_tags_fkey FOREIGN KEY (id_tags) REFERENCES public.tags(id_tags);


--
-- Name: especies especies_id_ecosistema_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especies
    ADD CONSTRAINT especies_id_ecosistema_fkey FOREIGN KEY (id_ecosistema) REFERENCES public.ecosistema(id_ecosistema);


--
-- Name: especies especies_id_tipo_especie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especies
    ADD CONSTRAINT especies_id_tipo_especie_fkey FOREIGN KEY (id_tipo_especie) REFERENCES public.tipos_especies(id_tipo_especie);


--
-- Name: especies_regiones especies_regiones_especies_id_especie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especies_regiones
    ADD CONSTRAINT especies_regiones_especies_id_especie_fkey FOREIGN KEY (especies_id_especie) REFERENCES public.especies(id_especie) NOT VALID;


--
-- Name: especies_regiones especies_regiones_regiones_id_region_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especies_regiones
    ADD CONSTRAINT especies_regiones_regiones_id_region_fkey FOREIGN KEY (regiones_id_region) REFERENCES public.regiones(id_region) NOT VALID;


--
-- Name: avistamientos fk_alerta; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avistamientos
    ADD CONSTRAINT fk_alerta FOREIGN KEY (alerta_id) REFERENCES public.alertas(id_alerta);


--
-- Name: historial_contrasenas fk_empleado; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_contrasenas
    ADD CONSTRAINT fk_empleado FOREIGN KEY (id_empleado) REFERENCES public.empleados(id_empleado) ON DELETE CASCADE;


--
-- Name: historial_contrasenas fk_ong; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_contrasenas
    ADD CONSTRAINT fk_ong FOREIGN KEY (ong_id) REFERENCES public.ong(id_ong) ON DELETE CASCADE;


--
-- Name: noticias_ambientales fk_region_noticias; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticias_ambientales
    ADD CONSTRAINT fk_region_noticias FOREIGN KEY (id_region) REFERENCES public.regiones(id_region) ON DELETE SET NULL;


--
-- Name: fotos_especies fotos_especies_id_especie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fotos_especies
    ADD CONSTRAINT fotos_especies_id_especie_fkey FOREIGN KEY (id_especie) REFERENCES public.especies(id_especie);


--
-- Name: historial_contrasenas historial_contrasenas_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_contrasenas
    ADD CONSTRAINT historial_contrasenas_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.cliente(id_usuario) ON DELETE CASCADE;


--
-- Name: incidencias id_empleado; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT id_empleado FOREIGN KEY (id_empleado) REFERENCES public.empleados(id_empleado) NOT VALID;


--
-- Name: preferencias_notificacion id_notificaciones; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.preferencias_notificacion
    ADD CONSTRAINT id_notificaciones FOREIGN KEY (id_notificacion) REFERENCES public.notificaciones_alertas(id_notificacion) NOT VALID;


--
-- Name: empleados id_rol; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT id_rol FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol) NOT VALID;


--
-- Name: incidencias id_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT id_usuario FOREIGN KEY (id_usuario) REFERENCES public.cliente(id_usuario) NOT VALID;


--
-- Name: preferencias_notificacion id_usuarios; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.preferencias_notificacion
    ADD CONSTRAINT id_usuarios FOREIGN KEY (id_usuario) REFERENCES public.cliente(id_usuario) NOT VALID;


--
-- Name: incidencias incidencias_id_pqrs_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_id_pqrs_fkey FOREIGN KEY (id_pqrs) REFERENCES public.pqrs(id);


--
-- Name: intentos_login intentos_login_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intentos_login
    ADD CONSTRAINT intentos_login_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.cliente(id_usuario);


--
-- Name: noticias_ambientales noticias_ambientales_id_fuentes_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticias_ambientales
    ADD CONSTRAINT noticias_ambientales_id_fuentes_fkey FOREIGN KEY (id_fuentes) REFERENCES public.fuentes(id_fuentes);


--
-- Name: noticias_ambientales noticias_ambientales_id_tags_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticias_ambientales
    ADD CONSTRAINT noticias_ambientales_id_tags_fkey FOREIGN KEY (id_tags) REFERENCES public.tags(id_tags);


--
-- Name: notificaciones_alertas notificaciones_alertas_id_alerta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones_alertas
    ADD CONSTRAINT notificaciones_alertas_id_alerta_fkey FOREIGN KEY (id_alerta) REFERENCES public.alertas(id_alerta);


--
-- Name: notificaciones_alertas notificaciones_alertas_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones_alertas
    ADD CONSTRAINT notificaciones_alertas_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.cliente(id_usuario);


--
-- Name: ong ong_id_tipo_ong_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ong
    ADD CONSTRAINT ong_id_tipo_ong_fkey FOREIGN KEY (id_tipo_ong) REFERENCES public.tipos_ong(id_tipo_ong);


--
-- Name: pqrs pqrs_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pqrs
    ADD CONSTRAINT pqrs_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.cliente(id_usuario) ON DELETE CASCADE;


--
-- Name: reportes reportes_id_tipo_reporte_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_id_tipo_reporte_fkey FOREIGN KEY (id_tipo_reporte) REFERENCES public.tipos_reportes(id_tipo_reporte);


--
-- Name: reportes reportes_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.cliente(id_usuario) ON DELETE CASCADE;


--
-- Name: roles_permisos roles_permisos_id_permiso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_id_permiso_fkey FOREIGN KEY (id_permiso) REFERENCES public.permisos(id_permiso);


--
-- Name: roles_permisos roles_permisos_id_rol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- Name: FUNCTION limitar_historial_contrasenas(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.limitar_historial_contrasenas() TO dottoooo;


--
-- Name: FUNCTION limpiar_fallos(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.limpiar_fallos() TO dottoooo;


--
-- Name: TABLE acciones_ong_reportes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.acciones_ong_reportes TO dottoooo;


--
-- Name: SEQUENCE acciones_ong_reportes_id_accion_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.acciones_ong_reportes_id_accion_seq TO dottoooo;


--
-- Name: TABLE alertas; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.alertas TO dottoooo;


--
-- Name: SEQUENCE alertas_id_alerta_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.alertas_id_alerta_seq TO dottoooo;


--
-- Name: TABLE avistamientos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.avistamientos TO dottoooo;


--
-- Name: SEQUENCE avistamientos_id_avistamiento_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.avistamientos_id_avistamiento_seq TO dottoooo;


--
-- Name: TABLE chat_pqrs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.chat_pqrs TO dottoooo;
GRANT ALL ON TABLE public.chat_pqrs TO admin WITH GRANT OPTION;


--
-- Name: TABLE cliente; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cliente TO dottoooo;


--
-- Name: SEQUENCE cliente_id_usuario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.cliente_id_usuario_seq TO dottoooo;


--
-- Name: TABLE comentarios_reportes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.comentarios_reportes TO dottoooo;


--
-- Name: SEQUENCE comentarios_reportes_id_comentario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.comentarios_reportes_id_comentario_seq TO dottoooo;


--
-- Name: TABLE ecosistema; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ecosistema TO dottoooo;


--
-- Name: SEQUENCE ecosistema_id_ecosistema_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.ecosistema_id_ecosistema_seq TO dottoooo;


--
-- Name: TABLE educacion_ambiental; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.educacion_ambiental TO dottoooo;


--
-- Name: SEQUENCE educacion_ambiental_id_educacion_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.educacion_ambiental_id_educacion_seq TO dottoooo;


--
-- Name: TABLE empleados; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.empleados TO dottoooo;


--
-- Name: SEQUENCE empleados_id_empleado_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.empleados_id_empleado_seq TO dottoooo;


--
-- Name: TABLE especies; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.especies TO dottoooo;


--
-- Name: SEQUENCE especies_id_especie_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.especies_id_especie_seq TO dottoooo;


--
-- Name: TABLE especies_regiones; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.especies_regiones TO dottoooo;


--
-- Name: SEQUENCE especies_regiones_especies_id_especie_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.especies_regiones_especies_id_especie_seq TO dottoooo;


--
-- Name: SEQUENCE especies_regiones_regiones_id_region_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.especies_regiones_regiones_id_region_seq TO dottoooo;


--
-- Name: TABLE fotos_especies; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.fotos_especies TO dottoooo;


--
-- Name: SEQUENCE fotos_especies_id_foto_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.fotos_especies_id_foto_seq TO dottoooo;


--
-- Name: TABLE fuentes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.fuentes TO dottoooo;


--
-- Name: SEQUENCE fuentes_id_fuentes_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.fuentes_id_fuentes_seq TO dottoooo;


--
-- Name: TABLE historial_contrasenas; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.historial_contrasenas TO dottoooo;


--
-- Name: SEQUENCE historial_contrasenas_id_historial_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.historial_contrasenas_id_historial_seq TO dottoooo;


--
-- Name: TABLE incidencias; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.incidencias TO dottoooo;


--
-- Name: SEQUENCE incidencias_id_pqrs_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.incidencias_id_pqrs_seq TO dottoooo;


--
-- Name: SEQUENCE incidencias_id_usuario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.incidencias_id_usuario_seq TO dottoooo;


--
-- Name: TABLE intentos_login; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.intentos_login TO dottoooo;


--
-- Name: SEQUENCE intentos_login_id_intento_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.intentos_login_id_intento_seq TO dottoooo;


--
-- Name: TABLE noticias_ambientales; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.noticias_ambientales TO dottoooo;


--
-- Name: SEQUENCE noticias_ambientales_id_noticia_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.noticias_ambientales_id_noticia_seq TO dottoooo;


--
-- Name: TABLE notificaciones_alertas; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.notificaciones_alertas TO dottoooo;


--
-- Name: SEQUENCE notificaciones_alertas_id_notificacion_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.notificaciones_alertas_id_notificacion_seq TO dottoooo;


--
-- Name: TABLE ong; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ong TO dottoooo;


--
-- Name: SEQUENCE ong_id_ong_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.ong_id_ong_seq TO dottoooo;


--
-- Name: TABLE permisos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.permisos TO dottoooo;


--
-- Name: SEQUENCE permisos_id_permiso_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.permisos_id_permiso_seq TO dottoooo;


--
-- Name: TABLE pqrs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pqrs TO dottoooo;


--
-- Name: SEQUENCE pqrs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.pqrs_id_seq TO dottoooo;


--
-- Name: TABLE preferencias_notificacion; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.preferencias_notificacion TO dottoooo;


--
-- Name: SEQUENCE preferencias_notificacion_id_preferencia_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.preferencias_notificacion_id_preferencia_seq TO dottoooo;


--
-- Name: TABLE regiones; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.regiones TO dottoooo;


--
-- Name: SEQUENCE regiones_id_region_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.regiones_id_region_seq TO dottoooo;


--
-- Name: TABLE reportes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reportes TO dottoooo;


--
-- Name: SEQUENCE reportes_id_reporte_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.reportes_id_reporte_seq TO dottoooo;


--
-- Name: TABLE roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.roles TO dottoooo;


--
-- Name: SEQUENCE roles_id_rol_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.roles_id_rol_seq TO dottoooo;


--
-- Name: TABLE roles_permisos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.roles_permisos TO dottoooo;


--
-- Name: TABLE tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tags TO dottoooo;


--
-- Name: SEQUENCE tags_id_tags_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.tags_id_tags_seq TO dottoooo;


--
-- Name: TABLE tipos_accion_ong; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tipos_accion_ong TO dottoooo;


--
-- Name: SEQUENCE tipos_accion_ong_id_tipo_accion_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.tipos_accion_ong_id_tipo_accion_seq TO dottoooo;


--
-- Name: TABLE tipos_alertas; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tipos_alertas TO dottoooo;


--
-- Name: SEQUENCE tipos_alertas_id_tipo_alerta_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.tipos_alertas_id_tipo_alerta_seq TO dottoooo;


--
-- Name: TABLE tipos_especies; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tipos_especies TO dottoooo;


--
-- Name: SEQUENCE tipos_especies_id_tipo_especie_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.tipos_especies_id_tipo_especie_seq TO dottoooo;


--
-- Name: TABLE tipos_ong; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tipos_ong TO dottoooo;


--
-- Name: SEQUENCE tipos_ong_id_tipo_ong_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.tipos_ong_id_tipo_ong_seq TO dottoooo;


--
-- Name: TABLE tipos_reportes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tipos_reportes TO dottoooo;


--
-- Name: SEQUENCE tipos_reportes_id_tipo_reporte_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.tipos_reportes_id_tipo_reporte_seq TO dottoooo;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO dottoooo;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TABLES TO admin WITH GRANT OPTION;


--
-- PostgreSQL database dump complete
--

