-- V34: Seed the vehicle_fuel_types catalog with the standard fuel type list.

INSERT IGNORE INTO vehicle_fuel_types (name, slug, status, created_at, updated_at) VALUES
    ('Gasoline', 'gasoline', 1, NOW(), NOW()),
    ('Diesel', 'diesel', 1, NOW(), NOW()),
    ('CNG', 'cng', 1, NOW(), NOW()),
    ('Bio Diesel', 'bio-diesel', 1, NOW(), NOW()),
    ('Liquid Petroleum Gas', 'liquid-petroleum-gas', 1, NOW(), NOW()),
    ('Ethanol', 'ethanol', 1, NOW(), NOW()),
    ('Methanol', 'methanol', 1, NOW(), NOW()),
    ('Premium Gasoline', 'premium-gasoline', 1, NOW(), NOW()),
    ('Electric', 'electric', 1, NOW(), NOW());
