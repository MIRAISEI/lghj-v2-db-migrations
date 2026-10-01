-- =============================================================================
-- Managed shipping methods (Shipping tab "Shipping Method").
--
-- The shipping method on a shipment arrangement / per-vehicle shipping row used
-- to be free text fed by a hard-coded RORO / CONTAINER dropdown. It is now a
-- reference to `shipping_methods`, a master-data list staff maintain themselves
-- (Supplier & Logistics Management -> Shipping Methods), seeded with the
-- methods LGH uses today.
--
--   shipping_methods                       name, description, sort_order,
--                                          status (1 active / 0 inactive),
--                                          soft delete. Inactive methods keep
--                                          resolving on existing shipments but
--                                          are not offered for new selections.
--   shipment_arrangements.shipping_method_id   replaces shipping_method (text)
--   case_shipment_vehicles.shipping_method_id  replaces shipping_method (text)
--
-- Legacy text values are carried over losslessly: every distinct value that
-- doesn't match a seeded name (e.g. the old generic "CONTAINER", which can't
-- be mapped to 20 GP vs 40 HQ) becomes an INACTIVE method with that name, and
-- rows are re-pointed by case-insensitive name match before the text columns
-- are dropped. Staff can then rename/activate/merge those by hand.
--
-- case_shipment_vehicles.shipping_method was never created by a migration —
-- it only exists where hibernate.ddl-auto=update added it — so everything
-- touching it is information_schema-guarded (same approach as V81).
--
-- Permissions SHIPPING_METHOD_READ / _WRITE / _DELETE: ADMIN and SHIPPING get
-- all three; every role that can edit case logistics (CASE_LOGISTICS_MANAGE)
-- gets READ, which it now depends on (to pick a method on the Shipping tab).
-- =============================================================================

-- ── shipping_methods ───────────────────────────────────────────────────────
CREATE TABLE shipping_methods (
    id          CHAR(36)         NOT NULL PRIMARY KEY DEFAULT (UUID()),
    name        VARCHAR(100)     NOT NULL,
    description VARCHAR(500)     NULL,
    sort_order  INT              NOT NULL DEFAULT 0 COMMENT 'Dropdown order, ascending',
    status      TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1: active, 0: inactive',
    deleted_at  TIMESTAMP        NULL DEFAULT NULL,
    created_at  TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Names are unique among non-deleted rows (case-insensitive); a
    -- soft-deleted name can be reused. NULLs don't collide in a UNIQUE index.
    live_name   VARCHAR(100) GENERATED ALWAYS AS (IF(deleted_at IS NULL, LOWER(name), NULL)) STORED,
    UNIQUE KEY uk_shipping_methods_live_name (live_name),
    INDEX idx_shipping_methods_status_sort (status, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO shipping_methods (id, name, description, sort_order, status) VALUES
    (UUID(), 'RORO',            'Roll-on/roll-off vessel',                    10, 1),
    (UUID(), 'RORO CBM',        'Roll-on/roll-off, charged per cubic metre',  20, 1),
    (UUID(), 'Container 20 GP', '20 ft general-purpose container',            30, 1),
    (UUID(), 'Container 40 HQ', '40 ft high-cube container',                  40, 1),
    (UUID(), 'Air Freight',     'Air cargo',                                  50, 1);

-- ── Carry over legacy free-text values ─────────────────────────────────────
INSERT INTO shipping_methods (id, name, description, sort_order, status)
SELECT UUID(), legacy.name, 'Carried over from the old fixed list (V84) - review, rename or deactivate.', 900, 0
FROM (
    SELECT DISTINCT TRIM(shipping_method) AS name
    FROM shipment_arrangements
    WHERE shipping_method IS NOT NULL AND TRIM(shipping_method) <> ''
) legacy
WHERE NOT EXISTS (SELECT 1 FROM shipping_methods m WHERE m.live_name = LOWER(legacy.name));

SET @csv_legacy_col = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'case_shipment_vehicles' AND column_name = 'shipping_method'
);

SET @sql = IF(@csv_legacy_col > 0,
    'INSERT INTO shipping_methods (id, name, description, sort_order, status)
     SELECT UUID(), legacy.name, ''Carried over from the old fixed list (V84) - review, rename or deactivate.'', 900, 0
     FROM (
         SELECT DISTINCT TRIM(shipping_method) AS name
         FROM case_shipment_vehicles
         WHERE shipping_method IS NOT NULL AND TRIM(shipping_method) <> ''''
     ) legacy
     WHERE NOT EXISTS (SELECT 1 FROM shipping_methods m WHERE m.live_name = LOWER(legacy.name))',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── shipment_arrangements ──────────────────────────────────────────────────
ALTER TABLE shipment_arrangements
    ADD COLUMN shipping_method_id CHAR(36) NULL AFTER booking_date,
    ADD CONSTRAINT fk_shipment_arrangements_shipping_method
        FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(id) ON DELETE SET NULL,
    ADD INDEX idx_shipment_arrangements_shipping_method (shipping_method_id);

UPDATE shipment_arrangements a
JOIN shipping_methods m ON m.live_name = LOWER(TRIM(a.shipping_method))
SET a.shipping_method_id = m.id
WHERE a.shipping_method IS NOT NULL;

ALTER TABLE shipment_arrangements DROP COLUMN shipping_method;

-- ── case_shipment_vehicles ─────────────────────────────────────────────────
ALTER TABLE case_shipment_vehicles
    ADD COLUMN shipping_method_id CHAR(36) NULL,
    ADD CONSTRAINT fk_case_shipment_vehicles_shipping_method
        FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(id) ON DELETE SET NULL,
    ADD INDEX idx_case_shipment_vehicles_shipping_method (shipping_method_id);

SET @sql = IF(@csv_legacy_col > 0,
    'UPDATE case_shipment_vehicles v
     JOIN shipping_methods m ON m.live_name = LOWER(TRIM(v.shipping_method))
     SET v.shipping_method_id = m.id
     WHERE v.shipping_method IS NOT NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@csv_legacy_col > 0,
    'ALTER TABLE case_shipment_vehicles DROP COLUMN shipping_method',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── Permissions ────────────────────────────────────────────────────────────
INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'SHIPPING_METHOD_READ'),
    (UUID(), 'SHIPPING_METHOD_WRITE'),
    (UUID(), 'SHIPPING_METHOD_DELETE');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name IN ('ADMIN', 'SHIPPING')
  AND p.name IN ('SHIPPING_METHOD_READ', 'SHIPPING_METHOD_WRITE', 'SHIPPING_METHOD_DELETE');

-- CASE_LOGISTICS_MANAGE now depends on SHIPPING_METHOD_READ.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT rp.role_id, p.id
FROM role_permissions rp
JOIN permissions lp ON lp.id = rp.permission_id AND lp.name = 'CASE_LOGISTICS_MANAGE'
CROSS JOIN permissions p
WHERE p.name = 'SHIPPING_METHOD_READ';
