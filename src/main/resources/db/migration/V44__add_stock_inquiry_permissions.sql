-- V44: Stock price inquiry permissions (read/write)

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'STOCK_INQUIRY_READ'),
    (UUID(), 'STOCK_INQUIRY_WRITE');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- SALES can read and action stock price inquiries.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('STOCK_INQUIRY_READ', 'STOCK_INQUIRY_WRITE')
WHERE r.name = 'SALES';
