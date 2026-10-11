-- =============================================================================
-- Finance: one permission for verifying payments, one for approving wallet
-- money going out.
--
-- PAYMENT_VERIFY replaces CASE_DEPOSIT_VERIFY, CASE_BALANCE_VERIFY and
-- CASE_CHARGE_VERIFY: checking a receipt against the amount the customer says
-- they paid (and what was required) is the same job whatever it pays for, done
-- by the same people (Finance → Payments, or the order page). Receipts on an
-- order also need CASE_READ; wallet top-up receipts also need WALLET_READ.
--
-- WALLET_APPROVE approves wallet refunds and adjustments (Finance → Wallet
-- requests), which were approved by CHANGE_REQUEST_APPROVE holders until now;
-- the Approvals page keeps order data changes only.
--
-- Every role that held one of the old verify permissions gets PAYMENT_VERIFY,
-- and every CHANGE_REQUEST_APPROVE holder gets WALLET_APPROVE, so nobody loses
-- access. FINANCE also gets WALLET_READ (the Finance → Wallets list). Kept in
-- sync with both PermissionName enums.
-- =============================================================================

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'PAYMENT_VERIFY'),
    (UUID(), 'WALLET_APPROVE');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT DISTINCT rp.role_id, np.id
FROM role_permissions rp
JOIN permissions op ON op.id = rp.permission_id
JOIN permissions np ON np.name = 'PAYMENT_VERIFY'
WHERE op.name IN ('CASE_DEPOSIT_VERIFY', 'CASE_BALANCE_VERIFY', 'CASE_CHARGE_VERIFY');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT DISTINCT rp.role_id, np.id
FROM role_permissions rp
JOIN permissions op ON op.id = rp.permission_id
JOIN permissions np ON np.name = 'WALLET_APPROVE'
WHERE op.name = 'CHANGE_REQUEST_APPROVE';

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('PAYMENT_VERIFY', 'WALLET_READ')
WHERE r.name = 'FINANCE';

-- The old verify permissions go (both enums no longer know them).
DELETE rp FROM role_permissions rp
JOIN permissions p ON p.id = rp.permission_id
WHERE p.name IN ('CASE_DEPOSIT_VERIFY', 'CASE_BALANCE_VERIFY', 'CASE_CHARGE_VERIFY');

DELETE FROM permissions
WHERE name IN ('CASE_DEPOSIT_VERIFY', 'CASE_BALANCE_VERIFY', 'CASE_CHARGE_VERIFY');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';
