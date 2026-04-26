SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS fines (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    incident_id         BIGINT REFERENCES incidents(id) ON DELETE SET NULL,
    unit_id             BIGINT REFERENCES units(id),
    user_id             BIGINT REFERENCES users(id),
    reason              TEXT NOT NULL,
    amount              NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    status              VARCHAR(20) NOT NULL DEFAULT 'EMITIDA'
                            CHECK (status IN ('EMITIDA','ANULADA','PAGADA')),
    created_by_user_id  BIGINT REFERENCES users(id),
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    voided_at           TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_fines_condo_status
    ON fines(condominium_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_fines_incident
    ON fines(incident_id);
