import requests
from bs4 import BeautifulSoup
import json

url = "https://noticiasambientales.com/"

try:
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    html_content = response.text
except Exception as e:
    print(f"Error al obtener el HTML: {e}")
    exit(1)

soup = BeautifulSoup(html_content, 'html.parser')

noticias = []

# Buscar artículos de noticias
for articulo in soup.find_all(['article', 'div'], class_=['td_module_10', 'td_module_6', 'td_module_16', 'td_module_11', 'td_module_1', 'td_module_2', 'td_module_3', 'td_module_4', 'td_module_5', 'td_module_7', 'td_module_8', 'td_module_9', 'td_module_12', 'td_module_13', 'td_module_14', 'td_module_15']):
    # Título
    titulo_elem = articulo.find(['h3', 'h2', 'h4'], class_='entry-title') or articulo.find(['h3', 'h2', 'h4'])
    titulo = titulo_elem.get_text(strip=True) if titulo_elem else "Sin título"

    # Enlace
    enlace_elem = titulo_elem.find('a') if titulo_elem else articulo.find('a')
    enlace = enlace_elem['href'] if enlace_elem and enlace_elem.has_attr('href') else "#"

    # Resumen
    resumen_elem = articulo.find('div', class_='td-excerpt') or articulo.find('p')
    resumen = resumen_elem.get_text(strip=True) if resumen_elem else "Sin resumen"

    # Fecha
    fecha_elem = articulo.find('time') or articulo.find('span', class_='td-post-date')
    fecha = fecha_elem.get_text(strip=True) if fecha_elem else None

    # Imagen
    imagen_elem = articulo.find('img')
    imagen_url = imagen_elem['src'] if imagen_elem and imagen_elem.has_attr('src') else None

    # Categoría
    categoria_elem = articulo.find('a', class_='td-post-category')
    categoria = categoria_elem.get_text(strip=True) if categoria_elem else "General"

    noticia = {
        "titulo": titulo,
        "resumen": resumen,
        "link": enlace,
        "fecha": fecha,
        "imagen_url": imagen_url,
        "categoria": categoria
    }
    noticias.append(noticia)

# Imprimir las noticias extraídas
for noticia in noticias:
    print("-"*60)
    print(f"Título: {noticia['titulo']}")
    print(f"Resumen: {noticia['resumen']}")
    print(f"Enlace: {noticia['link']}")
    print(f"Fecha: {noticia['fecha']}")
    print(f"Imagen: {noticia['imagen_url']}")
    print(f"Categoría: {noticia['categoria']}")

# Guardar las noticias extraídas como JSON
with open("noticias_extraidas.json", "w", encoding="utf-8") as f:
    json.dump(noticias, f, ensure_ascii=False, indent=2)
print(f"Se guardaron {len(noticias)} noticias en 'noticias_extraidas.json'")
