-- V67: Fix cases orphaned by the LC/balance-payment consolidation (admin-api
-- commit 0e5de12, "consolidate LC/balance payment into single LC step").
-- That change collapsed LC_VERIFIED -> BALANCE_PAYMENT_PENDING -> BALANCE_SUBMITTED
-- -> BALANCE_VERIFIED -> IN_SHIPPING down to LC_VERIFIED -> AWAITING_LC_COPY ->
-- IN_SHIPPING, but only in admin-api's CaseStateValidator/CaseStatus -- any case
-- already sitting in one of the retired BALANCE_* statuses at that moment has no
-- transition defined out of it any more, so staff have no action to move it
-- forward. Move each such case to its equivalent status under the new model,
-- and record the correction in case_status_history so it shows on the case
-- timeline like any other transition.

INSERT INTO case_status_history (id, case_id, from_status, to_status, changed_by_role, transition_reason, created_at)
SELECT UUID(), id, status, 'AWAITING_LC_COPY', 'SYSTEM',
       'Automatic: migrated off the retired balance-payment sub-workflow (LC/balance consolidation, admin-api commit 0e5de12)',
       CURRENT_TIMESTAMP(6)
FROM cases
WHERE status IN ('BALANCE_PAYMENT_PENDING', 'BALANCE_SUBMITTED', 'BALANCE_REJECTED');

UPDATE cases
SET status = 'AWAITING_LC_COPY', updated_at = CURRENT_TIMESTAMP
WHERE status IN ('BALANCE_PAYMENT_PENDING', 'BALANCE_SUBMITTED', 'BALANCE_REJECTED');

-- A case whose balance payment was already verified is effectively ready to
-- ship under the new model (full payment is confirmed either way).
INSERT INTO case_status_history (id, case_id, from_status, to_status, changed_by_role, transition_reason, created_at)
SELECT UUID(), id, status, 'IN_SHIPPING', 'SYSTEM',
       'Automatic: migrated off the retired balance-payment sub-workflow (LC/balance consolidation, admin-api commit 0e5de12)',
       CURRENT_TIMESTAMP(6)
FROM cases
WHERE status = 'BALANCE_VERIFIED';

UPDATE cases
SET status = 'IN_SHIPPING', updated_at = CURRENT_TIMESTAMP
WHERE status = 'BALANCE_VERIFIED';
