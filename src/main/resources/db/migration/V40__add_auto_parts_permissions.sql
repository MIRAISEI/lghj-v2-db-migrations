-- V40: Auto Parts permissions (catalog read/write/delete, inquiry read/write)

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'AUTO_PARTS_READ'),
    (UUID(), 'AUTO_PARTS_WRITE'),
    (UUID(), 'AUTO_PARTS_DELETE'),
    (UUID(), 'AUTO_PARTS_INQUIRY_READ'),
    (UUID(), 'AUTO_PARTS_INQUIRY_WRITE');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- BIDDING and SALES can read the auto parts catalog.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'AUTO_PARTS_READ'
WHERE r.name IN ('BIDDING', 'SALES');

-- SALES can read and action auto parts inquiries.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('AUTO_PARTS_INQUIRY_READ', 'AUTO_PARTS_INQUIRY_WRITE')
WHERE r.name = 'SALES';
