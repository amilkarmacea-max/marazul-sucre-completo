from pathlib import Path
import subprocess
import re

def ejecutar(binario, config, sql, forzar=False, tabla=False):
    args = [str(binario), '--defaults-extra-file=' + str(Path(config).resolve()), '--default-character-set=utf8mb4', '--connect-timeout=15']
    args += ['--table', '-vvv'] if tabla else ['--batch', '--skip-column-names']
    if forzar:
        args.append('--force')
    r = subprocess.run(args, input=sql.encode('utf8'), stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180)
    return r.returncode, r.stdout.decode('utf8', errors='replace').replace('\r', ''), r.stderr.decode('utf8', errors='replace').replace('\r', '')

def comprobar(resultado, esperados=()):
    codigo, salida, errores = resultado
    encontrados = re.findall(r'ERROR (\d+)', errores)
    if encontrados != [str(x) for x in esperados] or (codigo and not esperados):
        raise RuntimeError(errores or salida or 'El cliente falló sin salida')
    return salida

def guardar(carpeta, nombre, resultado):
    carpeta = Path(carpeta)
    carpeta.mkdir(parents=True, exist_ok=True)
    codigo, salida, errores = resultado
    (carpeta / (nombre + '.txt')).write_text(salida + '\nERRORES DEL CLIENTE\n' + errores + '\nCódigo de salida: ' + str(codigo) + '\n', encoding='utf8')

def normalizar(salida):
    salida = re.sub(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}', '<fecha>', salida)
    salida = re.sub(r' at line \d+', '', salida)
    return '\n'.join(linea for linea in salida.splitlines() if linea.strip() and not re.fullmatch('-+', linea) and not linea.startswith('CALL '))
