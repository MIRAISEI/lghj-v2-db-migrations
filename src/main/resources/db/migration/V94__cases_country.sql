-- =============================================================================
-- Order destination country (cases.country, cases.country_overridden).
--
--   cases.country             VARCHAR(255) NULL
--                             Destination country of the order (drives the LC / TT
--                             labels); NULL falls back to the customer's country.
--   cases.country_overridden  BIT(1) NOT NULL DEFAULT b'0'
--                             1 when staff set the country by hand, 0 when it
--                             follows the customer.
--
-- The admin API added both fields to its Case entity without a migration, so
-- they were created by Hibernate (ddl-auto=update) as country_overridden
-- BIT(1) NOT NULL with no default. The public API inserts orders without that
-- column, which MySQL rejects ("Field 'country_overridden' doesn't have a
-- default value") and the API returns as 409 when a customer starts a bid.
--
-- Written defensively like V58: MySQL has no ADD COLUMN IF NOT EXISTS, so each
-- step is an information_schema-guarded prepared statement. It adds whichever
-- column is missing, and gives an existing country_overridden its default.
-- =============================================================================

-- 1. Add `country` column if not present
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'cases' AND column_name = 'country'
);
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE cases ADD COLUMN country VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Backfill NULLs for existing `country_overridden` if column already exists
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'cases' AND column_name = 'country_overridden'
);
SET @sql = IF(@col_exists > 0,
    'UPDATE cases SET country_overridden = b''0'' WHERE country_overridden IS NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. Add `country_overridden` column if absent, or modify it to ensure NOT NULL DEFAULT b'0'
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'cases' AND column_name = 'country_overridden'
);
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE cases ADD COLUMN country_overridden BIT(1) NOT NULL DEFAULT b''0''',
    'ALTER TABLE cases MODIFY COLUMN country_overridden BIT(1) NOT NULL DEFAULT b''0''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
