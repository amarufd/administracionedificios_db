-- Legal documents: signature tracking
ALTER TABLE documents
    ADD COLUMN IF NOT EXISTS requires_signature BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS signature_status VARCHAR(20) NOT NULL DEFAULT 'NO_REQUIERE'
        CHECK (signature_status IN ('NO_REQUIERE','PENDIENTE','FIRMADO')),
    ADD COLUMN IF NOT EXISTS signer_name VARCHAR(140),
    ADD COLUMN IF NOT EXISTS signer_role VARCHAR(80),
    ADD COLUMN IF NOT EXISTS signed_at TIMESTAMP;

UPDATE documents
SET signature_status = CASE
    WHEN requires_signature AND signed_at IS NOT NULL THEN 'FIRMADO'
    WHEN requires_signature THEN 'PENDIENTE'
    ELSE 'NO_REQUIERE'
END;
