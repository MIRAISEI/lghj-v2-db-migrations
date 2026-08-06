-- V55: Free brand of the week (home hero auction vehicles) + free-brand permissions

CREATE TABLE IF NOT EXISTS `free_brands` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `vehicle_brand_id` bigint unsigned NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `free_brands_vehicle_brand_id_foreign` (`vehicle_brand_id`),
  CONSTRAINT `free_brands_vehicle_brand_id_foreign` FOREIGN KEY (`vehicle_brand_id`) REFERENCES `vehicle_brands` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `free_auction_vehicles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `free_brand_id` bigint unsigned DEFAULT NULL,
  `vehicle_id` varchar(255) DEFAULT NULL,
  `thumbnail_url` varchar(255) DEFAULT NULL,
  `brand` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `auction_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `free_auction_vehicles_free_brand_id_foreign` (`free_brand_id`),
  CONSTRAINT `free_auction_vehicles_free_brand_id_foreign` FOREIGN KEY (`free_brand_id`) REFERENCES `free_brands` (`id`) ON DELETE CASCADE
);

-- Free brand management permissions
INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'FREE_BRAND_READ'),
    (UUID(), 'FREE_BRAND_WRITE'),
    (UUID(), 'FREE_BRAND_DELETE');

-- ADMIN role gets every permission
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';
