-- SUBSCRIPTION_READ: view user subscription records.

INSERT IGNORE INTO permissions (id, name)
VALUES (UUID(), 'SUBSCRIPTION_READ');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- SALES role can view subscriptions.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'SUBSCRIPTION_READ'
WHERE r.name = 'SALES';
