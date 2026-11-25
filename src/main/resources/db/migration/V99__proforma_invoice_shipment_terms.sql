-- =============================================================================
-- Partial shipment and transhipment chosen per proforma invoice.
--
-- The L/C terms on a proforma printed "Partial shipment: NOT ALLOWED" and
-- "Transhipment: ALLOWED" for every order. Staff now choose each per invoice, so
-- both are stored on the invoice and on each version (the PDF a version printed).
-- Existing invoices keep what they printed: partial shipment not allowed,
-- transhipment allowed.
--
-- Written defensively like V94: admin-api runs with ddl-auto=update, so Hibernate
-- may already have added a column (nullable, without the default). Each column is
-- added if missing; otherwise its NULLs are filled and it gets the default.
-- =============================================================================

-- proforma_invoices.partial_shipment_allowed
SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND column_name = 'partial_shipment_allowed');
SET @sql = IF(@col_exists > 0, 'UPDATE proforma_invoices SET partial_shipment_allowed = b''0'' WHERE partial_shipment_allowed IS NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE proforma_invoices ADD COLUMN partial_shipment_allowed BIT(1) NOT NULL DEFAULT b''0''',
    'ALTER TABLE proforma_invoices MODIFY COLUMN partial_shipment_allowed BIT(1) NOT NULL DEFAULT b''0''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- proforma_invoices.transhipment_allowed
SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoices' AND column_name = 'transhipment_allowed');
SET @sql = IF(@col_exists > 0, 'UPDATE proforma_invoices SET transhipment_allowed = b''1'' WHERE transhipment_allowed IS NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE proforma_invoices ADD COLUMN transhipment_allowed BIT(1) NOT NULL DEFAULT b''1''',
    'ALTER TABLE proforma_invoices MODIFY COLUMN transhipment_allowed BIT(1) NOT NULL DEFAULT b''1''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- proforma_invoice_versions.partial_shipment_allowed
SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions' AND column_name = 'partial_shipment_allowed');
SET @sql = IF(@col_exists > 0, 'UPDATE proforma_invoice_versions SET partial_shipment_allowed = b''0'' WHERE partial_shipment_allowed IS NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE proforma_invoice_versions ADD COLUMN partial_shipment_allowed BIT(1) NOT NULL DEFAULT b''0''',
    'ALTER TABLE proforma_invoice_versions MODIFY COLUMN partial_shipment_allowed BIT(1) NOT NULL DEFAULT b''0''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- proforma_invoice_versions.transhipment_allowed
SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'proforma_invoice_versions' AND column_name = 'transhipment_allowed');
SET @sql = IF(@col_exists > 0, 'UPDATE proforma_invoice_versions SET transhipment_allowed = b''1'' WHERE transhipment_allowed IS NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE proforma_invoice_versions ADD COLUMN transhipment_allowed BIT(1) NOT NULL DEFAULT b''1''',
    'ALTER TABLE proforma_invoice_versions MODIFY COLUMN transhipment_allowed BIT(1) NOT NULL DEFAULT b''1''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
