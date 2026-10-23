-- =============================================================================
-- Homepage brand strip.
--
-- The public homepage shows a horizontally scrolling strip of brand logos.
-- Staff choose which brands appear from the catalog's Brands page; the strip
-- only lists active, non-deleted brands that have a logo and this flag on.
--
-- Starting set: Toyota, Nissan, Honda, Mazda, Subaru, Lexus, Mercedes-Benz,
-- BMW, Lamborghini and Ferrari. Names differ by environment ("Toyota", "NISSAN",
-- "MERCEDES-BENZ"...), so they are matched on name or synced code, ignoring
-- case, hyphens and dots. admin-api fills in emblems for these makes when a
-- brand has none (BrandLogoSeeder); staff can replace or untick them later.
-- =============================================================================

ALTER TABLE `vehicle_brands`
  ADD COLUMN `show_on_home` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1: logo shown in the public homepage brand strip' AFTER `status`;

UPDATE `vehicle_brands`
SET `show_on_home` = 1
WHERE `deleted_at` IS NULL
  AND (
    UPPER(TRIM(REPLACE(REPLACE(`name`, '-', ' '), '.', ''))) IN
      ('TOYOTA', 'NISSAN', 'HONDA', 'MAZDA', 'SUBARU', 'LEXUS',
       'MERCEDES BENZ', 'MERCEDES', 'BMW', 'LAMBORGHINI', 'FERRARI')
    OR UPPER(TRIM(REPLACE(REPLACE(IFNULL(`code`, ''), '-', ' '), '.', ''))) IN
      ('TOYOTA', 'NISSAN', 'HONDA', 'MAZDA', 'SUBARU', 'LEXUS',
       'MERCEDES BENZ', 'MERCEDES', 'BMW', 'LAMBORGHINI', 'FERRARI')
  );
