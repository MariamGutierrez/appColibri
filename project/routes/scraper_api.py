from fastapi import FastAPI, BackgroundTasks, Query
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import requests
from bs4 import BeautifulSoup
import re
from datetime import datetime
import sys
import os
import psycopg2
from psycopg2.extras import DictCursor
import logging
from typing import List, Optional

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Agregar el directorio padre al path para importar db.py
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from db import get_db

app = FastAPI(title="Colibri News Scraper API", 
              description="API para extraer noticias ambientales automáticamente")

# Configurar CORS para permitir solicitudes desde la aplicación principal
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especifica los orígenes exactos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/scrape_noticias", response_model=List[dict])
async def scrape_noticias():
    """
    Extrae noticias de la página principal de noticiasambientales.com
    """
    url = "https://noticiasambientales.com/"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        noticias = []
        
        # Iterar sobre los artículos en la página
        for articulo in soup.select("article"):
            titulo_elem = articulo.select_one("h2, h3, h4")
            resumen_elem = articulo.select_one("p")
            enlace_elem = articulo.select_one("a")
            fecha_elem = articulo.select_one(".date, .tiempo, time")
            imagen_elem = articulo.select_one("img")
            categoria_elem = articulo.select_one(".categoria, .category")
            
            # Extraer datos con manejo de excepciones
            try:
                titulo = titulo_elem.get_text(strip=True) if titulo_elem else "Sin título"
                resumen = resumen_elem.get_text(strip=True) if resumen_elem else "Sin resumen"
                enlace = enlace_elem['href'] if enlace_elem and enlace_elem.has_attr('href') else "#"
                
                # Normalizar URL si es relativa
                if enlace.startswith("/"):
                    enlace = f"https://noticiasambientales.com{enlace}"
                
                # Extraer fecha
                fecha = fecha_elem.get_text(strip=True) if fecha_elem else None
                
                # Extraer imagen
                imagen_url = None
                if imagen_elem and imagen_elem.has_attr('src'):
                    imagen_url = imagen_elem['src']
                elif imagen_elem and imagen_elem.has_attr('data-src'):
                    imagen_url = imagen_elem['data-src']
                
                # Extraer categoría
                categoria = categoria_elem.get_text(strip=True) if categoria_elem else "General"
                
                # Intentar cargar y extraer contenido completo
                contenido_completo = obtener_contenido_completo(enlace) if enlace != "#" else resumen
                
                noticia = {
                    "titulo": titulo,
                    "resumen": resumen,
                    "contenido": contenido_completo,
                    "link": enlace,
                    "fecha": fecha,
                    "imagen_url": imagen_url,
                    "categoria": categoria
                }
                noticias.append(noticia)
            except Exception as e:
                logger.error(f"Error procesando artículo: {e}")
                continue
        
        return noticias
    
    except Exception as e:
        logger.error(f"Error en scrape_noticias: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})

def obtener_contenido_completo(url):
    """
    Extrae el contenido completo de una noticia individual
    """
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Intentar encontrar el contenido principal (ajustar selectores según el sitio)
        contenido_elem = soup.select_one(".content, .article-content, .post-content, article")
        
        if contenido_elem:
            # Extraer todos los párrafos
            parrafos = contenido_elem.select("p")
            contenido = " ".join([p.get_text() for p in parrafos])
            return contenido
        else:
            return "No se pudo extraer el contenido completo."
    except Exception as e:
        logger.error(f"Error obteniendo contenido completo: {e}")
        return "Error al cargar el contenido completo."

@app.get("/guardar_noticias_db")
async def guardar_noticias_db(background_tasks: BackgroundTasks):
    """
    Extrae noticias y las guarda en la base de datos
    """
    background_tasks.add_task(procesar_y_guardar_noticias)
    return {"mensaje": "Iniciando proceso de extracción y guardado de noticias"}

async def procesar_y_guardar_noticias():
    """
    Función en segundo plano para procesar y guardar noticias
    """
    try:
        noticias = await scrape_noticias()
        db = get_db()
        
        with db.cursor() as cur:
            noticias_guardadas = 0
            
            for noticia in noticias:
                try:
                    # 1. Verificar si la noticia ya existe por título
                    cur.execute("SELECT id_noticia FROM noticias_ambientales WHERE titulo = %s", (noticia['titulo'],))
                    if cur.fetchone():
                        continue
                    
                    # 2. Verificar/crear tag para categoría
                    cur.execute("SELECT id_tags FROM tags WHERE nombre_tag = %s", (noticia['categoria'],))
                    tag_result = cur.fetchone()
                    
                    if tag_result:
                        id_tag = tag_result[0]
                    else:
                        cur.execute("INSERT INTO tags (nombre_tag) VALUES (%s) RETURNING id_tags", (noticia['categoria'],))
                        id_tag = cur.fetchone()[0]
                    
                    # 3. Insertar fuente
                    cur.execute("""
                        INSERT INTO fuentes (link_fuente, tipo_fuente, titulo_fuente, fecha_fuente)
                        VALUES (%s, %s, %s, %s) RETURNING id_fuentes
                    """, (noticia['link'], 'web', noticia['titulo'], datetime.now().strftime('%Y-%m-%d')))
                    id_fuente = cur.fetchone()[0]
                    
                    # 4. Insertar noticia
                    cur.execute("""
                        INSERT INTO noticias_ambientales (id_tags, id_fuentes, contenido, titulo, fecha_publicacion)
                        VALUES (%s, %s, %s, %s, %s) RETURNING id_noticia
                    """, (id_tag, id_fuente, noticia['contenido'], noticia['titulo'], datetime.now().strftime('%Y-%m-%d')))
                    id_noticia = cur.fetchone()[0]
                    
                    # 5. Si hay imagen, guardarla
                    if noticia.get('imagen_url'):
                        cur.execute("""
                            INSERT INTO media (tipo, ruta, descripcion)
                            VALUES (%s, %s, %s) RETURNING id_media
                        """, ('imagen', noticia['imagen_url'], f"Imagen para: {noticia['titulo']}"))
                        id_media = cur.fetchone()[0]
                        
                        cur.execute("""
                            INSERT INTO noticia_media (id_noticia, id_media)
                            VALUES (%s, %s)
                        """, (id_noticia, id_media))
                    
                    noticias_guardadas += 1
                    
                except Exception as e:
                    logger.error(f"Error guardando noticia: {e}")
                    continue
            
            db.commit()
            logger.info(f"Se guardaron {noticias_guardadas} noticias nuevas")
        
    except Exception as e:
        logger.error(f"Error en proceso de guardado: {e}")

@app.get("/scrape_por_categoria")
async def scrape_por_categoria(categoria: str = Query(..., description="Categoría de noticias a buscar")):
    """
    Busca noticias de una categoría específica
    """
    try:
        # Ajusta esta URL según la estructura del sitio
        url = f"https://noticiasambientales.com/categoria/{categoria}"
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        # Usar la misma lógica de extracción
        soup = BeautifulSoup(response.text, 'html.parser')
        
        noticias = []
        
        # Iterar sobre los artículos en la página
        for articulo in soup.select("article"):
            titulo_elem = articulo.select_one("h2, h3, h4")
            resumen_elem = articulo.select_one("p")
            enlace_elem = articulo.select_one("a")
            fecha_elem = articulo.select_one(".date, .tiempo, time")
            imagen_elem = articulo.select_one("img")
            categoria_elem = articulo.select_one(".categoria, .category")
            
            # Extraer datos con manejo de excepciones
            try:
                titulo = titulo_elem.get_text(strip=True) if titulo_elem else "Sin título"
                resumen = resumen_elem.get_text(strip=True) if resumen_elem else "Sin resumen"
                enlace = enlace_elem['href'] if enlace_elem and enlace_elem.has_attr('href') else "#"
                
                # Normalizar URL si es relativa
                if enlace.startswith("/"):
                    enlace = f"https://noticiasambientales.com{enlace}"
                
                # Extraer fecha
                fecha = fecha_elem.get_text(strip=True) if fecha_elem else None
                
                # Extraer imagen
                imagen_url = None
                if imagen_elem and imagen_elem.has_attr('src'):
                    imagen_url = imagen_elem['src']
                elif imagen_elem and imagen_elem.has_attr('data-src'):
                    imagen_url = imagen_elem['data-src']
                
                # Extraer categoría
                categoria = categoria_elem.get_text(strip=True) if categoria_elem else "General"
                
                # Intentar cargar y extraer contenido completo
                contenido_completo = obtener_contenido_completo(enlace) if enlace != "#" else resumen
                
                noticia = {
                    "titulo": titulo,
                    "resumen": resumen,
                    "contenido": contenido_completo,
                    "link": enlace,
                    "fecha": fecha,
                    "imagen_url": imagen_url,
                    "categoria": categoria
                }
                noticias.append(noticia)
            except Exception as e:
                logger.error(f"Error procesando artículo: {e}")
                continue
        
        return noticias
    
    except Exception as e:
        logger.error(f"Error en scrape_por_categoria: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
