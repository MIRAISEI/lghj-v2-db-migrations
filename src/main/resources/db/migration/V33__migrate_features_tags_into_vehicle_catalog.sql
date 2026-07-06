-- V33: Consolidate the old UUID-keyed `features`/`tags` tables (V24, used only for
-- inventory checkbox tagging) into the richer bigint-keyed `vehicle_features`/`vehicle_tags`
-- catalog tables (V32), so there is a single admin-managed feature/tag system instead
-- of two divergent ones. Repoints inventory_vehicle_features/inventory_vehicle_tags to the
-- new tables, then drops the old ones.

-- 1. Copy existing feature/tag rows into the new catalog tables as active entries.
INSERT IGNORE INTO vehicle_features (name, slug, status, created_at, updated_at)
SELECT name,
       LOWER(TRIM(BOTH '-' FROM REGEXP_REPLACE(REGEXP_REPLACE(name, '[^a-zA-Z0-9]+', '-'), '-+', '-'))),
       1,
       NOW(),
       NOW()
FROM features;

INSERT IGNORE INTO vehicle_tags (name, slug, status, created_at, updated_at)
SELECT name,
       LOWER(TRIM(BOTH '-' FROM REGEXP_REPLACE(REGEXP_REPLACE(name, '[^a-zA-Z0-9]+', '-'), '-+', '-'))),
       1,
       NOW(),
       NOW()
FROM tags;

-- 2. Repoint inventory_vehicle_features from features.id (CHAR(36)) to vehicle_features.id (bigint).
ALTER TABLE inventory_vehicle_features
    ADD COLUMN feature_id_new BIGINT UNSIGNED NULL AFTER feature_id;

UPDATE inventory_vehicle_features ivf
JOIN features f ON ivf.feature_id = f.id
JOIN vehicle_features vf ON vf.name = f.name
SET ivf.feature_id_new = vf.id;

-- Drop and re-add the primary key in the SAME statement — MySQL evaluates the
-- resulting table shape as a whole, so the still-live fk_ivf_vehicle constraint
-- (on vehicle_id) never sees an intermediate state with no supporting index.
-- The recreated FK gets a new name: MySQL treats DROP FOREIGN KEY + ADD CONSTRAINT
-- with the SAME name in one ALTER TABLE as a duplicate name (error 1826), unlike
-- primary keys which can be dropped and re-added by the same name in one statement.
ALTER TABLE inventory_vehicle_features
    DROP FOREIGN KEY fk_ivf_feature,
    DROP PRIMARY KEY,
    DROP COLUMN feature_id,
    CHANGE COLUMN feature_id_new feature_id BIGINT UNSIGNED NOT NULL,
    ADD PRIMARY KEY (vehicle_id, feature_id),
    ADD CONSTRAINT fk_ivf_vehicle_features FOREIGN KEY (feature_id) REFERENCES vehicle_features(id) ON DELETE CASCADE;

-- 3. Repoint inventory_vehicle_tags from tags.id (CHAR(36)) to vehicle_tags.id (bigint).
ALTER TABLE inventory_vehicle_tags
    ADD COLUMN tag_id_new BIGINT UNSIGNED NULL AFTER tag_id;

UPDATE inventory_vehicle_tags ivt
JOIN tags t ON ivt.tag_id = t.id
JOIN vehicle_tags vt ON vt.name = t.name
SET ivt.tag_id_new = vt.id;

ALTER TABLE inventory_vehicle_tags
    DROP FOREIGN KEY fk_ivt_tag,
    DROP PRIMARY KEY,
    DROP COLUMN tag_id,
    CHANGE COLUMN tag_id_new tag_id BIGINT UNSIGNED NOT NULL,
    ADD PRIMARY KEY (vehicle_id, tag_id),
    ADD CONSTRAINT fk_ivt_vehicle_tags FOREIGN KEY (tag_id) REFERENCES vehicle_tags(id) ON DELETE CASCADE;

-- 4. Drop the old tables now that nothing references them.
DROP TABLE features;
DROP TABLE tags;
