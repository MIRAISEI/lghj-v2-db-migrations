-- =============================================================================
-- Rename LC case-status and LC document-type values to match the redesigned
-- LC workflow:
--   LC_PENDING   -> LC_REQUIRED                  ("LC Required")
--   LC_SUBMITTED -> LC_DRAFT_VERIFICATION_NEEDED  ("LC Draft Verification Needed")
--   LC_REJECTED  -> LC_REQUIRED                  (folded in: reject now sends the
--                                                  case back to LC_REQUIRED with a
--                                                  remark instead of a separate status)
-- Document type: LC / LC_COPY -> LC_DRAFT
-- =============================================================================

UPDATE cases
SET status = 'LC_REQUIRED'
WHERE status IN ('LC_PENDING', 'LC_REJECTED');

UPDATE cases
SET status = 'LC_DRAFT_VERIFICATION_NEEDED'
WHERE status = 'LC_SUBMITTED';

UPDATE case_status_history
SET from_status = 'LC_REQUIRED'
WHERE from_status IN ('LC_PENDING', 'LC_REJECTED');

UPDATE case_status_history
SET to_status = 'LC_REQUIRED'
WHERE to_status IN ('LC_PENDING', 'LC_REJECTED');

UPDATE case_status_history
SET from_status = 'LC_DRAFT_VERIFICATION_NEEDED'
WHERE from_status = 'LC_SUBMITTED';

UPDATE case_status_history
SET to_status = 'LC_DRAFT_VERIFICATION_NEEDED'
WHERE to_status = 'LC_SUBMITTED';

UPDATE case_documents
SET document_type = 'LC_DRAFT'
WHERE document_type IN ('LC', 'LC_COPY');
