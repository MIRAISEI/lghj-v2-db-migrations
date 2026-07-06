-- V32: Vehicle catalog tables for colors, transmissions, fuel types, body styles, features and tags

CREATE TABLE IF NOT EXISTS `vehicle_colors` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT 'Raw synced value from avto.jp, used to dedupe re-syncs',
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_colors_slug_unique` (`slug`),
  UNIQUE KEY `vehicle_colors_code_unique` (`code`)
);

CREATE TABLE IF NOT EXISTS `vehicle_transmissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT 'Raw synced KPP value from avto.jp, used to dedupe re-syncs',
  `style` varchar(50) DEFAULT NULL COMMENT 'CVT | AM | MT | AT',
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_transmissions_slug_unique` (`slug`),
  UNIQUE KEY `vehicle_transmissions_code_unique` (`code`)
);

CREATE TABLE IF NOT EXISTS `vehicle_fuel_types` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_fuel_types_slug_unique` (`slug`)
);

CREATE TABLE IF NOT EXISTS `vehicle_body_styles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_body_styles_slug_unique` (`slug`)
);

CREATE TABLE IF NOT EXISTS `vehicle_features` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_features_slug_unique` (`slug`)
);

CREATE TABLE IF NOT EXISTS `vehicle_tags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_tags_slug_unique` (`slug`)
);
