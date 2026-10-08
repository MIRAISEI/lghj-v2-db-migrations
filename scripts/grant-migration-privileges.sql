-- =============================================================================
-- One-time database setup for migrations that create triggers (V88, which makes
-- case_audit_events append-only).
--
-- Run this ONCE per environment as a database administrator (root / the RDS
-- master user) BEFORE deploying db-migrations 1.15.0. It is deliberately not a
-- Flyway migration: a migration runs as the application user and can't grant
-- itself privileges. It's safe to run more than once.
--
-- Not needed where the application connects as root (local dev): root already
-- has every privilege.
--
-- Replace the placeholders:
--   lgh_system_v2   the schema (DB_DATABASE)
--   'lgh_app'@'%'   the user admin-api / public-api connect as (DB_USERNAME)
-- =============================================================================

-- 1. Let the application user create triggers, on this schema only
--    (least privilege: no global grant).
GRANT TRIGGER ON lgh_system_v2.* TO 'lgh_app'@'%';

-- 2. Only if binary logging is on (SELECT @@log_bin returns 1): MySQL then also
--    requires SUPER to create a trigger, unless log_bin_trust_function_creators
--    is enabled. Enable the setting rather than granting SUPER: SUPER would give
--    the application user server-wide administrative rights. The V88 triggers
--    only raise an error (SIGNAL), so they're safe for replication.
--
--    Self-managed MySQL 8+ (survives a restart):
SET PERSIST log_bin_trust_function_creators = 1;
--    AWS RDS / Aurora: SET PERSIST isn't allowed. Set
--    log_bin_trust_function_creators = 1 in the DB parameter group instead
--    (it's a dynamic parameter, so no reboot is needed), and skip the line above.

-- 3. Check.
SHOW GRANTS FOR 'lgh_app'@'%';
SELECT @@log_bin AS binary_logging, @@log_bin_trust_function_creators AS trust_creators;

-- Note: the application user can still DROP these triggers, because it also
-- runs migrations. For tamper evidence that holds up against that user, run
-- migrations as a separate user and remove TRIGGER from the runtime user.
-- That's a follow-up; confirm the retention and evidence requirements with
-- compliance counsel.
