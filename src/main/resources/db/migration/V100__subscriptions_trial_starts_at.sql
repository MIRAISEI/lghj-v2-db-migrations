-- =============================================================================
-- When a subscription's free trial started.
--
-- The 30-day trial now starts when the customer saves a card, not at
-- registration, and runs 30 days from that moment. public-api records the start
-- in subscriptions.trial_starts_at next to the existing trial_ends_at.
-- Nullable: paid subscriptions have no trial, and trials created before this
-- change didn't record a start.
--
-- Written defensively like V94/V99: public-api runs with ddl-auto=update, so
-- Hibernate may already have added the column. It's added only if missing;
-- otherwise it's brought to the same definition.
-- =============================================================================

SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'subscriptions' AND column_name = 'trial_starts_at');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE subscriptions ADD COLUMN trial_starts_at DATETIME(6) NULL AFTER quantity',
    'ALTER TABLE subscriptions MODIFY COLUMN trial_starts_at DATETIME(6) NULL');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
