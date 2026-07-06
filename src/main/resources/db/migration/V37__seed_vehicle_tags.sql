-- V37: Replace the vehicle_tags catalog with the canonical tag list.
-- NOTE: this deletes all existing vehicle_tags rows first. Because
-- inventory_vehicle_tags.tag_id has ON DELETE CASCADE back to
-- vehicle_tags(id) (see V33), any inventory-to-tag associations created
-- against the old rows are removed along with them.

DELETE FROM vehicle_tags;

INSERT INTO vehicle_tags (name, slug, image, status, created_at, updated_at) VALUES
    ('Recent Added', 'recent-added', NULL, 1, NOW(), NOW()),
    ('Most Visited', 'most-visited', NULL, 1, NOW(), NOW()),
    ('Best Selling', 'best-selling', NULL, 1, NOW(), NOW()),
    ('Premium', 'premium', NULL, 1, NOW(), NOW()),
    ('Cheapest', 'cheapest', NULL, 1, NOW(), NOW()),
    ('Featured', 'featured', NULL, 1, NOW(), NOW()),
    ('Machinery', 'machinery', NULL, 1, NOW(), NOW()),
    ('Machinery Parts', 'machinery-parts', NULL, 1, NOW(), NOW()),
    ('Accident', 'accident', NULL, 1, NOW(), NOW());
