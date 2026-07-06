-- Add the two new bid permissions split out from CASE_BID_MANAGE.
-- CASE_BID_CREATE : create manual bid cases (POST /cases/manual)
-- CASE_BID_OUTCOME: mark per-vehicle bid outcomes (PUT /vehicles/{id}/bid-outcome)

INSERT IGNORE INTO permissions (id, name)
VALUES
    (UUID(), 'CASE_BID_CREATE'),
    (UUID(), 'CASE_BID_OUTCOME');

-- ADMIN gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- BIDDING role gets both new permissions.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('CASE_BID_CREATE', 'CASE_BID_OUTCOME')
WHERE r.name = 'BIDDING';
