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

CREATE TABLE IF NOT EXISTS board_governance_minutes (
    id BIGSERIAL PRIMARY KEY,
    condominium_id BIGINT NOT NULL REFERENCES condominiums(id),
    title VARCHAR(160) NOT NULL,
    summary TEXT,
    file_url TEXT,
    published BOOLEAN NOT NULL DEFAULT FALSE,
    created_by_user_id BIGINT NOT NULL REFERENCES users(id),
    updated_by_user_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (NULLIF(TRIM(COALESCE(summary, '')), '') IS NOT NULL OR NULLIF(TRIM(COALESCE(file_url, '')), '') IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_board_governance_minutes_condo_created
    ON board_governance_minutes(condominium_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_board_governance_minutes_published
    ON board_governance_minutes(condominium_id, published, created_at DESC);
