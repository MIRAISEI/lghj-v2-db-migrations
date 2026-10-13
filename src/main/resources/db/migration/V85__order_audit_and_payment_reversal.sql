-- =============================================================================
-- Order audit trail + reversing a verified payment.
--
-- 1. case_audit_events: a staff-only, append-only log of changes to an order.
--    case_activities can't be used for this because the customer timeline in
--    public-api shows every case_activities row, which would leak internal data
--    such as vendors, purchase values and payment statuses. Each row is one
--    field change, or one action (created / removed / linked / unlinked / voided)
--    on a subject (shipment vehicle, transport leg, arrangement, document,
--    payment proof, ...). event_id groups the rows written by one save.
--
--    The table has no foreign keys on purpose, so the log survives if a case,
--    vehicle or user row is later removed. Who made the change is the user (id
--    and name); no role is kept. old_value / new_value and actor_name
--    are display snapshots (vendor -> company name, user -> name) so the log
--    stays readable after records are renamed or deleted. The application only
--    ever INSERTs into this table.
--
-- 2. Payment reversal: a verified (APPROVED) advance or balance receipt can be
--    voided, or have its verified amount corrected, through the admin approval
--    queue (change_requests, CHANGE_REQUEST_APPROVE). A voided proof keeps its
--    row, file and original verification details; it just stops counting as
--    paid. voided_at / voided_by_user_id / void_reason record who reversed it
--    and why.
--
-- Requesting a reversal reuses CASE_DEPOSIT_VERIFY / CASE_BALANCE_VERIFY and
-- approving it reuses CHANGE_REQUEST_APPROVE. Reading the audit log has its own
-- permission, AUDIT_LOG_READ, seeded by V88.
-- =============================================================================

CREATE TABLE IF NOT EXISTS case_audit_events (
    id CHAR(36) PRIMARY KEY,
    event_id CHAR(36) NOT NULL COMMENT 'groups the rows written by one save',

    case_id CHAR(36) NOT NULL,
    case_vehicle_id CHAR(36) NULL COMMENT 'NULL = order-level',

    area VARCHAR(32) NULL COMMENT 'which part of the order: PAYMENTS, PURCHASING, BIDDING, VEHICLE, CUSTOMER, TRANSPORT, INSPECTION, SHIPPING, DOCUMENTS, STATUS',
    subject_type VARCHAR(64) NOT NULL COMMENT 'e.g. SHIPMENT_VEHICLE, TRANSPORT_LEG, TRANSPORT_ARRANGEMENT, DOCUMENT, PAYMENT_PROOF',
    subject_id CHAR(36) NULL,
    subject_label VARCHAR(255) NULL COMMENT 'human label at the time, e.g. "Leg 2", file name',

    action VARCHAR(64) NOT NULL COMMENT 'CREATED, UPDATED, DELETED, LINKED, UNLINKED, UPLOADED, REMOVED, VOIDED, AMOUNT_CORRECTED, STATUS_CHANGED',
    field_key VARCHAR(100) NULL COMMENT 'NULL for whole-subject actions',
    old_value TEXT NULL,
    new_value TEXT NULL,
    reason VARCHAR(1000) NULL,
    approval VARCHAR(16) NULL COMMENT 'how a gated value was applied: FIRST_ENTRY, DIRECT (approver), APPROVED (request), SET (workflow step)',

    actor_user_id CHAR(36) NULL COMMENT 'NULL = system / automatic',
    actor_name VARCHAR(255) NULL,

    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    INDEX idx_case_audit_case_created (case_id, created_at),
    INDEX idx_case_audit_case_area_created (case_id, area, created_at),
    INDEX idx_case_audit_vehicle_created (case_vehicle_id, created_at),
    INDEX idx_case_audit_subject (subject_type, subject_id)
);

ALTER TABLE case_documents
    MODIFY COLUMN verification_status ENUM('PENDING', 'APPROVED', 'REJECTED', 'VOIDED') DEFAULT 'PENDING',
    ADD COLUMN voided_at DATETIME NULL COMMENT 'set when a verified payment proof was reversed',
    ADD COLUMN voided_by_user_id CHAR(36) NULL,
    ADD COLUMN void_reason VARCHAR(1000) NULL;
