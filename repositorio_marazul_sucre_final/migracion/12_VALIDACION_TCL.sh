#!/bin/bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
python3 validar_migracion.py --incluir-tcl "$@"
