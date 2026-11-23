# Migración de MySQL a MariaDB 12.3 LTS

Responsable: Andrés Felipe Mojarrango Silgado.

## Resultado del ensayo

Origen local MySQL 8.0.46; destino local MariaDB 12.3.3. Se reconstruyó el esquema desde el commit `a62154f1728d386c4483e48a3c0cc793dd988210` del repositorio, con `01_DDL.sql`, `01_DDL_RETOS.sql`, `04_DCL.sql` y 06 a 09. `05_TCL.sql` se ejecutó después de migrar como prueba comparativa, una sola vez sobre cada copia.

Las 25 tablas conservan todos los valores de sus columnas originales. La columna virtual añadida en destino no se compara como dato del origen. Coinciden el inventario de objetos y las cantidades de claves primarias, foráneas y únicas. Se comprobaron 3 vistas, 3 funciones, 3 procedimientos y 6 triggers; el archivo SQL de validación compara los conteos de las vistas y una llamada de disponibilidad. TCL deja las cuatro capturas seleccionadas COHERENTE, y las pruebas de venta devuelven los mismos códigos 0, -1 y -2 y los mismos errores 1644 esperados.

Este ensayo no exportó la base del servicio Aiven, que actualmente utiliza MySQL 8.4.11.

## Diferencias comprobadas

| Elemento | Resultado en 12.3.3 | Tratamiento |
| --- | --- | --- |
| `utf8mb4_0900_ai_ci` | Admitido; alias de cotejamiento UCA 14 | Se conserva el nombre; no se reemplaza por `utf8mb4_unicode_ci` |
| Índice funcional `uq_trip_crew_one_responsible` | Error 1064 en la importación directa | Columna virtual `responsible_trip_id` y UNIQUE sobre ella |
| `SET DEFAULT ROLE r TO u` | Sintaxis de MySQL | En MariaDB se usa `FOR` |
| `SHOW GRANTS FOR u USING r` | Sintaxis de MySQL | Consultar la cuenta y el rol por separado |
| Definidores del origen | Pueden nombrar una cuenta inexistente en destino | El adaptador los omite; el importador queda como definidor |
| Comentarios ejecutables del dump | mysqldump los produce aun con `--skip-comments` | Se materializan las instrucciones anteriores a 50700 y se omiten las guardas exclusivas de MySQL que MariaDB ignora; el SQL adaptado no tiene comentarios |

La compatibilidad del cotejamiento por nombre no demuestra equivalencia lingüística total de UCA 9 con UCA 14. Los datos y restricciones del dataset sí se verificaron. El adaptador es específico para el volcado de este proyecto y aborta si no encuentra el índice esperado.

## Archivos

- `12_MIGRACION.py`: exporta, adapta, carga y recrea roles. Exige MariaDB 12.3 y rechaza una base de destino existente salvo opción explícita.
- `adaptar_dump.py`: transforma el índice, materializa SQL ejecutable y elimina definidores.
- `04_DCL_MARIADB.sql`: recrea los tres roles y usuarios con sintaxis MariaDB.
- `volcado_mariadb_12_3.sql`: instantánea adaptada de la reconstrucción local antes de las pruebas TCL; no incluye cuentas.
- `validar_migracion.py`: compara datos, inventario, totales y errores esperados; opcionalmente ejecuta TCL y ventas.
- `12_VALIDACION_MARIADB.sql`: comprobaciones legibles y tres fallos deliberados.
- `12_MIGRACION.sh` y `12_VALIDACION_TCL.sh`: entradas para Bash que llaman los programas Python.

## Ejecución en Windows o Linux

Necesitas Python 3 y los clientes MySQL y MariaDB. No se requieren paquetes Python externos. Crea fuera del repositorio dos archivos de conexión `.cnf` y protege sus permisos. Ejemplo del origen:

```ini
[client]
host=127.0.0.1
port=3306
user=administrador_origen
password=CONTRASENA_ORIGEN
```

El destino usa la misma estructura con su puerto y cuenta administradora. Para exportar desde Aiven usa su host, puerto 27224 y `ssl-mode=REQUIRED` en el archivo de origen. El usuario inspector no tiene permisos suficientes para exportar toda la base.

Desde la carpeta `migracion`, ajusta las cuatro rutas y ejecuta:

```text
python 12_MIGRACION.py --mysql-bin "RUTA_MYSQL_BIN" --mariadb-bin "RUTA_MARIADB_BIN" --mysql-config "RUTA_ORIGEN.cnf" --mariadb-config "RUTA_DESTINO.cnf" --salidas resultados
python validar_migracion.py --mysql-bin "RUTA_MYSQL_BIN" --mariadb-bin "RUTA_MARIADB_BIN" --mysql-config "RUTA_ORIGEN.cnf" --mariadb-config "RUTA_DESTINO.cnf" --salidas resultados
```

Para sustituir una base de destino desechable ya respaldada agrega `--reemplazar-destino` a la migración. Esa opción elimina `marazul_sucre` solamente del destino. Mantén las escrituras y cambios DDL detenidos durante el volcado y la comparación. El modo de ensayo no cambia la conexión de la aplicación ni elimina el origen.

## Validación TCL y procedimientos

`--incluir-tcl` ejecuta escrituras con COMMIT en ambos motores. Úsalo únicamente sobre las dos copias de ensayo recién sincronizadas. No lo ejecutes contra el servicio de Aiven para una validación de solo lectura. Cada repetición requiere restaurar las dos copias al mismo estado previo; un ROLLBACK no revierte el avance de los AUTO_INCREMENT.

```text
python validar_migracion.py --mysql-bin "RUTA_MYSQL_BIN" --mariadb-bin "RUTA_MARIADB_BIN" --mysql-config "RUTA_ORIGEN.cnf" --mariadb-config "RUTA_DESTINO.cnf" --salidas resultados --incluir-tcl
```

Los archivos de pruebas de roles se ejecutan con su propia cuenta, seleccionando antes `marazul_sucre`. Esperados: inspector, cuatro errores 1142; operador, tres; comercial, cuatro. Las escrituras permitidas terminan en ROLLBACK. Para ejecutar `12_VALIDACION_MARIADB.sql` completo se usa `--force`, porque se esperan exactamente los errores 1644, 1062 y 1644; el validador verifica estos códigos y falla ante otros errores.

## Evidencias y alcance

`documentacion/registros/` contiene las salidas de los clientes y la comparación JSON de las 25 tablas. Las capturas de pantalla de cada prueba están en las secciones 8.1 y 8.2 del informe. La comparación TCL normaliza únicamente fechas generadas y formato del cliente; conserva valores, códigos y mensajes de error.

Fuentes oficiales: https://mariadb.com/docs/server/reference/data-types/string-data-types/character-sets/supported-character-sets-and-collations y https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/migrating-to-mariadb/moving-from-mysql .
