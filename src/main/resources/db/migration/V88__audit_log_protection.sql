-- =============================================================================
-- Protecting the order audit log (case_audit_events, V85).
--
-- 1. Tamper-proof: rows can only be inserted. The application never updates or
--    deletes them; these triggers make the database refuse it too, whoever
--    tries (the application's own user, or someone with direct access).
--    Correcting a mistake is done in the order itself, which writes a new row.
--
--    Note: with binary logging on, creating triggers needs the TRIGGER privilege
--    plus SUPER, or log_bin_trust_function_creators = 1, for the migration user.
--
-- 2. Its own permission: AUDIT_LOG_READ ("View Order Audit Log") instead of
--    everyone with CASE_READ. Seeded for ADMIN and for every role that can
--    approve change requests (the people who review corrections); grant it to
--    other roles from the Roles page. Also needs CASE_READ (enforced by the
--    PermissionName dependency map). Kept in sync with both PermissionName enums.
-- =============================================================================

DROP TRIGGER IF EXISTS case_audit_events_no_update;
CREATE TRIGGER case_audit_events_no_update
    BEFORE UPDATE ON case_audit_events
    FOR EACH ROW
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'case_audit_events is append-only: rows cannot be updated';

DROP TRIGGER IF EXISTS case_audit_events_no_delete;
CREATE TRIGGER case_audit_events_no_delete
    BEFORE DELETE ON case_audit_events
    FOR EACH ROW
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'case_audit_events is append-only: rows cannot be deleted';

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'AUDIT_LOG_READ');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- Roles that approve corrections can read the log they're judged against.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT DISTINCT rp.role_id, audit.id
FROM role_permissions rp
JOIN permissions approve ON approve.id = rp.permission_id AND approve.name = 'CHANGE_REQUEST_APPROVE'
JOIN permissions audit ON audit.name = 'AUDIT_LOG_READ';
