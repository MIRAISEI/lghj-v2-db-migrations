-- Seed one user per role for development / QA
--
-- Email pattern : {role}@miraisei.com
-- Password      : Admin@123  → admin
--                 Test@1234  → all others
--
-- Role      | Email                    | Password
-- ----------|--------------------------|----------
-- ADMIN     | admin@miraisei.com       | Admin@123
-- BIDDING   | bidding@miraisei.com     | Test@1234
-- SALES     | sales@miraisei.com       | Test@1234
-- FINANCE   | finance@miraisei.com     | Test@1234
-- SHIPPING  | shipping@miraisei.com    | Test@1234
-- CUSTOMER  | customer@miraisei.com    | Test@1234
-- SUPPORT   | support@miraisei.com     | Test@1234

-- ── Helper macro: one block per user ─────────────────────────────────────────
-- Pattern repeated for each user:
--   1. INSERT user (idempotent)
--   2. Assign role
--   3. Insert first_name / last_name / avatar meta
--   4. Insert status history entry

-- ── ADMIN ────────────────────────────────────────────────────────────────────

INSERT INTO users (id, username, email, email_verified_at, password, status, created_at, updated_at)
SELECT UUID(), 'admin_miraisei', 'admin@miraisei.com', NOW(6),
       '$2y$10$9dB4PtToR1NCXpqy9VpUeeiwiSf0fJPRaANkWF7tP/eImJQLU9ur6',
       'ACTIVE', NOW(6), NOW(6)
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@miraisei.com');

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON r.name = 'ADMIN'
WHERE u.email = 'admin@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = u.id AND ur.role_id = r.id);

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'first_name', 'System', NOW(6), NOW(6) FROM users u
WHERE u.email = 'admin@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'first_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'last_name', 'Admin', NOW(6), NOW(6) FROM users u
WHERE u.email = 'admin@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'last_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'avatar', 'system-admin', NOW(6), NOW(6) FROM users u
WHERE u.email = 'admin@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'avatar');

INSERT INTO user_status_history (id, user_id, previous_status, new_status, reason, changed_at)
SELECT UUID(), u.id, NULL, 'ACTIVE', 'Flyway seed admin@miraisei.com', NOW(6) FROM users u
WHERE u.email = 'admin@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_status_history h WHERE h.user_id = u.id AND h.reason = 'Flyway seed admin@miraisei.com');

-- ── BIDDING ──────────────────────────────────────────────────────────────────

INSERT INTO users (id, username, email, email_verified_at, password, status, created_at, updated_at)
SELECT UUID(), 'bidding_miraisei', 'bidding@miraisei.com', NOW(6),
       '$2y$10$Uj/7MrUJPyYmTktb1LumUuvG1NBVSsG6dalvcsAxyFemO/TWqZN4y',
       'ACTIVE', NOW(6), NOW(6)
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'bidding@miraisei.com');

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON r.name = 'BIDDING'
WHERE u.email = 'bidding@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = u.id AND ur.role_id = r.id);

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'first_name', 'Bidding', NOW(6), NOW(6) FROM users u
WHERE u.email = 'bidding@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'first_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'last_name', 'User', NOW(6), NOW(6) FROM users u
WHERE u.email = 'bidding@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'last_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'avatar', 'bidding-user', NOW(6), NOW(6) FROM users u
WHERE u.email = 'bidding@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'avatar');

INSERT INTO user_status_history (id, user_id, previous_status, new_status, reason, changed_at)
SELECT UUID(), u.id, NULL, 'ACTIVE', 'Flyway seed bidding@miraisei.com', NOW(6) FROM users u
WHERE u.email = 'bidding@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_status_history h WHERE h.user_id = u.id AND h.reason = 'Flyway seed bidding@miraisei.com');

-- ── SALES ────────────────────────────────────────────────────────────────────

INSERT INTO users (id, username, email, email_verified_at, password, status, created_at, updated_at)
SELECT UUID(), 'sales_miraisei', 'sales@miraisei.com', NOW(6),
       '$2y$10$Uj/7MrUJPyYmTktb1LumUuvG1NBVSsG6dalvcsAxyFemO/TWqZN4y',
       'ACTIVE', NOW(6), NOW(6)
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'sales@miraisei.com');

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON r.name = 'SALES'
WHERE u.email = 'sales@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = u.id AND ur.role_id = r.id);

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'first_name', 'Sales', NOW(6), NOW(6) FROM users u
WHERE u.email = 'sales@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'first_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'last_name', 'User', NOW(6), NOW(6) FROM users u
WHERE u.email = 'sales@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'last_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'avatar', 'sales-user', NOW(6), NOW(6) FROM users u
WHERE u.email = 'sales@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'avatar');

INSERT INTO user_status_history (id, user_id, previous_status, new_status, reason, changed_at)
SELECT UUID(), u.id, NULL, 'ACTIVE', 'Flyway seed sales@miraisei.com', NOW(6) FROM users u
WHERE u.email = 'sales@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_status_history h WHERE h.user_id = u.id AND h.reason = 'Flyway seed sales@miraisei.com');

-- ── FINANCE ──────────────────────────────────────────────────────────────────

INSERT INTO users (id, username, email, email_verified_at, password, status, created_at, updated_at)
SELECT UUID(), 'finance_miraisei', 'finance@miraisei.com', NOW(6),
       '$2y$10$Uj/7MrUJPyYmTktb1LumUuvG1NBVSsG6dalvcsAxyFemO/TWqZN4y',
       'ACTIVE', NOW(6), NOW(6)
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'finance@miraisei.com');

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON r.name = 'FINANCE'
WHERE u.email = 'finance@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = u.id AND ur.role_id = r.id);

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'first_name', 'Finance', NOW(6), NOW(6) FROM users u
WHERE u.email = 'finance@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'first_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'last_name', 'User', NOW(6), NOW(6) FROM users u
WHERE u.email = 'finance@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'last_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'avatar', 'finance-user', NOW(6), NOW(6) FROM users u
WHERE u.email = 'finance@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'avatar');

INSERT INTO user_status_history (id, user_id, previous_status, new_status, reason, changed_at)
SELECT UUID(), u.id, NULL, 'ACTIVE', 'Flyway seed finance@miraisei.com', NOW(6) FROM users u
WHERE u.email = 'finance@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_status_history h WHERE h.user_id = u.id AND h.reason = 'Flyway seed finance@miraisei.com');

-- ── SHIPPING ─────────────────────────────────────────────────────────────────

INSERT INTO users (id, username, email, email_verified_at, password, status, created_at, updated_at)
SELECT UUID(), 'shipping_miraisei', 'shipping@miraisei.com', NOW(6),
       '$2y$10$Uj/7MrUJPyYmTktb1LumUuvG1NBVSsG6dalvcsAxyFemO/TWqZN4y',
       'ACTIVE', NOW(6), NOW(6)
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'shipping@miraisei.com');

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON r.name = 'SHIPPING'
WHERE u.email = 'shipping@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = u.id AND ur.role_id = r.id);

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'first_name', 'Shipping', NOW(6), NOW(6) FROM users u
WHERE u.email = 'shipping@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'first_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'last_name', 'User', NOW(6), NOW(6) FROM users u
WHERE u.email = 'shipping@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'last_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'avatar', 'shipping-user', NOW(6), NOW(6) FROM users u
WHERE u.email = 'shipping@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'avatar');

INSERT INTO user_status_history (id, user_id, previous_status, new_status, reason, changed_at)
SELECT UUID(), u.id, NULL, 'ACTIVE', 'Flyway seed shipping@miraisei.com', NOW(6) FROM users u
WHERE u.email = 'shipping@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_status_history h WHERE h.user_id = u.id AND h.reason = 'Flyway seed shipping@miraisei.com');

-- ── CUSTOMER ─────────────────────────────────────────────────────────────────

INSERT INTO users (id, username, email, email_verified_at, password, status, created_at, updated_at)
SELECT UUID(), 'customer_miraisei', 'customer@miraisei.com', NOW(6),
       '$2y$10$Uj/7MrUJPyYmTktb1LumUuvG1NBVSsG6dalvcsAxyFemO/TWqZN4y',
       'ACTIVE', NOW(6), NOW(6)
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'customer@miraisei.com');

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON r.name = 'CUSTOMER'
WHERE u.email = 'customer@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = u.id AND ur.role_id = r.id);

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'first_name', 'Customer', NOW(6), NOW(6) FROM users u
WHERE u.email = 'customer@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'first_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'last_name', 'User', NOW(6), NOW(6) FROM users u
WHERE u.email = 'customer@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'last_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'avatar', 'customer-user', NOW(6), NOW(6) FROM users u
WHERE u.email = 'customer@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'avatar');

INSERT INTO user_status_history (id, user_id, previous_status, new_status, reason, changed_at)
SELECT UUID(), u.id, NULL, 'ACTIVE', 'Flyway seed customer@miraisei.com', NOW(6) FROM users u
WHERE u.email = 'customer@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_status_history h WHERE h.user_id = u.id AND h.reason = 'Flyway seed customer@miraisei.com');

-- ── SUPPORT ──────────────────────────────────────────────────────────────────

INSERT INTO users (id, username, email, email_verified_at, password, status, created_at, updated_at)
SELECT UUID(), 'support_miraisei', 'support@miraisei.com', NOW(6),
       '$2y$10$Uj/7MrUJPyYmTktb1LumUuvG1NBVSsG6dalvcsAxyFemO/TWqZN4y',
       'ACTIVE', NOW(6), NOW(6)
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'support@miraisei.com');

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON r.name = 'SUPPORT'
WHERE u.email = 'support@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id = u.id AND ur.role_id = r.id);

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'first_name', 'Support', NOW(6), NOW(6) FROM users u
WHERE u.email = 'support@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'first_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'last_name', 'User', NOW(6), NOW(6) FROM users u
WHERE u.email = 'support@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'last_name');

INSERT INTO users_meta (id, user_id, meta_key, meta_value, created_at, updated_at)
SELECT UUID(), u.id, 'avatar', 'support-user', NOW(6), NOW(6) FROM users u
WHERE u.email = 'support@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM users_meta um WHERE um.user_id = u.id AND um.meta_key = 'avatar');

INSERT INTO user_status_history (id, user_id, previous_status, new_status, reason, changed_at)
SELECT UUID(), u.id, NULL, 'ACTIVE', 'Flyway seed support@miraisei.com', NOW(6) FROM users u
WHERE u.email = 'support@miraisei.com'
  AND NOT EXISTS (SELECT 1 FROM user_status_history h WHERE h.user_id = u.id AND h.reason = 'Flyway seed support@miraisei.com');
