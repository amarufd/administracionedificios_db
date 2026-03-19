CREATE SCHEMA IF NOT EXISTS lazaro;
SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS condominiums (
    id                  BIGSERIAL PRIMARY KEY,
    name                VARCHAR(120) NOT NULL,
    display_name        VARCHAR(120) NOT NULL,
    is_default          BOOLEAN NOT NULL DEFAULT FALSE,
    transfer_account    VARCHAR(120),
    contact_phone       VARCHAR(40),
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    full_name           VARCHAR(120) NOT NULL,
    email               VARCHAR(180) NOT NULL,
    role                VARCHAR(30) NOT NULL CHECK (role IN ('ADMIN','CONSERJE','RESIDENTE')),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (condominium_id, email)
);

CREATE TABLE IF NOT EXISTS units (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    code                VARCHAR(40) NOT NULL,
    floor               VARCHAR(10),
    owner_user_id       BIGINT REFERENCES users(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVA',
    UNIQUE (condominium_id, code)
);

CREATE TABLE IF NOT EXISTS amenities (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    name                VARCHAR(100) NOT NULL,
    requires_approval   BOOLEAN NOT NULL DEFAULT TRUE,
    open_time           TIME,
    close_time          TIME
);

CREATE TABLE IF NOT EXISTS reservations (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    amenity_id          BIGINT NOT NULL REFERENCES amenities(id),
    unit_id             BIGINT NOT NULL REFERENCES units(id),
    resident_user_id    BIGINT NOT NULL REFERENCES users(id),
    start_at            TIMESTAMP NOT NULL,
    end_at              TIMESTAMP NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    voucher_url         TEXT,
    notes               TEXT,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (end_at > start_at)
);

CREATE TABLE IF NOT EXISTS common_expenses (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    period_yyyymm       CHAR(6) NOT NULL,
    issued_at           DATE NOT NULL,
    due_at              DATE NOT NULL,
    total_amount        NUMERIC(14,2) NOT NULL CHECK (total_amount >= 0),
    status              VARCHAR(20) NOT NULL DEFAULT 'EMITIDO',
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (condominium_id, period_yyyymm)
);

CREATE TABLE IF NOT EXISTS common_expense_items (
    id                  BIGSERIAL PRIMARY KEY,
    common_expense_id   BIGINT NOT NULL REFERENCES common_expenses(id) ON DELETE CASCADE,
    unit_id             BIGINT NOT NULL REFERENCES units(id),
    amount              NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    balance             NUMERIC(14,2) NOT NULL CHECK (balance >= 0),
    payment_status      VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    UNIQUE (common_expense_id, unit_id)
);

CREATE TABLE IF NOT EXISTS payment_links (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    provider_name       VARCHAR(80) NOT NULL,
    description         VARCHAR(140) NOT NULL,
    url                 TEXT NOT NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS documents (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    title               VARCHAR(140) NOT NULL,
    category            VARCHAR(50) NOT NULL,
    file_url            TEXT NOT NULL,
    valid_until         DATE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS providers (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    company_name        VARCHAR(140) NOT NULL,
    service_type        VARCHAR(80) NOT NULL,
    contact_name        VARCHAR(120),
    phone               VARCHAR(40),
    email               VARCHAR(180),
    certification_due   DATE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS votes (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    title               VARCHAR(160) NOT NULL,
    description         TEXT,
    start_at            TIMESTAMP NOT NULL,
    end_at              TIMESTAMP NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'ABIERTA',
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (end_at > start_at)
);

CREATE TABLE IF NOT EXISTS vote_options (
    id                  BIGSERIAL PRIMARY KEY,
    vote_id             BIGINT NOT NULL REFERENCES votes(id) ON DELETE CASCADE,
    option_label        VARCHAR(120) NOT NULL
);

CREATE TABLE IF NOT EXISTS vote_responses (
    vote_id             BIGINT NOT NULL REFERENCES votes(id) ON DELETE CASCADE,
    option_id           BIGINT NOT NULL REFERENCES vote_options(id) ON DELETE CASCADE,
    user_id             BIGINT NOT NULL REFERENCES users(id),
    voted_at            TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (vote_id, user_id)
);

CREATE TABLE IF NOT EXISTS parcels (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    unit_id             BIGINT NOT NULL REFERENCES units(id),
    carrier             VARCHAR(80),
    tracking_number     VARCHAR(80),
    received_at         TIMESTAMP NOT NULL,
    notified_at         TIMESTAMP,
    status              VARCHAR(20) NOT NULL DEFAULT 'RECIBIDO'
);

CREATE TABLE IF NOT EXISTS visits (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    unit_id             BIGINT NOT NULL REFERENCES units(id),
    visitor_name        VARCHAR(120) NOT NULL,
    visitor_document    VARCHAR(60),
    planned_at          TIMESTAMP NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    notified_at         TIMESTAMP
);

CREATE TABLE IF NOT EXISTS announcements (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    kind                VARCHAR(20) NOT NULL CHECK (kind IN ('NOTICIA','ALERTA','NOVEDAD')),
    title               VARCHAR(180) NOT NULL,
    body                TEXT NOT NULL,
    severity            VARCHAR(20) DEFAULT 'INFO',
    published_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at          TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reservations_condo_start ON reservations(condominium_id, start_at);
CREATE INDEX IF NOT EXISTS idx_expenses_period ON common_expenses(condominium_id, period_yyyymm);
CREATE INDEX IF NOT EXISTS idx_announcements_kind ON announcements(condominium_id, kind, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_visits_planned ON visits(condominium_id, planned_at);
CREATE INDEX IF NOT EXISTS idx_parcels_received ON parcels(condominium_id, received_at DESC);
