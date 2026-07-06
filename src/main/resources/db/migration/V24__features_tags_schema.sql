CREATE TABLE IF NOT EXISTS features (
    id   CHAR(36)     NOT NULL DEFAULT (UUID()),
    name VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_feature_name (name)
);

CREATE TABLE IF NOT EXISTS tags (
    id   CHAR(36)     NOT NULL DEFAULT (UUID()),
    name VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_tag_name (name)
);

CREATE TABLE IF NOT EXISTS inventory_vehicle_features (
    vehicle_id CHAR(36) NOT NULL,
    feature_id CHAR(36) NOT NULL,
    PRIMARY KEY (vehicle_id, feature_id),
    CONSTRAINT fk_ivf_vehicle FOREIGN KEY (vehicle_id) REFERENCES inventory_vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_ivf_feature FOREIGN KEY (feature_id) REFERENCES features(id)           ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS inventory_vehicle_tags (
    vehicle_id CHAR(36) NOT NULL,
    tag_id     CHAR(36) NOT NULL,
    PRIMARY KEY (vehicle_id, tag_id),
    CONSTRAINT fk_ivt_vehicle FOREIGN KEY (vehicle_id) REFERENCES inventory_vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_ivt_tag     FOREIGN KEY (tag_id)     REFERENCES tags(id)               ON DELETE CASCADE
);

-- Seed features
INSERT IGNORE INTO features (id, name) VALUES
    (UUID(), 'Back Camera'),
    (UUID(), 'Automatic Emergency Braking'),
    (UUID(), 'Adaptive Highlights'),
    (UUID(), 'Bicycle Detection'),
    (UUID(), 'Brake Assist'),
    (UUID(), 'Front Collision Warning'),
    (UUID(), 'Forward Collision Warning'),
    (UUID(), 'Traction Control'),
    (UUID(), 'Pedestrian Detection'),
    (UUID(), 'Curve Speed Warning'),
    (UUID(), 'High Speed Alert'),
    (UUID(), 'Adaptive Cruise Control'),
    (UUID(), 'Adaptive Headlights'),
    (UUID(), 'Electronic Stability Control'),
    (UUID(), 'Hill Descent Assist'),
    (UUID(), 'Leather Seats'),
    (UUID(), 'Dual AC'),
    (UUID(), 'Alloy Wheel'),
    (UUID(), 'Reverse Camera'),
    (UUID(), 'TV'),
    (UUID(), 'Navigation'),
    (UUID(), 'LED Headlights'),
    (UUID(), 'Air Condition'),
    (UUID(), 'Sunroof'),
    (UUID(), 'Heated Seats'),
    (UUID(), 'Keyless Entry'),
    (UUID(), 'Push Start'),
    (UUID(), 'Blind Spot Monitor');

-- Seed tags
INSERT IGNORE INTO tags (id, name) VALUES
    (UUID(), 'Recent Added'),
    (UUID(), 'Most Visited'),
    (UUID(), 'Best Selling'),
    (UUID(), 'Premium'),
    (UUID(), 'Cheapest'),
    (UUID(), 'Featured'),
    (UUID(), 'Machinery'),
    (UUID(), 'Machinery Parts'),
    (UUID(), 'Accident');
