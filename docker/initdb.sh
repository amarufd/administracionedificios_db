#!/bin/sh
set -eu

echo "Inicializando esquema de lazarodb..."

for sql_file in /docker-entrypoint-initdb.d/sql/*.sql; do
  echo "Ejecutando ${sql_file}..."
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$sql_file"
done
