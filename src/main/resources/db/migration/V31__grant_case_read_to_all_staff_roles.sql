-- CASE_READ was only granted to ADMIN, BIDDING and SALES in V28.
-- Every staff role (see RequiresStaffRole: ADMIN, BIDDING, SALES, FINANCE, SHIPPING)
-- should be able to view cases, so extend CASE_READ to FINANCE and SHIPPING too.

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'CASE_READ'
WHERE r.name IN ('FINANCE', 'SHIPPING');
