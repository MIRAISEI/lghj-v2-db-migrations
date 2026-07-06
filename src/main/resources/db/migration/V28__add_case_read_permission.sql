-- CASE_READ: view bid request cases (list + detail).
-- Required to access the Bid Requests page and any case read endpoint.

INSERT IGNORE INTO permissions (id, name)
VALUES (UUID(), 'CASE_READ');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- BIDDING and SALES roles need to view bid requests.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'CASE_READ'
WHERE r.name IN ('BIDDING', 'SALES');
