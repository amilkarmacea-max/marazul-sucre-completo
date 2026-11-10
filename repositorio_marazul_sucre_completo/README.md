# MarAzul Sucre · Soluciones de datos para la innovación sostenible (ODS 9)

Parcial final Corte II de Bases de Datos · Ingeniería de Sistemas · CECAR

MarAzul Sucre es la base de datos de una plataforma para las organizaciones de pescadores artesanales y comercializadores del departamento de Sucre. Registra jornadas de pesca, tripulación, capturas, inspecciones de calidad y ventas con trazabilidad completa, control de cantidades disponibles y permisos por perfil.

## Equipo

| Integrante | Rol |
| --- | --- |
| Amilkar José Macea Salgado | DBA / Arquitecto relacional |
| Luis Carlos Arrieta Matias | Líder de proyecto y calidad de datos |
| Juan David Díaz Caro | Desarrollador SQL de consultas y transacciones |
| Roger Andrés Hernández Gómez | Desarrollador SQL procedimental |
| Andrés Felipe Mojarrango Silgado | DevOps, seguridad y migración |
| Luis David Ortiz Hernández | Especialista NoSQL y bases vectoriales |

## Estructura del repositorio

```
/scripts_sql
    01_DDL.sql
    01_DDL_RETOS.sql
    PRUEBAS_01_DDL.sql
    02_DML_JOIN.sql
    03_DML_SUBCONSULTAS.sql
    04_DCL.sql
    05_TCL.sql
    06_VISTAS.sql
    07_FUNCIONES.sql
    08_PROCEDIMIENTOS.sql
    09_TRIGGERS.sql
/nosql
    10_NOSQL_SETUP.js
    10_NOSQL_CONSULTAS.js
    trip_logs.json
    README.md
/vectorial
    11_VECTORIAL.ipynb
    11_VECTORIAL_LIKE.sql
    README.md
/migracion
    README.md
/documentacion
    Informe_MarAzul_Sucre.docx
    modelo_entidad_relacion.png
    diagrama_fisico_antes_de_retos.png
    diagrama_fisico_despues_de_retos.png
README.md
```

## Requisitos

- MySQL 9.7 LTS (o MySQL 8.0.16 en adelante) y MySQL Workbench
- MongoDB Community Server 9.0 y MongoDB Compass, para la carpeta /nosql
- Google Colab con sentence-transformers 6.2.0 y ChromaDB 1.5.9, para la carpeta /vectorial
- MariaDB, para la carpeta /migracion

## Despliegue local

1. Abrir MySQL Workbench y conectarse al servidor local.
2. Abrir `scripts_sql/01_DDL.sql` y ejecutarlo completo. Crea la base `marazul_sucre` en su versión antes de los retos y carga el dataset.
3. Ejecutar `scripts_sql/01_DDL_RETOS.sql`. Aplica los retos DDL A, B y C sobre la misma base. Para repetirlo hay que volver a correr primero `01_DDL.sql`.
4. Ejecutar los scripts 02 a 09 en orden numérico. `05_TCL.sql` modifica datos, así que para repetir la secuencia completa hay que empezar otra vez desde `01_DDL.sql`. Los scripts `08_PROCEDIMIENTOS.sql` y `09_TRIGGERS.sql` terminan con pruebas que fallan a propósito con `SIGNAL SQLSTATE '45000'`, de modo que esos errores al final son los esperados.
5. `PRUEBAS_01_DDL.sql` es opcional y sirve para comprobar las restricciones y el índice de cobertura sobre la base recién creada.
6. Seguir las instrucciones de las carpetas `/nosql`, `/vectorial` y `/migracion`.

## Despliegue en la nube

- Servicio: [completar, por ejemplo Aiven for MySQL]
- Host: [completar]
- Puerto: [completar]
- Base de datos: marazul_sucre

## Credenciales de prueba

Las cuentas se crean en `04_DCL.sql` y solo sirven para la demostración.

| Usuario | Rol | Contraseña | Puede hacer |
| --- | --- | --- | --- |
| usr_operador1 | rol_operador_muelle | [completar] | INSERT y UPDATE en jornadas y capturas |
| usr_comercial1 | rol_gestor_comercial | [completar] | INSERT y UPDATE en ventas y detalle de venta |
| usr_inspector1 | rol_inspector_aunap | [completar] | Solo lectura de jornadas, capturas y especies |

## Convenciones

- Tablas y columnas en inglés y en snake_case.
- Prefijos: `fn_` funciones, `pr_` procedimientos, `vw_` vistas, `tr_` triggers, `idx_` índices, `fk_` claves foráneas, `uq_` únicos, `ck_` restricciones CHECK.
- El dataset es sintético: los municipios, códigos DANE, zonas y especies son reales de Sucre, pero las personas, embarcaciones y ventas son inventadas.
