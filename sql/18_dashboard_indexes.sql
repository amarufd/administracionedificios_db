SET search_path TO lazaro, public;

CREATE INDEX IF NOT EXISTS idx_incidents_condo_created_at
    ON incidents(condominium_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_incidents_condo_status_ack
    ON incidents(condominium_id, status, acknowledged_at);

CREATE INDEX IF NOT EXISTS idx_announcements_condo_published
    ON announcements(condominium_id, published_at DESC);
