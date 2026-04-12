#!/bin/sh
set -eu

# Crear usuario adicional si se define EXTRA_USER (para compartir la instancia con otros proyectos)
if [ -n "${EXTRA_USER:-}" ]; then
  echo "Verificando usuario extra '${EXTRA_USER}'..."
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
    DO \$\$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${EXTRA_USER}') THEN
        CREATE ROLE ${EXTRA_USER} WITH LOGIN PASSWORD '${EXTRA_PASSWORD:-postgres}' CREATEDB;
        RAISE NOTICE 'Usuario % creado.', '${EXTRA_USER}';
      ELSE
        RAISE NOTICE 'Usuario % ya existe.', '${EXTRA_USER}';
      END IF;
    END
    \$\$;
SQL
fi

echo "Inicializando esquema de lazarodb..."

for sql_file in /docker-entrypoint-initdb.d/sql/*.sql; do
  echo "Ejecutando ${sql_file}..."
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$sql_file"
done
