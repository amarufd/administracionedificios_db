SET search_path TO lazaro, public;

-- JdbcUserDao.findByCondominium:
--   WHERE condominium_id = ? AND is_active = TRUE ORDER BY full_name
-- The existing UNIQUE idx_users_condo_email (condominium_id, email) does not help this query.
CREATE INDEX IF NOT EXISTS idx_users_condo_active
    ON users(condominium_id, is_active, full_name);

-- JdbcNotificationDao.findPendingNotifications:
--   WHERE condominium_id = ? AND status = 'PENDIENTE' ORDER BY id
-- The existing idx_notifications_user (user_id, status) cannot serve this filter
-- because the leading column does not match.
CREATE INDEX IF NOT EXISTS idx_notifications_condo_status
    ON notifications(condominium_id, status);

-- Deferred candidate (do NOT add yet):
--   idx_audit_log_condo_created ON audit_log(condominium_id, created_at DESC)
-- Reason for deferral: no DAO query currently filters audit_log by condominium_id.
-- The candidate query (findByCondominium) is part of the planned stage 2 cross-tenant
-- fix in JdbcAuditLogDao. Before adding this index, run EXPLAIN ANALYZE against the
-- real query once it exists and confirm the planner picks this index over a sequential
-- scan on representative data volume.
