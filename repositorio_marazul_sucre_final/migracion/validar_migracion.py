from pathlib import Path
import argparse
import hashlib
import json
import sys
from cliente import ejecutar, comprobar, guardar, normalizar

def main():
    p = argparse.ArgumentParser()
    for nombre in ['mysql-bin', 'mariadb-bin', 'mysql-config', 'mariadb-config']:
        p.add_argument('--' + nombre, required=True)
    p.add_argument('--salidas', default='resultados')
    p.add_argument('--incluir-tcl', action='store_true')
    a = p.parse_args()
    base = Path(__file__).resolve().parent
    salidas = Path(a.salidas)
    salidas.mkdir(parents=True, exist_ok=True)
    ext = '.exe' if sys.platform == 'win32' else ''
    conexiones = [('mysql', Path(a.mysql_bin) / ('mysql' + ext), a.mysql_config), ('mariadb', Path(a.mariadb_bin) / ('mariadb' + ext), a.mariadb_config)]
    def consulta(c, sql):
        return comprobar(ejecutar(c[1], c[2], sql)).strip()
    version = consulta(conexiones[1], 'SELECT VERSION();')
    if not version.startswith('12.3.') or 'MariaDB' not in version:
        raise RuntimeError('Se exige MariaDB 12.3 LTS; encontrado ' + version)
    tablas = consulta(conexiones[0], "SELECT table_name FROM information_schema.tables WHERE table_schema='marazul_sucre' AND table_type='BASE TABLE' ORDER BY table_name;").splitlines()
    if len(tablas) != 25:
        raise RuntimeError('Se esperaban las 25 tablas del proyecto')
    informe = []
    for tabla in tablas:
        columnas = consulta(conexiones[0], "SELECT column_name FROM information_schema.columns WHERE table_schema='marazul_sucre' AND table_name='" + tabla + "' ORDER BY ordinal_position;").splitlines()
        lista = ','.join('`' + col + '`' for col in columnas)
        sql = 'SELECT ' + lista + ' FROM marazul_sucre.`' + tabla + '` ORDER BY ' + lista + ';'
        valores = [consulta(c, sql) for c in conexiones]
        informe.append({'tabla': tabla, 'filas': len(valores[0].splitlines()), 'iguales': valores[0] == valores[1], 'sha256': hashlib.sha256(valores[0].encode('utf8')).hexdigest()})
    (salidas / 'comparacion_filas.json').write_text(json.dumps(informe, indent=2), encoding='utf8')
    if not all(fila['iguales'] for fila in informe):
        raise RuntimeError('Hay diferencias de datos; consulte comparacion_filas.json')
    inventario = "SELECT table_type,COUNT(*) FROM information_schema.tables WHERE table_schema='marazul_sucre' GROUP BY table_type ORDER BY table_type; SELECT routine_type,COUNT(*) FROM information_schema.routines WHERE routine_schema='marazul_sucre' GROUP BY routine_type ORDER BY routine_type; SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='marazul_sucre'; SELECT constraint_type,COUNT(*) FROM information_schema.table_constraints WHERE constraint_schema='marazul_sucre' AND constraint_type IN ('FOREIGN KEY','PRIMARY KEY','UNIQUE') GROUP BY constraint_type ORDER BY constraint_type;"
    if consulta(conexiones[0], inventario) != consulta(conexiones[1], inventario):
        raise RuntimeError('El inventario de objetos o restricciones es diferente')
    validaciones = []
    for c in conexiones:
        r = ejecutar(c[1], c[2], (base / '12_VALIDACION_MARIADB.sql').read_text(encoding='utf8'), forzar=True)
        guardar(salidas, 'validacion_' + c[0], r)
        comprobar(r, [1644, 1062, 1644])
        validaciones.append(r[1])
    if validaciones[0] != validaciones[1]:
        raise RuntimeError('Los conteos, totales, vistas o función difieren')
    print('25 tablas con datos idénticos; inventario, totales y reglas verificados en ' + version)
    if a.incluir_tcl:
        scripts = base.parent / 'scripts_sql'
        procedimiento = (scripts / '08_PROCEDIMIENTOS.sql').read_text(encoding='utf8')
        if 'SET @result_code = NULL;' not in procedimiento:
            raise RuntimeError('No se encontró el inicio de las pruebas de procedimientos')
        casos = [('tcl', (scripts / '05_TCL.sql').read_text(encoding='utf8'), []), ('procedimientos', 'USE marazul_sucre;\nSET @result_code = NULL;' + procedimiento.split('SET @result_code = NULL;', 1)[1], [1644, 1644])]
        for nombre, sql, esperados in casos:
            valores = []
            for c in conexiones:
                r = ejecutar(c[1], c[2], sql, forzar=True)
                guardar(salidas, nombre + '_' + c[0], r)
                comprobar(r, esperados)
                valores.append(normalizar(r[1] + r[2]))
            if valores[0] != valores[1]:
                raise RuntimeError('Diferencias en ' + nombre)
            if nombre == 'tcl' and (valores[0].count('COHERENTE') != 4 or 'DESCUADRADO' in valores[0]):
                raise RuntimeError('Las cuatro capturas no quedaron coherentes')
            print(nombre + ': resultados y errores esperados iguales')

if __name__ == '__main__':
    main()
