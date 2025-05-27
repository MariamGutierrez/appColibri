# Colibri Project - Railway Deployment Guide

## 1. Estructura de archivos relevante

- `project/app.py` (aplicación Flask principal)
- `project/db.py` (conexión a base de datos)
- `requirements.txt` (dependencias Python)
- `Procfile` (comando para Railway/Gunicorn)
- `railway.json` (configuración Railway)
- `.env.example` (ejemplo de variables de entorno)

## 2. Variables de entorno necesarias

Crea un archivo `.env` en la raíz del proyecto (o usa el panel de Railway) con:

```
DATABASE_URL=postgresql://user:password@host:port/dbname
CLOUDINARY_CLOUD_NAME=dhaneunlu
CLOUDINARY_API_KEY=176747317263595
CLOUDINARY_API_SECRET=6a959CR7AvrMfAL94jyUJ56jKU8
SECRET_KEY=clave_secreta_segura
EMAIL_SENDER=your_email@gmail.com
EMAIL_PASSWORD=your_email_password
```

## 3. Requisitos para Railway

- Python 3.10+ (Railway lo detecta por `requirements.txt` y/o `railway.json`)
- `gunicorn` debe estar en `requirements.txt` (ya está)
- El archivo `Procfile` debe contener:
  ```
  web: gunicorn project.app:app
  ```
- El archivo `railway.json` debe tener:
  ```json
  {
    "build": {
      "env": {
        "PYTHON_VERSION": "3.10"
      }
    },
    "deploy": {
      "startCommand": "gunicorn project.app:app"
    }
  }
  ```

## 4. Pasos para desplegar en Railway

1. Sube el proyecto a GitHub.
2. Crea un nuevo proyecto en Railway y conecta tu repo.
3. Configura las variables de entorno en Railway (usa `.env.example` como guía).
4. Railway instalará dependencias y ejecutará el comando del `Procfile`.
5. Accede a la URL pública que te da Railway.

## 5. Notas
- Si usas archivos estáticos o subidas, asegúrate de que la carpeta `static/uploads` exista y esté en `.gitignore` si no quieres subir archivos locales.
- Para debug, revisa los logs de Railway.
- Si tienes problemas de importación de módulos, asegúrate de que los imports sean relativos o que el `sys.path` esté correctamente configurado (ya ajustado en `app.py`).

---

¡Listo para Railway! 🚀
