-- =============================================================================
-- V101: Per-user notification preferences.
--
-- One row per (user, category, channel) the user has explicitly saved. A
-- missing row means "enabled", so everyone keeps receiving every notification
-- until they turn something off; nothing is seeded.
--
--   category  what the notification is about. Values are the NotificationCategory
--             enum, kept in sync between admin-api and public-api:
--             ORDER_UPDATES, PAYMENTS, MESSAGES, INSPECTIONS, CHANGE_REQUESTS,
--             VEHICLE_PURCHASED. Stored as text so a new category needs no
--             migration.
--   channel   EMAIL or IN_APP.
--
-- Account and security emails (password reset, two-factor codes, welcome /
-- account created) are never governed by this table.
--
-- Written with IF NOT EXISTS: admin-api and public-api run with
-- ddl-auto=update, so Hibernate may already have created the table.
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id          CHAR(36)    NOT NULL,
    user_id     CHAR(36)    NOT NULL,
    category    VARCHAR(32) NOT NULL,
    channel     VARCHAR(16) NOT NULL,
    enabled     BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_user_notification_preferences (user_id, category, channel),
    CONSTRAINT fk_user_notification_preferences_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);
