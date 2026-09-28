-- =============================================================================
-- Transport / shipment arrangements own their status, payment, tracking and
-- documents -- there is no per-vehicle version of these while a vehicle is
-- linked to an arrangement.
--
--   Transport arrangement : transport status (already on the arrangement),
--                           payment status (column existed since V60, was
--                           unused -- the vehicle's own value was shown),
--                           attachments, payment receipt.
--   Shipment arrangement  : shipment tracking no. (new column here),
--                           Attachment BL.
--
-- Documents stay ordinary case_documents rows, one per linked vehicle, so every
-- existing read path (case tabs, customer portal, Documents tab) shows them on
-- each vehicle unchanged. The two new nullable columns mark the rows an
-- arrangement created, so the arrangement can list, replace and remove them as
-- one set. Rows without either column are ordinary per-vehicle documents
-- (including everything uploaded before this migration).
--
-- Written defensively (information_schema-guarded DDL): local dev runs with
-- hibernate.ddl-auto=update, which may have created these columns from the JPA
-- entities before this migration ran (same reason as V58 / V76).
-- =============================================================================

-- ── 1. case_documents: which arrangement created the row ─────────────────────

SET @exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'case_documents' AND column_name = 'transport_arrangement_id'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE case_documents ADD COLUMN transport_arrangement_id CHAR(36) NULL COMMENT ''Set when a transport arrangement created this document for every linked vehicle''',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'case_documents' AND column_name = 'shipment_arrangement_id'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE case_documents ADD COLUMN shipment_arrangement_id CHAR(36) NULL COMMENT ''Set when a shipment arrangement created this document for every linked vehicle''',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exists = (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'case_documents' AND index_name = 'idx_case_documents_transport_arrangement'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE case_documents ADD INDEX idx_case_documents_transport_arrangement (transport_arrangement_id)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exists = (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'case_documents' AND index_name = 'idx_case_documents_shipment_arrangement'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE case_documents ADD INDEX idx_case_documents_shipment_arrangement (shipment_arrangement_id)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── 2. shipment_arrangements: tracking no. ───────────────────────────────────

SET @exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'shipment_arrangements' AND column_name = 'shipment_tracking_no'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE shipment_arrangements ADD COLUMN shipment_tracking_no VARCHAR(255) NULL AFTER bl_status',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── 3. case_shipment_vehicles: columns the backfill below reads ──────────────
-- CaseShipmentVehicle has always mapped payment_status and shipment_tracking_no,
-- but no earlier migration created them (existing databases got them from
-- hibernate.ddl-auto=update). Create them where missing so a fresh database
-- can run the backfill; a no-op everywhere the columns already exist.

SET @exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'case_shipment_vehicles' AND column_name = 'payment_status'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE case_shipment_vehicles ADD COLUMN payment_status VARCHAR(50) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'case_shipment_vehicles' AND column_name = 'shipment_tracking_no'
);
SET @sql = IF(@exists = 0,
    'ALTER TABLE case_shipment_vehicles ADD COLUMN shipment_tracking_no VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── 4. Backfill the arrangement-level values from what vehicles held ─────────

-- Transport payment status: PAID only if every linked vehicle / leg was PAID,
-- otherwise UNPAID. Arrangements that already carry a value are left alone.
UPDATE transport_arrangements ta
SET ta.payment_status = CASE
    WHEN (EXISTS (SELECT 1 FROM case_shipment_vehicles sv WHERE sv.transport_arrangement_id = ta.id)
          OR EXISTS (SELECT 1 FROM case_shipment_vehicle_legs l WHERE l.transport_arrangement_id = ta.id))
     AND NOT EXISTS (SELECT 1 FROM case_shipment_vehicles sv
                     WHERE sv.transport_arrangement_id = ta.id AND COALESCE(sv.payment_status, '') <> 'PAID')
     AND NOT EXISTS (SELECT 1 FROM case_shipment_vehicle_legs l
                     WHERE l.transport_arrangement_id = ta.id AND COALESCE(l.payment_status, '') <> 'PAID')
    THEN 'PAID' ELSE 'UNPAID' END
WHERE ta.payment_status IS NULL OR ta.payment_status = '';

-- Shipment tracking no.: vehicles under one shipment used to hold their own; keep
-- every distinct value (comma-separated) rather than silently dropping any.
UPDATE shipment_arrangements sa
SET sa.shipment_tracking_no = (
    SELECT LEFT(GROUP_CONCAT(DISTINCT sv.shipment_tracking_no ORDER BY sv.shipment_tracking_no SEPARATOR ', '), 255)
    FROM case_shipment_vehicles sv
    WHERE sv.shipment_arrangement_id = sa.id
      AND sv.shipment_tracking_no IS NOT NULL AND sv.shipment_tracking_no <> '')
WHERE sa.shipment_tracking_no IS NULL;
