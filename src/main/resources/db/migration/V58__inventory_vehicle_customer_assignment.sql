-- Customer assignment for inventory vehicles.
-- Vehicles promoted from a bidding request (source_case_id IS NOT NULL) are
-- auto-assigned to the case's customer and that assignment is locked;
-- manually-created inventory vehicles can be assigned/reassigned by staff.
--
-- Written defensively (guarded dynamic ADD COLUMN / ADD INDEX / ADD CONSTRAINT)
-- because local dev runs with hibernate.ddl-auto=update, which has already
-- created these columns from the JPA entity on some environments before this
-- migration ever got a chance to run there -- a plain ADD COLUMN fails with
-- "Duplicate column name" in that case. MySQL's ALTER TABLE grammar has no
-- `IF NOT EXISTS` clause for ADD COLUMN, ADD INDEX, or ADD CONSTRAINT (that's
-- a MariaDB-only extension) -- an earlier version of this migration used it
-- and failed with a syntax error on real MySQL 8.0. Hence the
-- information_schema-guarded prepared statements throughout.

SET @col_customer_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND column_name = 'assigned_customer_id'
);
SET @sql = IF(@col_customer_exists = 0,
    'ALTER TABLE inventory_vehicles ADD COLUMN assigned_customer_id CHAR(36) NULL COMMENT ''Customer assigned to this vehicle''',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_admin_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND column_name = 'assigned_by_admin_id'
);
SET @sql = IF(@col_admin_exists = 0,
    'ALTER TABLE inventory_vehicles ADD COLUMN assigned_by_admin_id CHAR(36) NULL COMMENT ''Admin who manually assigned the customer; NULL when auto-assigned from a bidding request''',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_at_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND column_name = 'assigned_at'
);
SET @sql = IF(@col_at_exists = 0,
    'ALTER TABLE inventory_vehicles ADD COLUMN assigned_at DATETIME(6) NULL COMMENT ''When the customer was assigned''',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND index_name = 'idx_inv_assigned_customer_id'
);
SET @sql = IF(@idx_exists = 0,
    'ALTER TABLE inventory_vehicles ADD INDEX idx_inv_assigned_customer_id (assigned_customer_id)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_customer_exists = (
    SELECT COUNT(*) FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND constraint_name = 'fk_inv_assigned_customer'
);
SET @sql = IF(@fk_customer_exists = 0,
    'ALTER TABLE inventory_vehicles ADD CONSTRAINT fk_inv_assigned_customer FOREIGN KEY (assigned_customer_id) REFERENCES users(id) ON DELETE SET NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_admin_exists = (
    SELECT COUNT(*) FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'inventory_vehicles' AND constraint_name = 'fk_inv_assigned_by_admin'
);
SET @sql = IF(@fk_admin_exists = 0,
    'ALTER TABLE inventory_vehicles ADD CONSTRAINT fk_inv_assigned_by_admin FOREIGN KEY (assigned_by_admin_id) REFERENCES users(id) ON DELETE SET NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
