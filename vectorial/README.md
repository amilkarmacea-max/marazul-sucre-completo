# 11_VECTORIAL · Búsqueda semántica de pescado

Prototipo de búsqueda por similitud sobre las descripciones organolépticas de la tabla `species`, comparado con la búsqueda léxica con `LIKE`.

## Archivos

| Archivo | Contenido |
| --- | --- |
| `11_VECTORIAL.ipynb` | Cuaderno de Google Colab con embeddings multilingües y ChromaDB |
| `11_VECTORIAL_LIKE.sql` | Búsquedas `LIKE` sobre la base `marazul_sucre` en MySQL |

## Tecnologías

- Modelo de embeddings `intfloat/multilingual-e5-base` (768 dimensiones)
- sentence-transformers 6.2.0
- ChromaDB 1.5.9 con distancia coseno

## Pasos

1. Ejecutar `11_VECTORIAL_LIKE.sql` en MySQL Workbench sobre la base `marazul_sucre`.
2. Entrar a colab.research.google.com, usar **Archivo → Subir cuaderno** y escoger `11_VECTORIAL.ipynb`.
3. Usar **Entorno de ejecución → Ejecutar todas**. Con CPU es suficiente.
4. La primera celda instala las librerías. Si Colab pide reiniciar la sesión, se acepta y se ejecuta todo otra vez.
5. La primera ejecución descarga el modelo, de alrededor de 1 GB, así que tarda un par de minutos.
