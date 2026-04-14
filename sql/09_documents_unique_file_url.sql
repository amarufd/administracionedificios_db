-- ============================================================
-- Migration 09: evitar documentos duplicados por URL en un condominio
-- ============================================================
SET search_path TO lazaro, public;

WITH ranked_documents AS (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY condominium_id, file_url
               ORDER BY id
           ) AS row_num
    FROM documents
)
DELETE FROM documents d
USING ranked_documents r
WHERE d.id = r.id
  AND r.row_num > 1;

CREATE UNIQUE INDEX IF NOT EXISTS uq_documents_condo_file_url
    ON documents (condominium_id, file_url);
