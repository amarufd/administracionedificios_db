SET search_path TO lazaro, public;

ALTER TABLE shift_recurrence_rules
    ADD COLUMN IF NOT EXISTS days_of_week VARCHAR(30);

UPDATE shift_recurrence_rules
SET days_of_week = COALESCE(days_of_week, weekday_iso::TEXT)
WHERE days_of_week IS NULL;

