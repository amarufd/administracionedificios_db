# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Lazaro** — a multi-condominium management system. This repository holds the PostgreSQL database schema. The Spring Boot backend lives in the sibling directory `../administracionedificios_be`.

## Database Setup

```bash
# Create the database first (one-time)
psql -U postgres -c "CREATE DATABASE lazarodb;"

# Apply schema, seed data, and views in order
psql -h localhost -U postgres -d lazarodb -f sql/01_schema.sql
psql -h localhost -U postgres -d lazarodb -f sql/02_seed.sql
psql -h localhost -U postgres -d lazarodb -f sql/03_views_and_queries.sql
```

The SQL files must be applied in order — `01` defines tables, `02` inserts test data, `03` creates views that depend on both.

All tables live under the `lazaro` schema (e.g., `lazaro.condominiums`).

## Architecture

### Multi-tenancy
Every table includes a `condominium_id` foreign key. All queries should be scoped to a single condominium. The `users` table carries a `role` field (`ADMIN`, `CONSERJE`, `RESIDENTE`) for RBAC enforcement at the application layer.

### Domain Modules

| Module | Tables |
|---|---|
| Identity | `condominiums`, `users`, `units` |
| Reservations | `reservations`, `amenities` |
| Expenses & Billing | `common_expenses`, `common_expense_items`, `payment_links` |
| Documents & Providers | `documents`, `providers` |
| Community Voting | `votes`, `vote_options`, `vote_responses` |
| Parcels & Logistics | `parcels` |
| Visitor Management | `visits` |
| Announcements | `announcements` |

### Status Workflows
`reservations`, `common_expenses`, `visits`, and `votes` each have a `STATUS` column driving approval/lifecycle state machines. Valid state transitions are enforced by the backend service layer.

### Views (`03_views_and_queries.sql`)
- `vw_pending_common_expenses` — unpaid expense items grouped by unit
- `vw_active_announcements` — non-expired announcements currently in effect
- Utility queries for reservation counts, vote tracking, and document expiration warnings (60-day lookahead)
