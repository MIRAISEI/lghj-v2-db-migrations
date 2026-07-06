-- Tracks public detail-page view counts per stock vehicle, so the "Mostly
-- Visited Vehicles" homepage widget (public-client) can rank real inventory
-- instead of mock data. Owned/written by public-api only.
CREATE TABLE stock_vehicle_views (
    vehicle_id VARCHAR(36) NOT NULL,
    view_count BIGINT NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (vehicle_id)
);
