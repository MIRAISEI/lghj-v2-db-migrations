-- =============================================================================
-- Migrate case_vehicles.bid_date into case_vehicle_metadata, then drop it
-- =============================================================================
-- A vehicle's bid date now lives in case_vehicle_metadata under the
-- 'auction_date' key (date part) and 'auction_time' (time part), matching the
-- metadata already written by the public bid flow. Rows whose date only
-- existed in the legacy bid_date column (staff-scheduled vehicles, manual
-- cases, and bids placed before the metadata was written) are migrated first.
-- Existing auction_date / auction_time metadata is left untouched.

-- 1. Date part -> auction_date (only where the metadata is missing)
INSERT INTO case_vehicle_metadata (id, case_vehicle_id, meta_key, meta_value)
SELECT UUID(), v.id, 'auction_date', SUBSTRING_INDEX(v.bid_date, ' ', 1)
FROM case_vehicles v
WHERE v.bid_date IS NOT NULL AND v.bid_date <> ''
  AND NOT EXISTS (
      SELECT 1 FROM case_vehicle_metadata m
      WHERE m.case_vehicle_id = v.id AND m.meta_key = 'auction_date');

-- 2. Time part -> auction_time ("HH:mm", skipping meaningless midnights that
--    came from expire-date-derived values)
INSERT INTO case_vehicle_metadata (id, case_vehicle_id, meta_key, meta_value)
SELECT UUID(), v.id, 'auction_time', SUBSTRING(SUBSTRING_INDEX(v.bid_date, ' ', -1), 1, 5)
FROM case_vehicles v
WHERE v.bid_date LIKE '% %'
  AND SUBSTRING(SUBSTRING_INDEX(v.bid_date, ' ', -1), 1, 5) <> '00:00'
  AND NOT EXISTS (
      SELECT 1 FROM case_vehicle_metadata m
      WHERE m.case_vehicle_id = v.id AND m.meta_key = 'auction_time');

-- 3. Drop the legacy column
ALTER TABLE case_vehicles DROP COLUMN bid_date;
