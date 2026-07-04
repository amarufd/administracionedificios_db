SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS board_governance_motions (
    id BIGSERIAL PRIMARY KEY,
    condominium_id BIGINT NOT NULL REFERENCES condominiums(id),
    motion_type VARCHAR(40) NOT NULL CHECK (motion_type IN ('DUPLICATE_COMMON_EXPENSE','REMOVE_ADMINISTRATOR','SELECT_ADMINISTRATOR')),
    target_admin_user_id BIGINT REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (status IN ('PENDIENTE','APROBADA','RECHAZADA')),
    created_by_user_id BIGINT NOT NULL REFERENCES users(id),
    required_approvals INTEGER NOT NULL CHECK (required_approvals > 0),
    executed_resource_id BIGINT,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS board_governance_votes (
    motion_id BIGINT NOT NULL REFERENCES board_governance_motions(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    approved BOOLEAN NOT NULL,
    voted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (motion_id, user_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_board_governance_pending_type
    ON board_governance_motions(condominium_id, motion_type) WHERE status = 'PENDIENTE';
CREATE INDEX IF NOT EXISTS idx_board_governance_condo_created
    ON board_governance_motions(condominium_id, created_at DESC);
