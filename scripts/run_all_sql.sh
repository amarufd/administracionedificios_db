#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
SQL_DIR="${PROJECT_DIR}/sql"
ENV_FILE="${PROJECT_DIR}/.env"

if [ -f "${ENV_FILE}" ]; then
  # Exporta las variables simples del proyecto para reutilizar POSTGRES_*.
  set -a
  # shellcheck disable=SC1090
  . "${ENV_FILE}"
  set +a
fi

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-lazarodb}"
DB_USER="${POSTGRES_USER:-postgres}"

if [ -n "${POSTGRES_PASSWORD:-}" ]; then
  export PGPASSWORD="${POSTGRES_PASSWORD}"
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "Error: psql no está instalado en el host." >&2
  echo "Instala el cliente de PostgreSQL o ejecuta los SQL desde el contenedor." >&2
  exit 1
fi

if [ ! -d "${SQL_DIR}" ]; then
  echo "Error: no existe el directorio SQL en ${SQL_DIR}." >&2
  exit 1
fi

found_sql=0
for sql_file in "${SQL_DIR}"/*.sql; do
  if [ ! -f "${sql_file}" ]; then
    continue
  fi

  found_sql=1
  echo "Ejecutando $(basename "${sql_file}")..."
  psql \
    -v ON_ERROR_STOP=1 \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${DB_USER}" \
    -d "${DB_NAME}" \
    -f "${sql_file}"
done

if [ "${found_sql}" -eq 0 ]; then
  echo "No se encontraron archivos .sql en ${SQL_DIR}." >&2
  exit 1
fi

echo "SQL ejecutados correctamente."
