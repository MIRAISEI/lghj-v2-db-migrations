-- =============================================================================
-- Two-tier inventory: real (internal) stock vs public-portal stock.
--
-- inventory_vehicles now holds both kinds, told apart by stock_type:
--   * stock_type = 'Public Stock'  -> a listing published on the public portal
--   * any other stock_type         -> internal real stock ('Real Stock',
--                                     'Dealer Stock', 'Auction Stock', ...)
-- The public portal only ever shows Public Stock rows with status ACTIVE; a
-- public row is either ACTIVE or DRAFT (no on-hold / sold state).
--
-- A public row may be a *copy* of a real vehicle: source_vehicle_id points back
-- at it. Copies are independent snapshots -- editing one never touches the
-- other -- staff can re-sync a copy from its source on demand (last_synced_at
-- records when). Public rows created directly have source_vehicle_id NULL.
--
-- stock_type used to live only in inventory_vehicle_metadata (meta_key =
-- 'stock_type'); it is promoted to a real, indexed column here.
--
-- Written defensively (information_schema-guarded DDL) for the same reason as
-- V58: local dev runs with hibernate.ddl-auto=update, so the JPA entity may have
-- created some of these columns before this migration ever ran.
-- =============================================================================

-- ── 1. Columns / constraints ─────────────────────────────────────────────────

SET @exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND column_name = 'stock_type'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE inventory_vehicles ADD COLUMN stock_type VARCHAR(50) NOT NULL DEFAULT ''Real Stock'' COMMENT ''Public Stock = public portal listing; anything else = internal real stock'' AFTER stock_id',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND column_name = 'source_vehicle_id'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE inventory_vehicles ADD COLUMN source_vehicle_id CHAR(36) NULL COMMENT ''Real stock vehicle this public listing was copied from; NULL for real stock and for public listings created directly''',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND column_name = 'last_synced_at'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE inventory_vehicles ADD COLUMN last_synced_at DATETIME(6) NULL COMMENT ''When a public copy was last created/synced from its source vehicle''',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exists = (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND index_name = 'idx_inv_stock_type'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE inventory_vehicles ADD INDEX idx_inv_stock_type (stock_type)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- One public copy per real vehicle (MySQL allows many NULLs in a unique index).
SET @exists = (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND index_name = 'uq_inv_source_vehicle_id'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE inventory_vehicles ADD CONSTRAINT uq_inv_source_vehicle_id UNIQUE (source_vehicle_id)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exists = (
    SELECT COUNT(*) FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND constraint_name = 'fk_inv_source_vehicle'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE inventory_vehicles ADD CONSTRAINT fk_inv_source_vehicle FOREIGN KEY (source_vehicle_id) REFERENCES inventory_vehicles(id) ON DELETE SET NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── 2. Promote stock_type from metadata to the column ────────────────────────

UPDATE inventory_vehicles iv
JOIN inventory_vehicle_metadata m ON m.vehicle_id = iv.id AND m.meta_key = 'stock_type'
SET iv.stock_type = LEFT(TRIM(m.meta_value), 50)
WHERE m.meta_value IS NOT NULL AND TRIM(m.meta_value) <> '';

-- Rows the hibernate-created column may have left empty.
UPDATE inventory_vehicles SET stock_type = 'Real Stock' WHERE stock_type IS NULL OR stock_type = '';

-- ── 3. 'Dummy Stock' rows were the public-only entries ───────────────────────
-- Relabel them Public Stock. A dummy row that belongs to a customer or a case is
-- real bookkeeping, not a listing, so it is left alone.

UPDATE inventory_vehicles
SET stock_type = 'Public Stock'
WHERE stock_type = 'Dummy Stock'
  AND assigned_customer_id IS NULL
  AND source_case_id IS NULL;

-- A public listing is only ever ACTIVE (on the portal) or DRAFT (not). Relabelled
-- dummy rows may carry a real-stock status (ON_HOLD, SOLD_OUT, ...): take those
-- off the portal as drafts.
UPDATE inventory_vehicles
SET status = 'DRAFT'
WHERE stock_type = 'Public Stock'
  AND status NOT IN ('ACTIVE', 'DRAFT');

-- ── 4. Give every currently-published real vehicle a linked public copy ──────
-- So the public portal looks the same right after this ships. Mirrors what the
-- portal showed before (status ACTIVE) minus vehicles already assigned to a
-- customer, which should never have been listed. Public copies get a "P-"
-- stock id (stock_id is globally unique) and keep the original created_at so
-- the portal's newest-first ordering does not change.

-- CREATE ... AS SELECT (rather than an explicit column list) so real_id inherits
-- inventory_vehicles.id's collation and joins to it never hit a collation mismatch.
DROP TEMPORARY TABLE IF EXISTS tmp_public_copy_map;
CREATE TEMPORARY TABLE tmp_public_copy_map AS
SELECT iv.id AS real_id, UUID() AS public_id
FROM inventory_vehicles iv
WHERE iv.status = 'ACTIVE'
  AND iv.assigned_customer_id IS NULL
  AND iv.stock_type <> 'Public Stock'
  AND NOT EXISTS (SELECT 1 FROM inventory_vehicles c WHERE c.source_vehicle_id = iv.id);

INSERT INTO inventory_vehicles
    (id, chassis_no, stock_id, stock_type, status, source_vehicle_id, last_synced_at, created_at, updated_at)
SELECT map.public_id, iv.chassis_no, CONCAT('P-', iv.stock_id), 'Public Stock', 'ACTIVE',
       iv.id, CURRENT_TIMESTAMP(6), iv.created_at, CURRENT_TIMESTAMP(6)
FROM tmp_public_copy_map map
JOIN inventory_vehicles iv ON iv.id = map.real_id;

INSERT INTO inventory_vehicle_metadata (id, vehicle_id, meta_key, meta_value)
SELECT UUID(), map.public_id, md.meta_key, md.meta_value
FROM tmp_public_copy_map map
JOIN inventory_vehicle_metadata md ON md.vehicle_id = map.real_id
WHERE md.meta_key <> 'stock_type';

-- Media rows point at the same stored files as the source (no storage copy);
-- admin-api only deletes a stored file once no row references it any more.
INSERT INTO inventory_images
    (id, vehicle_id, file_path, file_name, mime_type, file_size_bytes, status, is_primary, sort_order, created_at)
SELECT UUID(), map.public_id, img.file_path, img.file_name, img.mime_type, img.file_size_bytes,
       img.status, img.is_primary, img.sort_order, img.created_at
FROM tmp_public_copy_map map
JOIN inventory_images img ON img.vehicle_id = map.real_id;

INSERT INTO inventory_videos
    (id, vehicle_id, file_path, file_name, mime_type, file_size_bytes, created_at)
SELECT UUID(), map.public_id, vid.file_path, vid.file_name, vid.mime_type, vid.file_size_bytes, vid.created_at
FROM tmp_public_copy_map map
JOIN inventory_videos vid ON vid.vehicle_id = map.real_id;

INSERT INTO inventory_vehicle_features (vehicle_id, feature_id)
SELECT map.public_id, f.feature_id
FROM tmp_public_copy_map map
JOIN inventory_vehicle_features f ON f.vehicle_id = map.real_id;

INSERT INTO inventory_vehicle_tags (vehicle_id, tag_id)
SELECT map.public_id, t.tag_id
FROM tmp_public_copy_map map
JOIN inventory_vehicle_tags t ON t.vehicle_id = map.real_id;

DROP TEMPORARY TABLE tmp_public_copy_map;

-- ── 5. stock_type now lives in the column only ───────────────────────────────

DELETE FROM inventory_vehicle_metadata WHERE meta_key = 'stock_type';
