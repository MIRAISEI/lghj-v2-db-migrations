CREATE TABLE user_favourite_items (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    user_id CHAR(36) NOT NULL COMMENT 'FK to users.id',
    group_name ENUM('A','B','C','D','E') NOT NULL COMMENT 'Favourite group A-E',
    vehicle_id VARCHAR(255) NOT NULL COMMENT 'External AVTO vehicle ID',
    vehicle_type ENUM('CAR','BIKE') NOT NULL COMMENT 'Vehicle auction type',

    -- Cached vehicle snapshot
    brand VARCHAR(255) COMMENT 'Cached brand name',
    model VARCHAR(255) COMMENT 'Cached model name',
    grade VARCHAR(100) COMMENT 'Cached grade',
    auction_date VARCHAR(100) COMMENT 'Cached auction date',
    avg_price VARCHAR(100) COMMENT 'Cached average price',
    image TEXT COMMENT 'Cached vehicle image URL',

    status ENUM('ACTIVE','REMOVED') NOT NULL DEFAULT 'ACTIVE' COMMENT 'Item status',
    deleted_at TIMESTAMP NULL COMMENT 'Soft delete timestamp',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uq_user_vehicle (user_id, vehicle_id, status),
    INDEX idx_user_group (user_id, group_name)
);
