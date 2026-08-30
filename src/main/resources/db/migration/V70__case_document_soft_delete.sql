-- V70: Soft delete for case documents.
--
-- The Purchasing / Transport / Inspection "Attachments" widgets now accept
-- multiple files, each listed as a distinct document. Removing an attachment
-- is a soft delete: the row (and its stored file) stays, but every admin and
-- customer-facing query filters out rows where deleted_at IS NOT NULL (enforced
-- in the JPA entities via @SQLRestriction).

ALTER TABLE case_documents
    ADD COLUMN deleted_at DATETIME NULL COMMENT 'Soft-delete timestamp; NULL = active',
    ADD COLUMN deleted_by_user_id CHAR(36) NULL COMMENT 'Staff user who removed the attachment';

CREATE INDEX idx_case_documents_deleted_at ON case_documents (deleted_at);
