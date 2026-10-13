-- =============================================================================
-- Withdrawing an inspection FAIL recorded by mistake.
--
-- A FAIL attempt opens an inspection resolution and notifies the customer. If
-- it was recorded by mistake (wrong vehicle, wrong result) and nobody has acted
-- on it yet (no resolution path chosen), staff can withdraw it through the
-- admin approval queue (change_requests). Nothing is deleted:
--   * the attempt keeps its row, marked voided (who, when, why), and no longer
--     counts as the vehicle's inspection result;
--   * its resolution is closed as VOIDED, so no failure workflow is shown.
-- =============================================================================

ALTER TABLE inspection_attempts
    ADD COLUMN voided_at DATETIME NULL COMMENT 'set when a mistaken result was withdrawn',
    ADD COLUMN voided_by_user_id CHAR(36) NULL,
    ADD COLUMN void_reason VARCHAR(1000) NULL;

ALTER TABLE inspection_resolutions
    MODIFY COLUMN status ENUM(
        'OPEN',
        'RESOLVED_REINSPECT',
        'FIX_COST_PENDING_CUSTOMER',
        'FIX_COST_REJECTED',
        'FIX_COST_AWAITING_PROOF',
        'FIX_COST_AWAITING_VERIFICATION',
        'FIX_COST_VERIFIED',
        'FIX_IN_PROGRESS',
        'RESOLVED_FIX_AND_REINSPECT',
        'REAUCTION_PENDING_CUSTOMER',
        'REAUCTION_LOSS_AWAITING_PROOF',
        'REAUCTION_AGREED_NO_LOSS',
        'REAUCTION_LOSS_AWAITING_VERIFICATION',
        'REAUCTION_LOSS_VERIFIED',
        'RESOLVED_REAUCTION',
        'VOIDED'
    ) NOT NULL DEFAULT 'OPEN';
