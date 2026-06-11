SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS board_approval_requests (
    id                   BIGSERIAL PRIMARY KEY,
    condominium_id       BIGINT NOT NULL REFERENCES condominiums(id),
    vote_id              BIGINT NOT NULL UNIQUE REFERENCES votes(id) ON DELETE CASCADE,
    resource_type        VARCHAR(30) NOT NULL CHECK (resource_type IN ('UNIT','ASSET')),
    payload              JSONB NOT NULL,
    status               VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                             CHECK (status IN ('PENDIENTE','APROBADA','RECHAZADA')),
    created_resource_id  BIGINT,
    requested_by_user_id BIGINT REFERENCES users(id),
    resolved_by_user_id  BIGINT REFERENCES users(id),
    resolved_at          TIMESTAMP,
    created_at           TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_board_approval_requests_condo_status
    ON board_approval_requests(condominium_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_board_approval_requests_vote
    ON board_approval_requests(vote_id);
