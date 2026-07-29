-- V51: Blog articles (blog_articles, blog_tags, blog_article_tags) + article permissions

CREATE TABLE IF NOT EXISTS `blog_articles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `introduction` text,
  `description` longtext,
  `slug` varchar(255) NOT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: published, 0: draft',
  `image` varchar(255) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `blog_articles_slug_unique` (`slug`)
);

CREATE TABLE IF NOT EXISTS `blog_tags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1: active, 0: draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `blog_tags_slug_unique` (`slug`)
);

CREATE TABLE IF NOT EXISTS `blog_article_tags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `article_id` bigint unsigned NOT NULL,
  `art_tag_id` bigint unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `blog_article_tags_article_id_art_tag_id_unique` (`article_id`, `art_tag_id`),
  KEY `blog_article_tags_art_tag_id_foreign` (`art_tag_id`),
  CONSTRAINT `blog_article_tags_article_id_foreign` FOREIGN KEY (`article_id`) REFERENCES `blog_articles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `blog_article_tags_art_tag_id_foreign` FOREIGN KEY (`art_tag_id`) REFERENCES `blog_tags` (`id`) ON DELETE CASCADE
);

-- Article permissions
INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'ARTICLE_READ'),
    (UUID(), 'ARTICLE_WRITE'),
    (UUID(), 'ARTICLE_DELETE');

-- ADMIN role gets every permission
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';
