-- =============================================================================
-- Multi-country exchange rates + per-order (case) exchange rates.
--
--   exchange_rates       Global Settings: rate vs JPY per country. Append-only —
--                        every create/edit inserts a new row; the newest row per
--                        country is the active rate, older rows are its history.
--   case_exchange_rates  Rate applied to one order, per payment stage (target).
--                        Also append-only: the newest row per (case_id, target)
--                        is the current rate, all rows are its audit trail. This
--                        is the single source of truth — cases carries no copy.
--   permissions          EXCHANGE_RATE_READ / _WRITE / _DELETE.
--
-- Both rate tables record who set each row (created_by_user_id / set_by_user_id)
-- so a rate used in a payment calculation can always be traced to a person.
--
-- Written defensively for exchange_rates (CREATE TABLE IF NOT EXISTS +
-- information_schema-guarded ALTERs, same approach as V58): local dev runs with
-- hibernate.ddl-auto=update, which already created that table from the JPA
-- entity on some machines before this migration existed. MySQL's ALTER TABLE
-- has no IF NOT EXISTS for ADD COLUMN / ADD INDEX / ADD CONSTRAINT, hence the
-- prepared statements.
--
-- Branch-local leftovers: an earlier, never-merged version of this feature let
-- Hibernate create `system_settings`, `case_exchange_rate_history` and nine
-- `cases.*exchange_rate*` columns on some local dev DBs. Nothing reads them any
-- more and no shared environment has them, so this migration leaves them alone;
-- drop them by hand locally if present.
-- =============================================================================

-- ── exchange_rates ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS exchange_rates (
    id                 BIGINT        NOT NULL AUTO_INCREMENT,
    country            VARCHAR(100)  NOT NULL COMMENT 'Country name as listed in the admin country picker',
    currency           VARCHAR(10)   NOT NULL COMMENT 'ISO 4217 code',
    rate               DECIMAL(15,4) NOT NULL COMMENT 'Units of currency per 1 JPY',
    expire_date        DATE          NULL,
    created_by_user_id CHAR(36)      NULL,
    created_at         DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Hibernate-created tables have a nullable created_at with no default; converge.
UPDATE exchange_rates SET created_at = CURRENT_TIMESTAMP(6) WHERE created_at IS NULL;
ALTER TABLE exchange_rates MODIFY COLUMN created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6);

SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'exchange_rates' AND column_name = 'created_by_user_id'
);
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE exchange_rates ADD COLUMN created_by_user_id CHAR(36) NULL AFTER expire_date',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- "Latest rate per country" + per-country history lookups.
SET @idx_exists = (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'exchange_rates' AND index_name = 'idx_exchange_rates_country_created'
);
SET @sql = IF(@idx_exists = 0,
    'ALTER TABLE exchange_rates ADD INDEX idx_exchange_rates_country_created (country, created_at)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_exists = (
    SELECT COUNT(*) FROM information_schema.table_constraints
    WHERE table_schema = DATABASE() AND table_name = 'exchange_rates' AND constraint_name = 'fk_exchange_rates_created_by'
);
SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE exchange_rates ADD CONSTRAINT fk_exchange_rates_created_by FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ── case_exchange_rates ────────────────────────────────────────────────────
-- New in this migration on every environment, so declared in full.
CREATE TABLE IF NOT EXISTS case_exchange_rates (
    id             CHAR(36)                   NOT NULL,
    case_id        CHAR(36)                   NOT NULL,
    target         ENUM('ADVANCE', 'BALANCE') NOT NULL COMMENT 'Payment stage the rate converts',
    rate           DECIMAL(15,4)              NOT NULL COMMENT 'Units of currency per 1 JPY',
    currency       VARCHAR(10)                NOT NULL COMMENT 'ISO 4217 code',
    expire_date    DATE                       NULL,
    set_by_user_id CHAR(36)                   NULL,
    created_at     DATETIME(6)                NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_case_exchange_rates_case_target_created (case_id, target, created_at),
    CONSTRAINT fk_case_exchange_rates_case FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    CONSTRAINT fk_case_exchange_rates_set_by FOREIGN KEY (set_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── permissions ────────────────────────────────────────────────────────────
-- Previously gated by role name: reads by ADMIN/BIDDING/SHIPPING/SALES, writes
-- by ADMIN/BIDDING. Seeded so those roles keep exactly that access; FINANCE also
-- gets read access since it works with the converted payment amounts.
INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'EXCHANGE_RATE_READ'),
    (UUID(), 'EXCHANGE_RATE_WRITE'),
    (UUID(), 'EXCHANGE_RATE_DELETE');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('EXCHANGE_RATE_READ', 'EXCHANGE_RATE_WRITE')
WHERE r.name = 'BIDDING';

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'EXCHANGE_RATE_READ'
WHERE r.name IN ('SALES', 'SHIPPING', 'FINANCE');
