-- =============================================================================
-- Deleting an order outright (CASE_DELETE).
--
-- Cancelling keeps an order (it can be reopened); deleting removes it and
-- everything under it, for orders that shouldn't exist at all (a duplicate, a
-- test, one created by mistake). Admin-only by default — grant it to other
-- roles from the Roles page. Before an order is deleted, what was paid on it is
-- returned to the customer's wallet (V89) and a snapshot of the order is kept in
-- the order audit log (case_audit_events, which has no foreign keys and
-- survives the delete). Completed orders, and orders with a payment receipt
-- waiting to be verified, can't be deleted. Kept in sync with both
-- PermissionName enums.
-- =============================================================================

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'CASE_DELETE');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';
