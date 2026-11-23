-- =============================================================================
-- One proforma invoice for one or more vehicles of an order, and the order's
-- consignee ("ordered on behalf of"). Goes with admin-api refactor/invoice-gen.
--
-- Until now an invoice belonged to exactly one vehicle (V98): proforma_invoices
-- carried that vehicle's line (case_vehicle_id, description, chassis_number,
-- year_of_manufacture, hs_code) and uq_case_vehicle_pi allowed one invoice per
-- vehicle. Now:
--   - proforma_invoices is the invoice header, numbered within the order by
--     invoice_index (the -2, -3 suffix of the invoice number);
--   - proforma_invoice_vehicles holds one line per vehicle;
--   - proforma_invoice_version_vehicles keeps the lines each version printed;
--   - each version is ACTIVE or INACTIVE;
--   - each invoice and version records its currency, terms of delivery and the
--     applicant's tax ID and email (the layout comes from admin-api's
--     invoice-profiles.json, by the order's country).
--
-- Existing invoices become single-vehicle invoices: same number, same PDFs,
-- one line copied from their old columns, the current version ACTIVE and the
-- older ones INACTIVE.
--
-- The old single-vehicle columns are made nullable rather than dropped. admin-api
-- no longer writes them (an INSERT failed on "case_vehicle_id doesn't have a
-- default value"), but existing rows keep what they printed, and the previous
-- admin-api build can still read them if it has to be rolled back. A later
-- migration can drop them.
--
-- Written defensively like V94/V99/V100 (admin-api runs with ddl-auto=update, so
-- Hibernate may already have added some of this), in plain MySQL 8.0 syntax:
-- no ADD COLUMN IF NOT EXISTS, no temporary tables. Safe to run twice.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. proforma_invoices: the single-vehicle columns become optional
-- -----------------------------------------------------------------------------

-- Same type and collation, only NULL allowed (the referenced column types are
-- read from the schema, so this works whatever created the table).
SET @sql = (SELECT CONCAT('ALTER TABLE proforma_invoices ', GROUP_CONCAT(
        CONCAT('MODIFY COLUMN `', column_name, '` ', column_type,
               IF(collation_name IS NULL, '', CONCAT(' COLLATE ', collation_name)), ' NULL')
        SEPARATOR ', '))
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices'
      AND column_name IN ('case_vehicle_id', 'description', 'chassis_number') AND is_nullable = 'NO');
SET @sql = IFNULL(@sql, 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- One invoice per vehicle no longer holds.
SET @sql = IF((SELECT COUNT(*) FROM information_schema.statistics
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND index_name = 'uq_case_vehicle_pi') > 0,
    'ALTER TABLE proforma_invoices DROP INDEX uq_case_vehicle_pi',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- -----------------------------------------------------------------------------
-- 2. proforma_invoices.invoice_index: 1 for an order's first invoice, 2, 3 ...
-- -----------------------------------------------------------------------------

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND column_name = 'invoice_index') = 0,
    'ALTER TABLE proforma_invoices ADD COLUMN invoice_index INT NULL AFTER case_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Existing invoices are numbered per order in the order they were created. Rows
-- Hibernate already numbered keep their index; the rest go after them.
UPDATE proforma_invoices p
JOIN (SELECT id, case_id,
             ROW_NUMBER() OVER (PARTITION BY case_id ORDER BY created_at, id) AS rn
      FROM proforma_invoices
      WHERE invoice_index IS NULL OR invoice_index < 1) unnumbered ON unnumbered.id = p.id
LEFT JOIN (SELECT case_id, MAX(invoice_index) AS max_index
           FROM proforma_invoices
           WHERE invoice_index >= 1
           GROUP BY case_id) numbered ON numbered.case_id = unnumbered.case_id
SET p.invoice_index = unnumbered.rn + COALESCE(numbered.max_index, 0);

ALTER TABLE proforma_invoices MODIFY COLUMN invoice_index INT NOT NULL DEFAULT 1;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.statistics
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND index_name = 'uq_case_invoice_index') = 0,
    'ALTER TABLE proforma_invoices ADD CONSTRAINT uq_case_invoice_index UNIQUE (case_id, invoice_index)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- -----------------------------------------------------------------------------
-- 3. proforma_invoice_versions: status, and the line columns become optional
-- -----------------------------------------------------------------------------

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions' AND column_name = 'status') = 0,
    'ALTER TABLE proforma_invoice_versions ADD COLUMN status VARCHAR(20) NULL AFTER version',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- The invoice's current version is the active one; earlier versions were replaced.
-- A blank status is what Hibernate leaves when it adds the column to existing rows.
UPDATE proforma_invoice_versions v
JOIN proforma_invoices p ON p.id = v.proforma_invoice_id
SET v.status = IF(v.version = p.current_version, 'ACTIVE', 'INACTIVE')
WHERE v.status IS NULL OR v.status = '';

ALTER TABLE proforma_invoice_versions MODIFY COLUMN status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';

SET @sql = (SELECT CONCAT('ALTER TABLE proforma_invoice_versions ', GROUP_CONCAT(
        CONCAT('MODIFY COLUMN `', column_name, '` ', column_type,
               IF(collation_name IS NULL, '', CONCAT(' COLLATE ', collation_name)), ' NULL')
        SEPARATOR ', '))
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions'
      AND column_name IN ('description', 'chassis_number') AND is_nullable = 'NO');
SET @sql = IFNULL(@sql, 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- -----------------------------------------------------------------------------
-- 4. The vehicle lines: what each invoice covers, and what each version printed
-- -----------------------------------------------------------------------------

-- Foreign-key columns copy the referenced id column exactly (case_vehicles.id is
-- CHAR(36), the invoice ids VARCHAR(36)), since a type or collation mismatch
-- would make the constraint fail.
SET @pi_id_type = (SELECT CONCAT(column_type, IF(collation_name IS NULL, '',
        CONCAT(' CHARACTER SET ', character_set_name, ' COLLATE ', collation_name)))
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND column_name = 'id');
SET @piv_id_type = (SELECT CONCAT(column_type, IF(collation_name IS NULL, '',
        CONCAT(' CHARACTER SET ', character_set_name, ' COLLATE ', collation_name)))
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions' AND column_name = 'id');
SET @cv_id_type = (SELECT CONCAT(column_type, IF(collation_name IS NULL, '',
        CONCAT(' CHARACTER SET ', character_set_name, ' COLLATE ', collation_name)))
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'case_vehicles' AND column_name = 'id');

-- vehicle_position is the line's position on the invoice (1, 2, ...), not the
-- vehicle's position in the order.
SET @sql = CONCAT('CREATE TABLE IF NOT EXISTS proforma_invoice_vehicles (',
    'id VARCHAR(36) NOT NULL PRIMARY KEY, ',
    'proforma_invoice_id ', @pi_id_type, ' NOT NULL, ',
    'case_vehicle_id ', @cv_id_type, ' NOT NULL, ',
    'vehicle_position INT NOT NULL, ',
    'description TEXT NOT NULL, ',
    'chassis_number VARCHAR(100) NOT NULL, ',
    'year_of_manufacture INT NULL, ',
    'hs_code VARCHAR(50) NULL, ',
    'fob_amount DECIMAL(15, 2) NOT NULL, ',
    'freight_amount DECIMAL(15, 2) NOT NULL, ',
    'line_total DECIMAL(15, 2) NOT NULL, ',
    'created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), ',
    'updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6), ',
    'INDEX idx_piv_pi_cv (proforma_invoice_id, case_vehicle_id), ',
    'INDEX idx_piv_cv (case_vehicle_id), ',
    'CONSTRAINT fk_pi_vehicles_invoice FOREIGN KEY (proforma_invoice_id) ',
        'REFERENCES proforma_invoices(id) ON DELETE CASCADE, ',
    'CONSTRAINT fk_pi_vehicles_case_vehicle FOREIGN KEY (case_vehicle_id) ',
        'REFERENCES case_vehicles(id) ON DELETE CASCADE)');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = CONCAT('CREATE TABLE IF NOT EXISTS proforma_invoice_version_vehicles (',
    'id VARCHAR(36) NOT NULL PRIMARY KEY, ',
    'proforma_invoice_version_id ', @piv_id_type, ' NOT NULL, ',
    'case_vehicle_id ', @cv_id_type, ' NOT NULL, ',
    'vehicle_position INT NOT NULL, ',
    'description TEXT NOT NULL, ',
    'chassis_number VARCHAR(100) NOT NULL, ',
    'year_of_manufacture INT NULL, ',
    'hs_code VARCHAR(50) NULL, ',
    'fob_amount DECIMAL(15, 2) NOT NULL, ',
    'freight_amount DECIMAL(15, 2) NOT NULL, ',
    'line_total DECIMAL(15, 2) NOT NULL, ',
    'created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), ',
    'INDEX idx_pivv_ver (proforma_invoice_version_id), ',
    'INDEX idx_pivv_cv (case_vehicle_id), ',
    'CONSTRAINT fk_pi_version_vehicles_version FOREIGN KEY (proforma_invoice_version_id) ',
        'REFERENCES proforma_invoice_versions(id) ON DELETE CASCADE, ',
    'CONSTRAINT fk_pi_version_vehicles_case_vehicle FOREIGN KEY (case_vehicle_id) ',
        'REFERENCES case_vehicles(id) ON DELETE CASCADE)');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Existing invoices: one line from the old columns. Only where the old columns
-- are there to copy from, the vehicle still exists, and the invoice has no lines
-- yet (so a second run, or rows the new admin-api already wrote, are left alone).
SET @has_legacy_lines = (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices'
      AND column_name IN ('case_vehicle_id', 'description', 'chassis_number', 'year_of_manufacture', 'hs_code'));

SET @sql = IF(@has_legacy_lines = 5,
    'INSERT INTO proforma_invoice_vehicles
         (id, proforma_invoice_id, case_vehicle_id, vehicle_position, description, chassis_number,
          year_of_manufacture, hs_code, fob_amount, freight_amount, line_total, created_at, updated_at)
     SELECT UUID(), p.id, cv.id, 1, COALESCE(p.description, ''''), COALESCE(p.chassis_number, ''''),
            p.year_of_manufacture, p.hs_code, p.fob_amount, p.freight_amount, p.total_amount,
            p.created_at, p.updated_at
     FROM proforma_invoices p
     JOIN case_vehicles cv ON cv.id = p.case_vehicle_id
     WHERE NOT EXISTS (SELECT 1 FROM proforma_invoice_vehicles l WHERE l.proforma_invoice_id = p.id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Each existing version: the line it printed, from its own snapshot columns.
SET @has_legacy_version_lines = (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions'
      AND column_name IN ('description', 'chassis_number', 'year_of_manufacture', 'hs_code'));

SET @sql = IF(@has_legacy_lines = 5 AND @has_legacy_version_lines = 4,
    'INSERT INTO proforma_invoice_version_vehicles
         (id, proforma_invoice_version_id, case_vehicle_id, vehicle_position, description, chassis_number,
          year_of_manufacture, hs_code, fob_amount, freight_amount, line_total, created_at)
     SELECT UUID(), v.id, cv.id, 1, COALESCE(v.description, ''''), COALESCE(v.chassis_number, ''''),
            v.year_of_manufacture, v.hs_code, v.fob_amount, v.freight_amount, v.total_amount, v.created_at
     FROM proforma_invoice_versions v
     JOIN proforma_invoices p ON p.id = v.proforma_invoice_id
     JOIN case_vehicles cv ON cv.id = p.case_vehicle_id
     WHERE NOT EXISTS (SELECT 1 FROM proforma_invoice_version_vehicles l WHERE l.proforma_invoice_version_id = v.id)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- -----------------------------------------------------------------------------
-- 5. cases: the consignee, the final customer a dealership orders for
-- -----------------------------------------------------------------------------
-- All optional; an order has at most one. The tax ID is the consignee's tax
-- number where the invoice prints one (NPWP in Indonesia). Added at the end of
-- the table, which MySQL 8 does in place. Columns Hibernate already added keep
-- their definition (the same as here).

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'cases' AND column_name = 'consignee_name') = 0,
    'ALTER TABLE cases ADD COLUMN consignee_name VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'cases' AND column_name = 'consignee_address') = 0,
    'ALTER TABLE cases ADD COLUMN consignee_address TEXT NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'cases' AND column_name = 'consignee_phone') = 0,
    'ALTER TABLE cases ADD COLUMN consignee_phone VARCHAR(50) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'cases' AND column_name = 'consignee_tax_id') = 0,
    'ALTER TABLE cases ADD COLUMN consignee_tax_id VARCHAR(50) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'cases' AND column_name = 'consignee_email') = 0,
    'ALTER TABLE cases ADD COLUMN consignee_email VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- -----------------------------------------------------------------------------
-- 6. How each invoice was issued: currency, terms of delivery, and the applicant's
--    tax ID and email (invoice-profiles.json in admin-api decides the layout by
--    country; these are what staff chose for the invoice, kept per version so a
--    version always matches the PDF it printed)
-- -----------------------------------------------------------------------------
-- Existing invoices were all issued in JPY on CFR terms (the only layout there
-- was). A blank value is what Hibernate leaves when it adds a NOT NULL column to
-- existing rows; those get the same defaults.

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND column_name = 'currency') = 0,
    'ALTER TABLE proforma_invoices ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT ''JPY'' AFTER transhipment_allowed',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND column_name = 'delivery_terms') = 0,
    'ALTER TABLE proforma_invoices ADD COLUMN delivery_terms VARCHAR(10) NOT NULL DEFAULT ''CFR'' AFTER currency',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND column_name = 'applicant_tax_id') = 0,
    'ALTER TABLE proforma_invoices ADD COLUMN applicant_tax_id VARCHAR(50) NULL AFTER applicant_address',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND column_name = 'applicant_email') = 0,
    'ALTER TABLE proforma_invoices ADD COLUMN applicant_email VARCHAR(255) NULL AFTER applicant_tax_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE proforma_invoices SET currency = 'JPY' WHERE currency IS NULL OR currency = '';
UPDATE proforma_invoices SET delivery_terms = 'CFR' WHERE delivery_terms IS NULL OR delivery_terms = '';
ALTER TABLE proforma_invoices
    MODIFY COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'JPY',
    MODIFY COLUMN delivery_terms VARCHAR(10) NOT NULL DEFAULT 'CFR';

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions' AND column_name = 'currency') = 0,
    'ALTER TABLE proforma_invoice_versions ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT ''JPY'' AFTER transhipment_allowed',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions' AND column_name = 'delivery_terms') = 0,
    'ALTER TABLE proforma_invoice_versions ADD COLUMN delivery_terms VARCHAR(10) NOT NULL DEFAULT ''CFR'' AFTER currency',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions' AND column_name = 'applicant_tax_id') = 0,
    'ALTER TABLE proforma_invoice_versions ADD COLUMN applicant_tax_id VARCHAR(50) NULL AFTER applicant_address',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions' AND column_name = 'applicant_email') = 0,
    'ALTER TABLE proforma_invoice_versions ADD COLUMN applicant_email VARCHAR(255) NULL AFTER applicant_tax_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE proforma_invoice_versions SET currency = 'JPY' WHERE currency IS NULL OR currency = '';
UPDATE proforma_invoice_versions SET delivery_terms = 'CFR' WHERE delivery_terms IS NULL OR delivery_terms = '';
ALTER TABLE proforma_invoice_versions
    MODIFY COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'JPY',
    MODIFY COLUMN delivery_terms VARCHAR(10) NOT NULL DEFAULT 'CFR';
