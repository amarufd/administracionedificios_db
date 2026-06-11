SET search_path TO lazaro, public;

CREATE TABLE rental_checkin_tokens (
    id         BIGSERIAL    PRIMARY KEY,
    rental_id  BIGINT       NOT NULL REFERENCES unit_short_term_rentals(id),
    token      VARCHAR(64)  NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ  NOT NULL,
    used_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rct_token     ON rental_checkin_tokens(token);
CREATE INDEX idx_rct_rental_id ON rental_checkin_tokens(rental_id);
