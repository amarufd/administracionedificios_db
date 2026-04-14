-- ============================================================
-- Migration 08: reparar ids autoincrementales y sincronizar secuencias
-- ============================================================
SET search_path TO lazaro, public;

DO $$
DECLARE
    target_table TEXT;
    target_sequence TEXT;
    qualified_table TEXT;
BEGIN
    FOR target_table IN
        SELECT unnest(ARRAY[
            'condominiums',
            'users',
            'units',
            'amenities',
            'reservations',
            'common_expenses',
            'common_expense_items',
            'payment_links',
            'documents',
            'providers',
            'votes',
            'vote_options',
            'parcels',
            'visits',
            'announcements',
            'incidents',
            'shifts',
            'shift_checklist_items',
            'payments',
            'notification_templates',
            'notifications',
            'audit_log',
            'settings',
            'unit_occupation_history'
        ])
    LOOP
        qualified_table := format('lazaro.%I', target_table);
        target_sequence := pg_get_serial_sequence(qualified_table, 'id');

        IF target_sequence IS NULL THEN
            target_sequence := format('lazaro.%I_id_seq', target_table);
            EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %s', target_sequence);
            EXECUTE format(
                'ALTER SEQUENCE %s OWNED BY %s.id',
                target_sequence,
                qualified_table
            );
            EXECUTE format(
                'ALTER TABLE %s ALTER COLUMN id SET DEFAULT nextval(%L)',
                qualified_table,
                target_sequence
            );
        END IF;

        EXECUTE format(
            'SELECT setval(%L, COALESCE((SELECT MAX(id) FROM %s), 0) + 1, false)',
            target_sequence,
            qualified_table
        );
    END LOOP;
END
$$;
