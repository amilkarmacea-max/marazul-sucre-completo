#!/bin/bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
python3 12_MIGRACION.py "$@"
