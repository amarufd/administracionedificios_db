SET search_path TO lazaro, public;

ALTER TABLE shifts
    ADD COLUMN IF NOT EXISTS building_id BIGINT REFERENCES buildings(id),
    ADD COLUMN IF NOT EXISTS check_in_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS check_in_method VARCHAR(20),
    ADD COLUMN IF NOT EXISTS check_out_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS check_out_method VARCHAR(20),
    ADD COLUMN IF NOT EXISTS attendance_status VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
        CHECK (attendance_status IN ('PENDIENTE','PRESENTE','ATRASADO','AUSENTE')),
    ADD COLUMN IF NOT EXISTS final_status VARCHAR(20) NOT NULL DEFAULT 'EN_CURSO'
        CHECK (final_status IN ('EN_CURSO','TRABAJADO','AUSENTE','INCOMPLETO')),
    ADD COLUMN IF NOT EXISTS minutes_late INTEGER NOT NULL DEFAULT 0 CHECK (minutes_late >= 0),
    ADD COLUMN IF NOT EXISTS closed_by_user_id BIGINT REFERENCES users(id);

CREATE INDEX IF NOT EXISTS idx_shifts_schedule ON shifts(shift_schedule_id);
CREATE INDEX IF NOT EXISTS idx_shifts_attendance ON shifts(condominium_id, attendance_status, started_at DESC);

