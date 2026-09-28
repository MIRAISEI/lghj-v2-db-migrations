-- V54: Team management (departments, designations, team_members) + team permissions

CREATE TABLE IF NOT EXISTS `departments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  `sort_order` int NOT NULL DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `designations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(150) NOT NULL,
  `department_id` bigint unsigned DEFAULT NULL,
  `reports_to_id` bigint unsigned DEFAULT NULL,
  `sort_order` int NOT NULL DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `designations_department_id_foreign` (`department_id`),
  KEY `designations_reports_to_id_foreign` (`reports_to_id`),
  CONSTRAINT `designations_department_id_foreign` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `designations_reports_to_id_foreign` FOREIGN KEY (`reports_to_id`) REFERENCES `designations` (`id`) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS `team_members` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `designation_id` bigint unsigned NOT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `connect_label` varchar(150) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `team_members_designation_id_foreign` (`designation_id`),
  CONSTRAINT `team_members_designation_id_foreign` FOREIGN KEY (`designation_id`) REFERENCES `designations` (`id`)
);

-- Team management permissions
INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'TEAM_READ'),
    (UUID(), 'TEAM_WRITE'),
    (UUID(), 'TEAM_DELETE');

-- ADMIN role gets every permission
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';
