-- ============================================================
-- Migration 51: votaciones para reemplazo de mesa directiva
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE board_governance_motions
    ADD COLUMN IF NOT EXISTS target_board_member_user_id BIGINT REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS replacement_board_member_user_ids TEXT;

ALTER TABLE board_governance_motions
    DROP CONSTRAINT IF EXISTS board_governance_motions_motion_type_check;

ALTER TABLE board_governance_motions
    ADD CONSTRAINT board_governance_motions_motion_type_check
    CHECK (motion_type IN (
        'DUPLICATE_COMMON_EXPENSE',
        'REMOVE_ADMINISTRATOR',
        'SELECT_ADMINISTRATOR',
        'REMOVE_BOARD_MEMBER',
        'REPLACE_BOARD_MEMBERS'
    ));
