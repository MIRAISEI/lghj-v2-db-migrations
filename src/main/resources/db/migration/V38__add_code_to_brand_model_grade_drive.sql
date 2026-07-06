-- V38: Add `code` (raw synced value from avto.jp, used to dedupe re-syncs) to the
-- remaining avto.jp-synced catalog tables, matching the pattern already used by
-- vehicle_colors/vehicle_transmissions (V32). `name` remains the Pascal-cased
-- display name shown to users; `code` is the exact raw vendor value.
--
-- Brands and Drives are flat lists (like Colors/Transmissions), so `code` is
-- globally unique there. Models and Grades are scoped to a parent (brand/model)
-- and the same raw name legitimately repeats across different parents (e.g. many
-- models share the raw grade "G" or "Limited"), so their uniqueness is scoped to
-- the parent instead of global.

ALTER TABLE `vehicle_brands`
  ADD COLUMN `code` varchar(255) DEFAULT NULL COMMENT 'Raw synced MARKA_NAME value from avto.jp, used to dedupe re-syncs' AFTER `slug`,
  ADD UNIQUE KEY `vehicle_brands_code_unique` (`code`);

ALTER TABLE `vehicle_models`
  ADD COLUMN `code` varchar(255) DEFAULT NULL COMMENT 'Raw synced MODEL_NAME value from avto.jp, used to dedupe re-syncs' AFTER `slug`,
  ADD UNIQUE KEY `vehicle_models_brand_code_unique` (`vehicle_brand_id`, `code`);

ALTER TABLE `vehicle_grades`
  ADD COLUMN `code` varchar(255) DEFAULT NULL COMMENT 'Raw synced GRADE value from avto.jp, used to dedupe re-syncs' AFTER `slug`,
  ADD UNIQUE KEY `vehicle_grades_model_code_unique` (`vehicle_model_id`, `code`);

ALTER TABLE `vehicle_drives`
  ADD COLUMN `code` varchar(255) DEFAULT NULL COMMENT 'Raw synced PRIV value from avto.jp, used to dedupe re-syncs' AFTER `slug`,
  ADD UNIQUE KEY `vehicle_drives_code_unique` (`code`);
