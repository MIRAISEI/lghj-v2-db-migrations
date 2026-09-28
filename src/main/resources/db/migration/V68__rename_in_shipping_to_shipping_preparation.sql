-- =============================================================================
-- Rename the IN_SHIPPING case status to SHIPPING_PREPARATION. The old name
-- was misleading: this status is set the instant the LC copy is received
-- (before any transport/inspection/shipment booking has actually been
-- arranged), not once shipping is genuinely under way.
-- =============================================================================

UPDATE cases
SET status = 'SHIPPING_PREPARATION'
WHERE status = 'IN_SHIPPING';

UPDATE case_status_history
SET from_status = 'SHIPPING_PREPARATION'
WHERE from_status = 'IN_SHIPPING';

UPDATE case_status_history
SET to_status = 'SHIPPING_PREPARATION'
WHERE to_status = 'IN_SHIPPING';
