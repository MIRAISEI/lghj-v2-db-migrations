-- =============================================================================
-- Admin approval workflow for sensitive field edits.
--
-- A staff member without CHANGE_REQUEST_APPROVE who edits an *existing* value of
-- an approval-gated field (chassis number, purchase value, supplier, CIF value,
-- LC value on a case vehicle -- more entity types/fields can be added later
-- without schema changes) does not change the record. Instead one row per
-- field is written here as PENDING; an approver then approves (the value is
-- applied) or rejects it. Holders of CHANGE_REQUEST_APPROVE bypass the queue.
--
-- entity_type / entity_id are deliberately polymorphic (no FK) so the same
-- table can later serve inventory records or other views. old/new_value hold
-- the raw values (supplier -> supplier id); old/new_display hold what the
-- approver reads (supplier -> company name). The names/labels are snapshots so
-- the log stays readable after users or records are renamed or removed.
-- =============================================================================

CREATE TABLE IF NOT EXISTS change_requests (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),

    entity_type VARCHAR(64) NOT NULL COMMENT 'e.g. CASE_VEHICLE',
    entity_id CHAR(36) NOT NULL,
    case_id CHAR(36) NULL COMMENT 'owning order, for deep-linking',
    entity_label VARCHAR(255) NULL COMMENT 'human label of the record at request time',

    field_key VARCHAR(64) NOT NULL COMMENT 'e.g. CHASSIS_NUMBER, PURCHASE_VALUE, SUPPLIER, CIF_VALUE, LC_VALUE',
    field_label VARCHAR(100) NOT NULL,
    old_value TEXT NULL,
    new_value TEXT NULL,
    old_display TEXT NULL,
    new_display TEXT NULL,

    status ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'SUPERSEDED') NOT NULL DEFAULT 'PENDING',

    auto_approved TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1: editor held CHANGE_REQUEST_APPROVE, applied immediately (audit row only)',

    requested_by CHAR(36) NOT NULL,
    requested_by_name VARCHAR(255) NULL,
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    reviewed_by CHAR(36) NULL,
    reviewed_by_name VARCHAR(255) NULL,
    reviewed_at TIMESTAMP NULL DEFAULT NULL,
    review_note VARCHAR(1000) NULL,

    INDEX idx_change_requests_status_requested (status, requested_at),
    INDEX idx_change_requests_entity_field (entity_type, entity_id, field_key, status),
    INDEX idx_change_requests_requester (requested_by, requested_at)
);

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'CHANGE_REQUEST_APPROVE');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';
