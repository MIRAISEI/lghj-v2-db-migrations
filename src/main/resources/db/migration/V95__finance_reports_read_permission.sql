-- =============================================================================
-- FINANCE_REPORTS_READ ("View financial figures"): the money on the staff
-- dashboard — order value (CIF), average per vehicle, winning bid value, the
-- order value trend, the money columns of the order-type comparison, and the
-- amounts on recent bids. Without it the dashboard shows counts only, and the
-- admin API leaves the money out of its responses.
--
-- FINANCE gets it; ADMIN gets it like every other permission. Other roles can
-- be given it on the Roles page. Kept in sync with the admin API's
-- PermissionName enum.
-- =============================================================================

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'FINANCE_REPORTS_READ');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'FINANCE_REPORTS_READ'
WHERE r.name IN ('FINANCE', 'ADMIN');
