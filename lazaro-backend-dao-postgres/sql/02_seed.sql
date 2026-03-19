SET search_path TO lazaro, public;

INSERT INTO condominiums (id, name, display_name, is_default, transfer_account, contact_phone)
VALUES
(1, 'Condominio Lazaro Centro', 'Lazaro Centro', TRUE, 'CTA-001-CLP', '+56 2 5555 0001')
ON CONFLICT (id) DO NOTHING;

INSERT INTO users (id, condominium_id, full_name, email, role)
VALUES
(1, 1, 'Ana Admin', 'admin@lazaro.cl', 'ADMIN'),
(2, 1, 'Carlos Conserje', 'conserje@lazaro.cl', 'CONSERJE'),
(3, 1, 'Rocio Residente', 'rocio@lazaro.cl', 'RESIDENTE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO units (id, condominium_id, code, floor, owner_user_id)
VALUES
(1, 1, 'A-101', '1', 3),
(2, 1, 'A-201', '2', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO amenities (id, condominium_id, name, requires_approval, open_time, close_time)
VALUES
(1, 1, 'Quincho', TRUE, '09:00', '23:00'),
(2, 1, 'Sala Multiuso', TRUE, '08:00', '22:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO reservations (condominium_id, amenity_id, unit_id, resident_user_id, start_at, end_at, status, voucher_url, notes)
VALUES
(1, 1, 1, 3, NOW() + INTERVAL '2 day', NOW() + INTERVAL '2 day 3 hour', 'PENDIENTE', 'https://files.lazaro.cl/voucher/123', 'Evento familiar');

INSERT INTO common_expenses (id, condominium_id, period_yyyymm, issued_at, due_at, total_amount, status)
VALUES
(1, 1, TO_CHAR(NOW(), 'YYYYMM'), CURRENT_DATE, CURRENT_DATE + INTERVAL '10 day', 2500000, 'EMITIDO')
ON CONFLICT (id) DO NOTHING;

INSERT INTO common_expense_items (common_expense_id, unit_id, amount, balance, payment_status)
VALUES
(1, 1, 85000, 85000, 'PENDIENTE'),
(1, 2, 92000, 0, 'PAGADO')
ON CONFLICT DO NOTHING;

INSERT INTO payment_links (condominium_id, provider_name, description, url, is_active)
VALUES
(1, 'WebPay', 'Pago Gastos Comunes', 'https://pagos.lazaro.cl/webpay', TRUE),
(1, 'MercadoPago', 'Pago Reservas', 'https://pagos.lazaro.cl/reservas', TRUE);

INSERT INTO documents (condominium_id, title, category, file_url, valid_until)
VALUES
(1, 'Reglamento de Copropiedad', 'REGLAMENTO', 'https://docs.lazaro.cl/reglamento.pdf', CURRENT_DATE + INTERVAL '365 day'),
(1, 'Acta Mesa Directiva', 'ACTA', 'https://docs.lazaro.cl/acta-2026-03.pdf', CURRENT_DATE + INTERVAL '365 day');

INSERT INTO providers (condominium_id, company_name, service_type, contact_name, phone, email, certification_due)
VALUES
(1, 'Ascensores Andes', 'ASCENSOR', 'Pedro Mena', '+56 9 1111 2222', 'pedro@ascandes.cl', CURRENT_DATE + INTERVAL '200 day'),
(1, 'Electricidad Segura', 'ELECTRICO', 'Sofia Lara', '+56 9 3333 4444', 'sofia@elsegura.cl', CURRENT_DATE + INTERVAL '120 day');

INSERT INTO votes (id, condominium_id, title, description, start_at, end_at, status)
VALUES
(1, 1, 'Cambio de horario sala multiuso', 'Definir nuevo horario de cierre', NOW(), NOW() + INTERVAL '7 day', 'ABIERTA')
ON CONFLICT (id) DO NOTHING;

INSERT INTO vote_options (id, vote_id, option_label)
VALUES
(1, 1, 'Cerrar 22:00'),
(2, 1, 'Cerrar 23:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO vote_responses (vote_id, option_id, user_id)
VALUES
(1, 1, 3)
ON CONFLICT DO NOTHING;

INSERT INTO parcels (condominium_id, unit_id, carrier, tracking_number, received_at, status)
VALUES
(1, 1, 'Chilexpress', 'CLX-000123', NOW(), 'RECIBIDO');

INSERT INTO visits (condominium_id, unit_id, visitor_name, visitor_document, planned_at, status)
VALUES
(1, 1, 'Jorge Perez', '11.222.333-4', NOW() + INTERVAL '1 day', 'PENDIENTE');

INSERT INTO announcements (condominium_id, kind, title, body, severity, expires_at)
VALUES
(1, 'NOTICIA', 'Mantenimiento de ascensor', 'Se realizará mantención preventiva el viernes.', 'INFO', NOW() + INTERVAL '5 day'),
(1, 'ALERTA', 'Corte de agua programado', 'Corte desde 09:00 a 13:00.', 'ALTA', NOW() + INTERVAL '2 day'),
(1, 'NOVEDAD', 'Nueva función de reservas', 'Ya disponible comprobante digital.', 'INFO', NOW() + INTERVAL '30 day');
