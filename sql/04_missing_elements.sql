-- ============================================================
-- Migration: missing elements from menu spec
-- Applies on top of 01_schema.sql
-- ============================================================
SET search_path TO lazaro, public;

-- ============================================================
-- ALTER existing tables
-- ============================================================

-- condominiums: operational fields
ALTER TABLE condominiums
    ADD COLUMN IF NOT EXISTS address            TEXT,
    ADD COLUMN IF NOT EXISTS operational_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    ADD COLUMN IF NOT EXISTS total_units        INT,
    ADD COLUMN IF NOT EXISTS logo_url           TEXT,
    ADD COLUMN IF NOT EXISTS account_holder_name VARCHAR(160),
    ADD COLUMN IF NOT EXISTS account_holder_rut  VARCHAR(20),
    ADD COLUMN IF NOT EXISTS bank_name           VARCHAR(120),
    ADD COLUMN IF NOT EXISTS bank_account_type   VARCHAR(60),
    ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(120),
    ADD COLUMN IF NOT EXISTS transfer_email      VARCHAR(180),
    ADD COLUMN IF NOT EXISTS transfer_alias      VARCHAR(120);

-- backfill legacy transfer account into the explicit account number field
UPDATE condominiums
SET bank_account_number = transfer_account
WHERE bank_account_number IS NULL
  AND transfer_account IS NOT NULL;

-- users: contact & identity
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS phone       VARCHAR(40),
    ADD COLUMN IF NOT EXISTS document_id VARCHAR(60),
    ADD COLUMN IF NOT EXISTS avatar_url  TEXT;

-- units: renter linkage & occupation status
ALTER TABLE units
    ADD COLUMN IF NOT EXISTS renter_user_id    BIGINT REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS occupation_status VARCHAR(20) NOT NULL DEFAULT 'OCUPADO';

-- visits: access control & entry/exit tracking
ALTER TABLE visits
    ADD COLUMN IF NOT EXISTS authorized_by_user_id BIGINT REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS registered_by_user_id BIGINT REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS actual_entry_at        TIMESTAMP,
    ADD COLUMN IF NOT EXISTS actual_exit_at         TIMESTAMP;

-- parcels: delivery record
ALTER TABLE parcels
    ADD COLUMN IF NOT EXISTS delivered_at          TIMESTAMP,
    ADD COLUMN IF NOT EXISTS delivered_to_user_id  BIGINT REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS registered_by_user_id BIGINT REFERENCES users(id);

-- announcements: segmentation
ALTER TABLE announcements
    ADD COLUMN IF NOT EXISTS target_role       VARCHAR(30),
    ADD COLUMN IF NOT EXISTS target_unit_id    BIGINT REFERENCES units(id),
    ADD COLUMN IF NOT EXISTS created_by_user_id BIGINT REFERENCES users(id);

-- amenities: reservation rules
ALTER TABLE amenities
    ADD COLUMN IF NOT EXISTS max_duration_minutes        INT,
    ADD COLUMN IF NOT EXISTS max_advance_days            INT,
    ADD COLUMN IF NOT EXISTS max_reservations_per_period INT,
    ADD COLUMN IF NOT EXISTS period_type                 VARCHAR(20),
    ADD COLUMN IF NOT EXISTS rules_text                  TEXT,
    ADD COLUMN IF NOT EXISTS rental_cost                 NUMERIC(12,2) NOT NULL DEFAULT 0;

-- documents: visibility control
ALTER TABLE documents
    ADD COLUMN IF NOT EXISTS visible_to_roles    VARCHAR(80),
    ADD COLUMN IF NOT EXISTS target_unit_id      BIGINT REFERENCES units(id),
    ADD COLUMN IF NOT EXISTS uploaded_by_user_id BIGINT REFERENCES users(id);

-- ============================================================
-- NEW TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS incidents (
    id                   BIGSERIAL PRIMARY KEY,
    condominium_id       BIGINT NOT NULL REFERENCES condominiums(id),
    unit_id              BIGINT REFERENCES units(id),
    reported_by_user_id  BIGINT NOT NULL REFERENCES users(id),
    assigned_to_user_id  BIGINT REFERENCES users(id),
    title                VARCHAR(160) NOT NULL,
    description          TEXT,
    status               VARCHAR(20) NOT NULL DEFAULT 'ABIERTA'
                             CHECK (status IN ('ABIERTA','EN_PROCESO','CERRADA')),
    priority             VARCHAR(20) NOT NULL DEFAULT 'MEDIA'
                             CHECK (priority IN ('BAJA','MEDIA','ALTA')),
    resolved_at          TIMESTAMP,
    created_at           TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS shifts (
    id                BIGSERIAL PRIMARY KEY,
    condominium_id    BIGINT NOT NULL REFERENCES condominiums(id),
    concierge_user_id BIGINT NOT NULL REFERENCES users(id),
    started_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    ended_at          TIMESTAMP,
    status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVO'
                          CHECK (status IN ('ACTIVO','CERRADO')),
    handover_notes    TEXT
);

CREATE TABLE IF NOT EXISTS shift_checklist_items (
    id          BIGSERIAL PRIMARY KEY,
    shift_id    BIGINT NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
    item_label  VARCHAR(140) NOT NULL,
    is_checked  BOOLEAN NOT NULL DEFAULT FALSE,
    checked_at  TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payments (
    id                      BIGSERIAL PRIMARY KEY,
    condominium_id          BIGINT NOT NULL REFERENCES condominiums(id),
    common_expense_item_id  BIGINT NOT NULL REFERENCES common_expense_items(id),
    registered_by_user_id   BIGINT REFERENCES users(id),
    amount                  NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    payment_method          VARCHAR(40) NOT NULL,
    reference_number        VARCHAR(80),
    payment_date            DATE NOT NULL,
    notes                   TEXT,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_templates (
    id             BIGSERIAL PRIMARY KEY,
    condominium_id BIGINT NOT NULL REFERENCES condominiums(id),
    event_type     VARCHAR(60) NOT NULL,
    subject        VARCHAR(180) NOT NULL,
    body_template  TEXT NOT NULL,
    channel        VARCHAR(20) NOT NULL CHECK (channel IN ('EMAIL','SMS','PUSH'))
);

CREATE TABLE IF NOT EXISTS notifications (
    id             BIGSERIAL PRIMARY KEY,
    condominium_id BIGINT NOT NULL REFERENCES condominiums(id),
    user_id        BIGINT NOT NULL REFERENCES users(id),
    template_id    BIGINT REFERENCES notification_templates(id),
    sent_at        TIMESTAMP,
    status         VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                       CHECK (status IN ('ENVIADO','FALLIDO','PENDIENTE'))
);

CREATE TABLE IF NOT EXISTS audit_log (
    id             BIGSERIAL PRIMARY KEY,
    condominium_id BIGINT,
    user_id        BIGINT,
    entity_type    VARCHAR(60) NOT NULL,
    entity_id      BIGINT,
    action         VARCHAR(30) NOT NULL,
    old_data       JSONB,
    new_data       JSONB,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS settings (
    id             BIGSERIAL PRIMARY KEY,
    condominium_id BIGINT NOT NULL REFERENCES condominiums(id),
    key            VARCHAR(80) NOT NULL,
    value          TEXT,
    description    VARCHAR(180),
    updated_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (condominium_id, key)
);

CREATE TABLE IF NOT EXISTS unit_occupation_history (
    id       BIGSERIAL PRIMARY KEY,
    unit_id  BIGINT NOT NULL REFERENCES units(id),
    user_id  BIGINT NOT NULL REFERENCES users(id),
    role     VARCHAR(20) NOT NULL CHECK (role IN ('DUEÑO','ARRENDATARIO')),
    from_date DATE NOT NULL,
    to_date   DATE
);

-- Indexes for new tables
CREATE INDEX IF NOT EXISTS idx_incidents_condo_status  ON incidents(condominium_id, status);
CREATE INDEX IF NOT EXISTS idx_shifts_condo_status     ON shifts(condominium_id, status);
CREATE INDEX IF NOT EXISTS idx_payments_condo          ON payments(condominium_id, payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity        ON audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user          ON audit_log(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user      ON notifications(user_id, status);
