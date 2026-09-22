-- =============================================================================
-- Per-order advance-payment waiver ("temporary Trusted Partner").
--
-- Staff without CHANGE_REQUEST_APPROVE can ask an admin to waive the advance
-- payment for ONE order. The request is a change_requests row (entity_type
-- 'CASE', field_key 'ADVANCE_PAYMENT_WAIVER'); once approved, the order carries
-- advance_payment_waived = 1 and is treated exactly like an order of a Trusted
-- Partner customer: the deposit stages are skipped / no deposit is collected.
-- The waiver belongs to the order, not the customer, so it never affects any
-- other order of the same customer.
--
-- change_requests.request_note holds the requester's reason so the approver can
-- read why the change was asked for.
-- =============================================================================

ALTER TABLE cases
    ADD COLUMN advance_payment_waived TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN advance_payment_waived_by CHAR(36) NULL,
    ADD COLUMN advance_payment_waived_at TIMESTAMP NULL DEFAULT NULL;

ALTER TABLE change_requests
    ADD COLUMN request_note VARCHAR(1000) NULL AFTER new_display;
