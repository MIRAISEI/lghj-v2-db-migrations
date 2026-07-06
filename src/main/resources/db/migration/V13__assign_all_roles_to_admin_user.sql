-- Ensure ADMIN has permissions when role_permissions is completely empty.
-- This runs only once for empty installations to avoid overriding existing mappings.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN'
  AND NOT EXISTS (
      SELECT 1
      FROM role_permissions
  )
  AND NOT EXISTS (
      SELECT 1
      FROM role_permissions rp
      WHERE rp.role_id = r.id
        AND rp.permission_id = p.id
  );

-- Assign every available role to seeded admin user.
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r
WHERE u.email = 'admin@miraisei.com'
  AND NOT EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = u.id
        AND ur.role_id = r.id
  );

-- Add is_locked column to roles table
ALTER TABLE roles ADD COLUMN is_locked BOOLEAN NOT NULL DEFAULT FALSE;

