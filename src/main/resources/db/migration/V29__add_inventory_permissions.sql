-- Inventory permissions: read, write (create/update), delete.

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'INVENTORY_READ'),
    (UUID(), 'INVENTORY_WRITE'),
    (UUID(), 'INVENTORY_DELETE');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- BIDDING and SALES roles can read inventory.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'INVENTORY_READ'
WHERE r.name IN ('BIDDING', 'SALES');
