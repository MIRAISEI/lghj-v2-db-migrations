CREATE TABLE IF NOT EXISTS inventory_vehicles (
    id              CHAR(36)    NOT NULL DEFAULT (UUID()),
    chassis_no      VARCHAR(255),
    stock_id        VARCHAR(255),
    status          VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    case_vehicle_id CHAR(36)    NULL     COMMENT 'FK to case_vehicles when promoted from bid win',
    source_case_id  CHAR(36)    NULL     COMMENT 'Source case id for navigation to bid-request page',
    created_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    INDEX idx_inv_chassis_no        (chassis_no),
    INDEX idx_inv_status            (status),
    INDEX idx_inv_case_vehicle_id   (case_vehicle_id),
    INDEX idx_inv_source_case_id    (source_case_id)
);

CREATE TABLE IF NOT EXISTS inventory_vehicle_metadata (
    id         CHAR(36)     NOT NULL DEFAULT (UUID()),
    vehicle_id CHAR(36)     NOT NULL,
    meta_key   VARCHAR(100) NOT NULL,
    meta_value TEXT,
    created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT fk_inv_meta_vehicle FOREIGN KEY (vehicle_id)
        REFERENCES inventory_vehicles(id) ON DELETE CASCADE,
    INDEX idx_inv_meta_vehicle_id (vehicle_id),
    INDEX idx_inv_meta_key        (meta_key)
);
