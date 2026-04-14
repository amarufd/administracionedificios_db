# Lazaro PostgreSQL

Este paquete se generó a partir de tu archivo `Lazaro.drawio.xml`, considerando 3 pestañas:
- `Interfaz visual`
- `Infra y sistema`
- `Patrones y Diseño del sistema`

## Contenido
- `review/01_revision_xml.md`: revisión funcional + propuesta de opciones adicionales de menú.
- `sql/01_schema.sql`: esquema PostgreSQL.
- `sql/02_seed.sql`: datos de ejemplo para probar flujos.
- `sql/03_views_and_queries.sql`: vistas y consultas útiles.
- `sql/04_missing_elements.sql` a `sql/10_concurrency_guards.sql`: migraciones incrementales del modelo.

## Ejecutar SQL
```bash
psql -h localhost -U postgres -d lazaro_condominio -f sql/01_schema.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/02_seed.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/03_views_and_queries.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/04_missing_elements.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/05_auth.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/06_condominium_admin_flow.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/07_normalize_condominium_types.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/08_fix_id_sequences.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/09_documents_unique_file_url.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/10_concurrency_guards.sql
```

También puedes ejecutarlos todos en orden con:

```bash
./scripts/run_all_sql.sh
```

El script:
- toma `POSTGRES_DB`, `POSTGRES_USER` y `POSTGRES_PASSWORD` desde `.env`
- usa `localhost:5432` por defecto
- ejecuta los archivos de `sql/` en orden por nombre, por lo que `01_...` a `10_...` quedan aplicados secuencialmente

Si necesitas otro host o puerto:

```bash
DB_HOST=127.0.0.1 DB_PORT=5433 ./scripts/run_all_sql.sh
```

Si la base ya existe y el volumen de PostgreSQL no se va a recrear, ejecuta al menos:

```bash
psql -h localhost -U postgres -d lazaro_condominio -f sql/08_fix_id_sequences.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/09_documents_unique_file_url.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/10_concurrency_guards.sql
```

Esas migraciones reparan columnas `id` sin default autoincremental, sincronizan cada secuencia con el `MAX(id)` actual y agregan restricciones para impedir duplicados concurrentes en documentos, turnos, pagos y reservas.

## Notas técnicas
- Patrón aplicado: `Repository/DAO` + `Service-ready`.
- Arquitectura objetivo: compatible con `Clean/Hexagonal` (los DAOs quedan como adapters de persistencia).
- Base de datos: PostgreSQL con índices y constraints para escenarios de condominio.
