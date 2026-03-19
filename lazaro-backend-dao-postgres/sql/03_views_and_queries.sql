SET search_path TO lazaro, public;

CREATE OR REPLACE VIEW vw_pending_common_expenses AS
SELECT
    ce.period_yyyymm,
    u.code AS unit_code,
    cei.amount,
    cei.balance,
    cei.payment_status
FROM common_expense_items cei
JOIN common_expenses ce ON ce.id = cei.common_expense_id
JOIN units u ON u.id = cei.unit_id
WHERE cei.payment_status = 'PENDIENTE';

CREATE OR REPLACE VIEW vw_active_announcements AS
SELECT
    a.id,
    a.kind,
    a.title,
    a.severity,
    a.published_at,
    a.expires_at
FROM announcements a
WHERE a.expires_at IS NULL OR a.expires_at >= NOW();

-- reservas activas por condominio
SELECT condominium_id, status, COUNT(*) AS total
FROM reservations
GROUP BY condominium_id, status
ORDER BY condominium_id, status;

-- estado de votaciones
SELECT id, title, status, start_at, end_at
FROM votes
ORDER BY created_at DESC;

-- documentos próximos a vencer (60 días)
SELECT id, title, category, valid_until
FROM documents
WHERE valid_until IS NOT NULL
  AND valid_until <= CURRENT_DATE + INTERVAL '60 day'
ORDER BY valid_until;
