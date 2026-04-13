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
- `sql/04_missing_elements.sql` a `sql/07_normalize_condominium_types.sql`: migraciones incrementales del modelo.

## Ejecutar SQL
```bash
psql -h localhost -U postgres -d lazaro_condominio -f sql/01_schema.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/02_seed.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/03_views_and_queries.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/04_missing_elements.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/05_auth.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/06_condominium_admin_flow.sql
psql -h localhost -U postgres -d lazaro_condominio -f sql/07_normalize_condominium_types.sql
```

## Notas técnicas
- Patrón aplicado: `Repository/DAO` + `Service-ready`.
- Arquitectura objetivo: compatible con `Clean/Hexagonal` (los DAOs quedan como adapters de persistencia).
- Base de datos: PostgreSQL con índices y constraints para escenarios de condominio.
