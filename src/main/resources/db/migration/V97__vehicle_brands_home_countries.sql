-- =============================================================================
-- Countries for the homepage brand strip's starting makes.
--
-- The strip splits its logos into a "Japanese Brands" row and an "Other Country
-- Brands" row by vehicle_brands.country. The ten makes V96 flagged have no
-- country yet, so set it here. Names match the admin country picker (Japan,
-- Germany, Italy), and brands are matched on name or synced code ignoring case,
-- hyphens and dots, as in V96. A country staff already entered is left alone.
-- =============================================================================

UPDATE `vehicle_brands`
SET `country` = CASE
    WHEN UPPER(TRIM(REPLACE(REPLACE(`name`, '-', ' '), '.', ''))) IN ('MERCEDES BENZ', 'MERCEDES', 'BMW')
      OR UPPER(TRIM(REPLACE(REPLACE(IFNULL(`code`, ''), '-', ' '), '.', ''))) IN ('MERCEDES BENZ', 'MERCEDES', 'BMW')
      THEN 'Germany'
    WHEN UPPER(TRIM(REPLACE(REPLACE(`name`, '-', ' '), '.', ''))) IN ('LAMBORGHINI', 'FERRARI')
      OR UPPER(TRIM(REPLACE(REPLACE(IFNULL(`code`, ''), '-', ' '), '.', ''))) IN ('LAMBORGHINI', 'FERRARI')
      THEN 'Italy'
    ELSE 'Japan'
  END
WHERE `deleted_at` IS NULL
  AND (`country` IS NULL OR TRIM(`country`) = '')
  AND (
    UPPER(TRIM(REPLACE(REPLACE(`name`, '-', ' '), '.', ''))) IN
      ('TOYOTA', 'NISSAN', 'HONDA', 'MAZDA', 'SUBARU', 'LEXUS',
       'MERCEDES BENZ', 'MERCEDES', 'BMW', 'LAMBORGHINI', 'FERRARI')
    OR UPPER(TRIM(REPLACE(REPLACE(IFNULL(`code`, ''), '-', ' '), '.', ''))) IN
      ('TOYOTA', 'NISSAN', 'HONDA', 'MAZDA', 'SUBARU', 'LEXUS',
       'MERCEDES BENZ', 'MERCEDES', 'BMW', 'LAMBORGHINI', 'FERRARI')
  );
