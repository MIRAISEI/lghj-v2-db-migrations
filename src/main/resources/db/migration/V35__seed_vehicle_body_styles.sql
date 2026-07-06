-- V35: Seed the vehicle_body_styles catalog with the standard body style list.

INSERT IGNORE INTO vehicle_body_styles (name, slug, image, status, created_at, updated_at) VALUES
    ('Sedan', 'sedan', NULL, 1, NOW(), NOW()),
    ('Hatchback', 'hatchback', NULL, 1, NOW(), NOW()),
    ('Coupe', 'coupe', NULL, 1, NOW(), NOW()),
    ('Sports car', 'sports-car', NULL, 1, NOW(), NOW()),
    ('Station Wagon', 'station-wagon', NULL, 1, NOW(), NOW()),
    ('Hatchback', 'hatchback-1', NULL, 1, NOW(), NOW()),
    ('Convertible', 'convertible', NULL, 1, NOW(), NOW()),
    ('Sport Utility Vehicle', 'sport-utility-vehicle', NULL, 1, NOW(), NOW()),
    ('Mini Van', 'mini-van', NULL, 1, NOW(), NOW()),
    ('Pick up truck', 'pick-up-truck', NULL, 1, NOW(), NOW()),
    ('WING VAN', 'wing-van', NULL, 1, NOW(), NOW()),
    ('Flat Bed Truck', 'flat-bed-truck', NULL, 1, NOW(), NOW()),
    ('Power Gate Truck', 'power-gate-truck', NULL, 1, NOW(), NOW()),
    ('REFRIGERATOR', 'refrigerator', 'style/image/A6Rc1asNgqCcYQ1z7dsVsUkTeQ7bcpx4xYW6I2eO.jpg', 1, NOW(), NOW()),
    ('TANKER TRUCK', 'tanker-truck', NULL, 1, NOW(), NOW()),
    ('machinery', 'machinery', NULL, 1, NOW(), NOW()),
    ('SUV', 'suv', NULL, 1, NOW(), NOW());
