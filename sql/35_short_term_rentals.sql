-- Migration 35: short-term rental (Airbnb-style) entities
SET search_path TO lazaro, public;

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS temp_users (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT       NOT NULL REFERENCES condominiums(id),
    full_name           VARCHAR(120) NOT NULL,
    document_id         VARCHAR(60),
    phone               VARCHAR(40),
    access_code_hash    VARCHAR(255) NOT NULL,
    access_code_prefix  VARCHAR(8)   NOT NULL,
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    deactivated_at      TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_temp_users_prefix
    ON temp_users(condominium_id, access_code_prefix)
    WHERE is_active = TRUE;

CREATE TABLE IF NOT EXISTS unit_short_term_rentals (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT      NOT NULL REFERENCES condominiums(id),
    unit_id             BIGINT      NOT NULL REFERENCES units(id),
    temp_user_id        BIGINT      NOT NULL REFERENCES temp_users(id),
    created_by_user_id  BIGINT      NOT NULL REFERENCES users(id),
    start_at            TIMESTAMP   NOT NULL,
    end_at              TIMESTAMP   NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA'
        CHECK (status IN ('PROGRAMADA','ACTIVA','FINALIZADA','CANCELADA')),
    notes               TEXT,
    created_at          TIMESTAMP   NOT NULL DEFAULT NOW(),
    CHECK (end_at > start_at),
    UNIQUE (temp_user_id)
);

ALTER TABLE unit_short_term_rentals
    ADD CONSTRAINT no_overlap_active_per_unit
    EXCLUDE USING gist (
        unit_id WITH =,
        tsrange(start_at, end_at, '[)') WITH &&
    )
    WHERE (status IN ('PROGRAMADA','ACTIVA'));

CREATE INDEX IF NOT EXISTS idx_short_term_rentals_unit_status
    ON unit_short_term_rentals(condominium_id, unit_id, status);
