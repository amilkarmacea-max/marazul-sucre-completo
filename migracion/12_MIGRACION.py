from pathlib import Path
import argparse
import subprocess
import sys
from cliente import ejecutar, comprobar, guardar

def main():
    p = argparse.ArgumentParser()
    for nombre in ['mysql-bin', 'mariadb-bin', 'mysql-config', 'mariadb-config']:
        p.add_argument('--' + nombre, required=True)
    p.add_argument('--salidas', default='resultados')
    p.add_argument('--reemplazar-destino', action='store_true')
    a = p.parse_args()
    destino = Path(a.salidas).resolve()
    destino.mkdir(parents=True, exist_ok=True)
    cliente = Path(a.mariadb_bin) / ('mariadb.exe' if sys.platform == 'win32' else 'mariadb')
    version = comprobar(ejecutar(cliente, a.mariadb_config, 'SELECT VERSION();')).strip()
    if not version.startswith('12.3.') or 'MariaDB' not in version:
        raise RuntimeError('El destino debe ser MariaDB 12.3 LTS. Versión encontrada: ' + version)
    existente = comprobar(ejecutar(cliente, a.mariadb_config, "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='marazul_sucre';")).strip()
    if existente != '0' and not a.reemplazar_destino:
        raise RuntimeError('El destino ya contiene marazul_sucre. Utilice una instancia vacía o --reemplazar-destino después de respaldarla.')
    dump = Path(a.mysql_bin) / ('mysqldump.exe' if sys.platform == 'win32' else 'mysqldump')
    args = [str(dump), '--defaults-extra-file=' + str(Path(a.mysql_config).resolve()), '--databases', 'marazul_sucre', '--routines', '--triggers', '--single-transaction', '--complete-insert', '--set-gtid-purged=OFF', '--no-tablespaces', '--column-statistics=0', '--skip-comments']
    r = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180)
    if r.returncode:
        raise RuntimeError(r.stderr.decode('utf8', errors='replace'))
    origen = destino / 'volcado_mysql_original.sql'
    adaptado = destino / 'volcado_mariadb.sql'
    origen.write_bytes(r.stdout)
    subprocess.run([sys.executable, str(Path(__file__).with_name('adaptar_dump.py')), str(origen), str(adaptado)], check=True)
    if existente != '0':
        comprobar(ejecutar(cliente, a.mariadb_config, 'DROP DATABASE marazul_sucre;'))
    carga = ejecutar(cliente, a.mariadb_config, adaptado.read_text(encoding='utf8'))
    guardar(destino, 'carga_mariadb', carga)
    comprobar(carga)
    dcl = ejecutar(cliente, a.mariadb_config, Path(__file__).with_name('04_DCL_MARIADB.sql').read_text(encoding='utf8'), tabla=True)
    guardar(destino, 'roles_mariadb', dcl)
    comprobar(dcl)
    print('Carga y roles completados en ' + version + '. Ejecute validar_migracion.py para comprobar el resultado.')

if __name__ == '__main__':
    main()
