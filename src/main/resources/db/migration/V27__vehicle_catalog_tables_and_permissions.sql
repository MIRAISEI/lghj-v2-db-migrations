-- V27: Vehicle catalog tables (brands, models, grades, drives) + catalog permissions

CREATE TABLE IF NOT EXISTS `vehicle_brands` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `introduction` text,
  `slug` varchar(255) NOT NULL,
  `logo` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_brands_slug_unique` (`slug`)
);

CREATE TABLE IF NOT EXISTS `vehicle_models` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `introduction` text,
  `slug` varchar(255) NOT NULL,
  `logo` varchar(255) DEFAULT NULL,
  `vehicle_brand_id` bigint unsigned DEFAULT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_models_slug_unique` (`slug`),
  KEY `vehicle_models_vehicle_brand_id_foreign` (`vehicle_brand_id`),
  CONSTRAINT `vehicle_models_vehicle_brand_id_foreign`
    FOREIGN KEY (`vehicle_brand_id`) REFERENCES `vehicle_brands` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `vehicle_grades` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `vehicle_model_id` bigint unsigned NOT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_grades_slug_unique` (`slug`),
  KEY `vehicle_grades_vehicle_model_id_foreign` (`vehicle_model_id`),
  CONSTRAINT `vehicle_grades_vehicle_model_id_foreign`
    FOREIGN KEY (`vehicle_model_id`) REFERENCES `vehicle_models` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `vehicle_drives` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_drives_slug_unique` (`slug`)
);

-- Catalog permissions
INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'CATALOG_READ'),
    (UUID(), 'CATALOG_WRITE'),
    (UUID(), 'CATALOG_DELETE'),
    (UUID(), 'CATALOG_SYNC');

-- ADMIN role gets every permission
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';
