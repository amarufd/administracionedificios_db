ALTER TABLE common_expenses
    ADD COLUMN IF NOT EXISTS version_no INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS budget_adjustment NUMERIC(14,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_to_prorate NUMERIC(14,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS reserve_fund NUMERIC(14,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS individual_charges NUMERIC(14,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS annexes TEXT,
    ADD COLUMN IF NOT EXISTS total_to_collect NUMERIC(14,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS is_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS source_file_name VARCHAR(255),
    ADD COLUMN IF NOT EXISTS source_format VARCHAR(20),
    ADD COLUMN IF NOT EXISTS notes TEXT;

UPDATE common_expenses
SET budget_adjustment = COALESCE(budget_adjustment, 0),
    total_to_prorate = CASE
        WHEN COALESCE(total_to_prorate, 0) = 0 THEN total_amount + COALESCE(budget_adjustment, 0)
        ELSE total_to_prorate
    END,
    reserve_fund = COALESCE(reserve_fund, 0),
    individual_charges = COALESCE(individual_charges, 0),
    total_to_collect = CASE
        WHEN COALESCE(total_to_collect, 0) = 0 THEN total_amount + COALESCE(budget_adjustment, 0) + COALESCE(reserve_fund, 0) + COALESCE(individual_charges, 0)
        ELSE total_to_collect
    END,
    is_confirmed = TRUE,
    confirmed_at = COALESCE(confirmed_at, created_at);

ALTER TABLE common_expenses
    DROP CONSTRAINT IF EXISTS common_expenses_condominium_id_period_yyyymm_key;

CREATE UNIQUE INDEX IF NOT EXISTS idx_common_expenses_period_version
    ON common_expenses(condominium_id, period_yyyymm, version_no);

CREATE UNIQUE INDEX IF NOT EXISTS idx_common_expenses_period_confirmed
    ON common_expenses(condominium_id, period_yyyymm)
    WHERE is_confirmed = TRUE;
