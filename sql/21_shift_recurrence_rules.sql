SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS shift_recurrence_rules (
    id                          BIGSERIAL PRIMARY KEY,
    condominium_id              BIGINT NOT NULL REFERENCES condominiums(id),
    building_id                 BIGINT REFERENCES buildings(id),
    template_id                 BIGINT REFERENCES shift_templates(id),
    title                       VARCHAR(160) NOT NULL,
    description                 TEXT,
    concierge_user_id           BIGINT REFERENCES users(id),
    scheduled_start_time        TIME NOT NULL,
    scheduled_end_time          TIME NOT NULL,
    duration_minutes            INTEGER NOT NULL CHECK (duration_minutes > 0),
    weekday_iso                 INTEGER NOT NULL CHECK (weekday_iso BETWEEN 1 AND 7),
    starts_on                   DATE NOT NULL,
    ends_on                     DATE NOT NULL,
    confirmation_deadline_time  TIME,
    is_active                   BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_user_id          BIGINT NOT NULL REFERENCES users(id),
    updated_by_user_id          BIGINT REFERENCES users(id),
    created_at                  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (ends_on >= starts_on)
);

ALTER TABLE shift_schedules
    ADD COLUMN IF NOT EXISTS recurrence_rule_id BIGINT REFERENCES shift_recurrence_rules(id);

CREATE INDEX IF NOT EXISTS idx_shift_recurrence_rules_condo
    ON shift_recurrence_rules(condominium_id, building_id, is_active);

CREATE INDEX IF NOT EXISTS idx_shift_schedules_recurrence_rule
    ON shift_schedules(recurrence_rule_id, scheduled_start_at);
