# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Lazaro** — sistema de administración de condominios multi-tenant. Este repositorio contiene el esquema PostgreSQL. El backend Spring Boot vive en `../administracionedificios_be`, el frontend React en `../administracionedificios_front`.

## Setup

### Con Docker (recomendado)
```bash
docker compose up -d
```
El contenedor (`lazaro-db`) aplica automáticamente todos los archivos `sql/*.sql` en orden al iniciar.

#### Networking con el backend
Los proyectos (db, be, front) son docker-compose independientes. Para que el backend pueda resolver `lazaro-db` como hostname, ambos deben estar en una red externa compartida. Cada proyecto tiene un `docker-compose.override.yml` (no commiteado, basado en `docker-compose.override.example.yml`) que los conecta a la red `mediaserver_suite`.

```bash
# Crear la red externa (solo una vez)
docker network create mediaserver_suite
```

Sin el override, el contenedor queda solo en su red default (`administracionedificios_db_default`) y el backend no puede conectarse.

### Manual
```bash
psql -U postgres -c "CREATE DATABASE lazarodb;"
psql -U postgres -d lazarodb -f sql/01_schema.sql
psql -U postgres -d lazarodb -f sql/02_seed.sql
psql -U postgres -d lazarodb -f sql/03_views_and_queries.sql
psql -U postgres -d lazarodb -f sql/04_missing_elements.sql
psql -U postgres -d lazarodb -f sql/05_auth.sql
```

Los archivos deben aplicarse en orden numérico — cada uno depende del anterior.

## Archivos SQL

| Archivo | Contenido |
|---|---|
| `01_schema.sql` | Tablas principales bajo el schema `lazaro.*` |
| `02_seed.sql` | Datos de prueba: condominios, usuarios, unidades, gastos, etc. |
| `03_views_and_queries.sql` | Vistas: `vw_pending_common_expenses`, `vw_active_announcements` y queries utilitarios |
| `04_missing_elements.sql` | Tablas adicionales: `incidents`, `shifts`, `shift_checklist_items`, `amenities`, `payments` |
| `05_auth.sql` | Migración de autenticación: columna `password`, rol `SUPER_ADMIN`, índices parciales para email único con NULL |

## Arquitectura

### Multi-tenancy
Todas las tablas incluyen `condominium_id` como FK. Las queries siempre deben estar acotadas a un condominio. La tabla `users` tiene campo `role` para RBAC en la capa de aplicación.

### Roles de usuario
| Rol | condominium_id | Descripción |
|---|---|---|
| `ADMIN` | requerido | Administrador de un condominio |
| `CONSERJE` | requerido | Conserje de un condominio |
| `RESIDENTE` | requerido | Residente/propietario de una unidad |
| `SUPER_ADMIN` | `NULL` | Administrador global de la plataforma |

### Módulos del dominio

| Módulo | Tablas |
|---|---|
| Identidad | `condominiums`, `users`, `units` |
| Reservas | `reservations`, `amenities` |
| Gastos y Cobranza | `common_expenses`, `common_expense_items`, `payments` |
| Documentos y Proveedores | `documents`, `providers` |
| Votaciones | `votes`, `vote_options`, `vote_responses` |
| Encomiendas | `parcels` |
| Visitas | `visits` |
| Comunicados | `announcements` |
| Incidencias | `incidents` |
| Turnos | `shifts`, `shift_checklist_items` |

### Convenciones SQL
- Schema `lazaro.*` para todas las tablas (e.g. `lazaro.condominiums`)
- Columnas en `snake_case`
- IDs generados con `SERIAL` o `BIGSERIAL`
- Patrón `INSERT ... RETURNING id` en el backend
- `condominium_id IS NULL` permitido solo para usuarios `SUPER_ADMIN` (índices parciales en `05_auth.sql`)

## Usuarios de demo (creados por `05_auth.sql`)

| Email | Password | Rol |
|---|---|---|
| `superadmin@plataforma.cl` | `super123` | SUPER_ADMIN |
| `admin@lazaro.cl` | `admin123` | ADMIN |
| `conserje@lazaro.cl` | `conserje123` | CONSERJE |
| `rocio@lazaro.cl` | `residente123` | RESIDENTE |
