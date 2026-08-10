-- V57: Testimonial management (customer testimonials shown on the public home page) + testimonial permissions

CREATE TABLE IF NOT EXISTS `testimonials` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `author` varchar(150) NOT NULL,
  `location` varchar(150) DEFAULT NULL,
  `quote` text NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `sort_order` int NOT NULL DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- Testimonial management permissions
INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'TESTIMONIAL_READ'),
    (UUID(), 'TESTIMONIAL_WRITE'),
    (UUID(), 'TESTIMONIAL_DELETE');

-- ADMIN role gets every permission
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';
