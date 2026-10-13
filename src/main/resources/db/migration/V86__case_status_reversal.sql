-- =============================================================================
-- Stepping an order back one status / reopening a cancelled order.
--
-- Staff can now move an order back (e.g. unpublish pricing, undo "bidding
-- complete") or reopen a cancelled one, through the admin approval queue
-- (change_requests, field ORDER_STATUS). The move is recorded in
-- case_status_history like any other transition, flagged as a reversal so the
-- clients render it as "moved back" and logic that reads the history as a
-- forward-only sequence (e.g. "when was the deposit verified", "the staff
-- remark for the current status") can tell it apart.
--
-- No new permission: requesting a step back needs the permission of the step
-- being undone (e.g. CASE_PRICING_PUBLISH to unpublish pricing, CASE_CANCEL to
-- reopen); approving it needs CHANGE_REQUEST_APPROVE.
-- =============================================================================

ALTER TABLE case_status_history
    ADD COLUMN is_reversal TINYINT(1) NOT NULL DEFAULT 0
        COMMENT '1: the order was moved back (step back / reopen), not forward';
