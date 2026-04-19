-- 20_shift_scheduling.sql
-- Scheduling layer for planned concierge shifts.

SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS shift_templates (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    building_id         BIGINT REFERENCES buildings(id),
    name                VARCHAR(120) NOT NULL,
    description         TEXT,
    start_time          TIME NOT NULL,
    end_time            TIME NOT NULL,
    crosses_midnight    BOOLEAN NOT NULL DEFAULT FALSE,
    color_hex           VARCHAR(20),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS shift_schedules (
    id                      BIGSERIAL PRIMARY KEY,
    condominium_id          BIGINT NOT NULL REFERENCES condominiums(id),
    building_id             BIGINT REFERENCES buildings(id),
    template_id             BIGINT REFERENCES shift_templates(id),
    title                   VARCHAR(160) NOT NULL,
    description             TEXT,
    scheduled_start_at      TIMESTAMP NOT NULL,
    scheduled_end_at        TIMESTAMP NOT NULL,
    status                  VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADO'
                                CHECK (status IN ('PROGRAMADO','CONFIRMADO','EN_CURSO','TRABAJADO','AUSENTE','CANCELADO')),
    assignment_status       VARCHAR(30) NOT NULL DEFAULT 'SIN_ASIGNAR'
                                CHECK (assignment_status IN ('SIN_ASIGNAR','ASIGNADO','REEMPLAZO_PENDIENTE','REASIGNADO')),
    confirmation_deadline_at TIMESTAMP,
    created_by_user_id      BIGINT NOT NULL REFERENCES users(id),
    updated_by_user_id      BIGINT REFERENCES users(id),
    created_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (scheduled_end_at > scheduled_start_at)
);

CREATE TABLE IF NOT EXISTS shift_assignments (
    id                  BIGSERIAL PRIMARY KEY,
    shift_schedule_id   BIGINT NOT NULL REFERENCES shift_schedules(id) ON DELETE CASCADE,
    concierge_user_id   BIGINT NOT NULL REFERENCES users(id),
    assignment_type     VARCHAR(20) NOT NULL DEFAULT 'TITULAR'
                            CHECK (assignment_type IN ('TITULAR','REEMPLAZO','APOYO')),
    assigned_by_user_id BIGINT NOT NULL REFERENCES users(id),
    assigned_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    is_current          BOOLEAN NOT NULL DEFAULT TRUE,
    notes               TEXT
);

CREATE TABLE IF NOT EXISTS shift_requests (
    id                          BIGSERIAL PRIMARY KEY,
    shift_schedule_id           BIGINT NOT NULL REFERENCES shift_schedules(id) ON DELETE CASCADE,
    requested_by_user_id        BIGINT NOT NULL REFERENCES users(id),
    request_type                VARCHAR(20) NOT NULL
                                    CHECK (request_type IN ('CONFIRMACION','RECHAZO','CAMBIO')),
    status                      VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                                    CHECK (status IN ('PENDIENTE','APROBADA','RECHAZADA')),
    reason                      TEXT,
    proposed_replacement_user_id BIGINT REFERENCES users(id),
    reviewed_by_user_id         BIGINT REFERENCES users(id),
    reviewed_at                 TIMESTAMP,
    resolution_notes            TEXT,
    created_at                  TIMESTAMP NOT NULL DEFAULT NOW()
);

ALTER TABLE shifts
    ADD COLUMN IF NOT EXISTS shift_schedule_id BIGINT REFERENCES shift_schedules(id);

CREATE INDEX IF NOT EXISTS idx_shift_templates_condo ON shift_templates(condominium_id, building_id);
CREATE INDEX IF NOT EXISTS idx_shift_schedules_range ON shift_schedules(condominium_id, scheduled_start_at, scheduled_end_at);
CREATE INDEX IF NOT EXISTS idx_shift_schedules_status ON shift_schedules(condominium_id, status, assignment_status);
CREATE INDEX IF NOT EXISTS idx_shift_assignments_current ON shift_assignments(concierge_user_id, is_current);
CREATE INDEX IF NOT EXISTS idx_shift_requests_schedule ON shift_requests(shift_schedule_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS uq_shift_assignments_current
    ON shift_assignments(shift_schedule_id)
    WHERE is_current = TRUE;
