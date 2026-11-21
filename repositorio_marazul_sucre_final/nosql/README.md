# 10_NOSQL · Diarios de campo en MongoDB

Colección `trip_logs` con un diario por cada jornada finalizada o cancelada de la base `marazul_sucre`, enlazado por `trip_id`.

## Archivos

| Archivo | Contenido |
| --- | --- |
| `10_NOSQL_SETUP.js` | Crea la colección con su validador `$jsonSchema` y los cuatro índices |
| `trip_logs.json` | 262 diarios de campo en Extended JSON |
| `10_NOSQL_CONSULTAS.js` | Consultas de los retos B y C |

## Requisitos

MongoDB Community Server 9.0 y MongoDB Compass, que trae integrada la consola mongosh.

## Pasos

1. Instalar MongoDB Community Server con el instalador de Windows, dejando marcadas las opciones de instalarlo como servicio y de instalar MongoDB Compass.
2. Abrir Compass y conectarse a `mongodb://localhost:27017`.
3. Abrir la consola con el botón `>_` y pegar el contenido de `10_NOSQL_SETUP.js`.
4. En el panel izquierdo entrar a la base `marazul_sucre`, colección `trip_logs`, y usar **Add Data → Import JSON or CSV file** con `trip_logs.json`. Deben quedar 262 documentos.
5. Volver a la consola y ejecutar una por una las consultas de `10_NOSQL_CONSULTAS.js`, empezando por `use marazul_sucre`.

La consulta con `updateOne` agrega una incidencia nueva al diario de la jornada 251. Para repetir todo desde cero se vuelve a ejecutar `10_NOSQL_SETUP.js` y se importa otra vez el archivo.
