SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS surveys (
    id              BIGSERIAL PRIMARY KEY,
    condominium_id  BIGINT NOT NULL REFERENCES condominiums(id),
    title           VARCHAR(160) NOT NULL,
    description     TEXT,
    start_at        TIMESTAMP NOT NULL,
    end_at          TIMESTAMP NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'ABIERTA'
                        CHECK (status IN ('ABIERTA','CERRADA')),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (end_at > start_at)
);

CREATE TABLE IF NOT EXISTS survey_options (
    id              BIGSERIAL PRIMARY KEY,
    survey_id       BIGINT NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
    option_label    VARCHAR(120) NOT NULL
);

CREATE TABLE IF NOT EXISTS survey_responses (
    survey_id       BIGINT NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
    option_id       BIGINT NOT NULL REFERENCES survey_options(id) ON DELETE CASCADE,
    user_id         BIGINT NOT NULL REFERENCES users(id),
    responded_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (survey_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_surveys_condo_status ON surveys(condominium_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_survey_options_survey ON survey_options(survey_id);

