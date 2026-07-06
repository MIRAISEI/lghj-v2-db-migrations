-- Approval/deposit workflow redesign:
--   SUBMITTED            -> WAITING_FOR_APPROVAL
--   (new)                   APPROVED
--   DEPOSIT_SUBMITTED    -> AWAITING_DEPOSIT_VERIFICATION
--   DEPOSIT_VERIFIED     -> dropped (verify now goes straight to IN_BIDDING)
-- plus three new staff permissions for the approve / set-deposit / proxy steps.

-- 1. New permissions.
INSERT IGNORE INTO permissions (id, name)
VALUES
    (UUID(), 'CASE_APPROVE'),
    (UUID(), 'CASE_SET_DEPOSIT'),
    (UUID(), 'CASE_DEPOSIT_SUBMIT');

-- 2. System admins get every permission (idempotent).
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- 3. Role-specific grants, matching DataInitializer / the validator graph.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p
WHERE (r.name = 'BIDDING' AND p.name IN ('CASE_APPROVE', 'CASE_SET_DEPOSIT'))
   OR (r.name = 'SALES'   AND p.name IN ('CASE_DEPOSIT_SUBMIT'));

-- 4. Remap existing live case statuses to the new model. (case_status_history
--    rows keep their original values as an audit trail.)
UPDATE cases SET status = 'WAITING_FOR_APPROVAL'          WHERE status = 'SUBMITTED';
UPDATE cases SET status = 'AWAITING_DEPOSIT_VERIFICATION' WHERE status = 'DEPOSIT_SUBMITTED';
UPDATE cases SET status = 'IN_BIDDING'                    WHERE status = 'DEPOSIT_VERIFIED';
