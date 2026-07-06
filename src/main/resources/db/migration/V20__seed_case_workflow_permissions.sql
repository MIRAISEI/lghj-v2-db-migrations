-- Case-workflow permissions. These exist in the PermissionName enum and are
-- enforced by CaseStateValidator, but were never seeded by a migration (V1 only
-- seeded the USER_*/ROLE_* permissions, and DataInitializer is disabled outside
-- dev). Without these rows the staff case-transition actions are unavailable.

INSERT IGNORE INTO permissions (id, name)
VALUES
    (UUID(), 'CASE_SUBMIT'),
    (UUID(), 'CASE_REVIEW'),
    (UUID(), 'CASE_DEPOSIT_VERIFY'),
    (UUID(), 'CASE_BID_MANAGE'),
    (UUID(), 'CASE_PRICING_PUBLISH'),
    (UUID(), 'CASE_LC_VERIFY'),
    (UUID(), 'CASE_BALANCE_VERIFY'),
    (UUID(), 'CASE_SHIPPING_MANAGE'),
    (UUID(), 'CASE_CANCEL');

-- System admins get every permission (including the new case permissions and
-- any seeded earlier). Idempotent via the role_permissions PK + INSERT IGNORE.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- Role-specific case permissions, matching DataInitializer / the validator graph.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p
WHERE (r.name = 'BIDDING'  AND p.name IN ('CASE_SUBMIT', 'CASE_REVIEW', 'CASE_BID_MANAGE'))
   OR (r.name = 'SALES'    AND p.name IN ('CASE_SUBMIT', 'CASE_PRICING_PUBLISH'))
   OR (r.name = 'FINANCE'  AND p.name IN ('CASE_DEPOSIT_VERIFY', 'CASE_LC_VERIFY', 'CASE_BALANCE_VERIFY'))
   OR (r.name = 'SHIPPING' AND p.name IN ('CASE_SHIPPING_MANAGE'));
