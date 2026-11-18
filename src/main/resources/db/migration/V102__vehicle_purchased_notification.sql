-- =============================================================================
-- V102: "Vehicle purchased" announcement.
--
-- When a vehicle's purchase status is PURCHASED and an Auction Result Sheet is
-- attached, admin-api emails and notifies (in-app) every active staff user
-- holding VEHICLE_PURCHASED_NOTIFY. This replaces the WhatsApp message staff
-- used to post by hand.
--
-- case_vehicles.purchase_notification_sent_at
--   When the announcement was sent. It goes out once per vehicle: later edits,
--   re-uploads, or switching the status away and back don't send it again.
--   NULL = not sent yet.
--
--   Written defensively like V94/V99/V100: admin-api runs with
--   ddl-auto=update, so Hibernate may already have added the column. It's
--   added only if missing; otherwise it's brought to the same definition.
--
--   Backfill: vehicles that already meet both conditions are marked as sent,
--   so re-uploading a sheet on an older purchase doesn't announce it now.
--   Vehicles still waiting on their status or their sheet are left NULL and
--   are announced when the missing half arrives.
--
-- VEHICLE_PURCHASED_NOTIFY
--   Who receives the announcement. ADMIN gets it (ADMIN always gets every
--   permission); other teams are given it in Roles. Kept in sync with both
--   PermissionName enums.
-- =============================================================================

SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'case_vehicles'
      AND column_name = 'purchase_notification_sent_at');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE case_vehicles ADD COLUMN purchase_notification_sent_at DATETIME(6) NULL AFTER purchase_status',
    'ALTER TABLE case_vehicles MODIFY COLUMN purchase_notification_sent_at DATETIME(6) NULL');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE case_vehicles cv
SET cv.purchase_notification_sent_at = CURRENT_TIMESTAMP(6)
WHERE cv.purchase_status = 'PURCHASED'
  AND cv.purchase_notification_sent_at IS NULL
  AND EXISTS (
      SELECT 1 FROM case_documents d
      WHERE d.case_vehicle_id = cv.id
        AND d.document_type = 'AUCTION_RESULT_SHEET'
        AND d.deleted_at IS NULL
        AND (d.verification_status IS NULL OR d.verification_status <> 'VOIDED'));

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'VEHICLE_PURCHASED_NOTIFY');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';
