CREATE TABLE IF NOT EXISTS inventory_images (
    id              CHAR(36)     NOT NULL DEFAULT (UUID()),
    vehicle_id      CHAR(36)     NOT NULL,
    file_path       VARCHAR(500) NOT NULL,
    file_name       VARCHAR(255),
    mime_type       VARCHAR(100),
    file_size_bytes BIGINT,
    status          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    is_primary      TINYINT(1)   NOT NULL DEFAULT 0,
    sort_order      INT          NOT NULL DEFAULT 0,
    created_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT fk_inv_img_vehicle FOREIGN KEY (vehicle_id)
        REFERENCES inventory_vehicles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS inventory_videos (
    id              CHAR(36)     NOT NULL DEFAULT (UUID()),
    vehicle_id      CHAR(36)     NOT NULL,
    file_path       VARCHAR(500) NOT NULL,
    file_name       VARCHAR(255),
    mime_type       VARCHAR(100),
    file_size_bytes BIGINT,
    created_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT fk_inv_vid_vehicle FOREIGN KEY (vehicle_id)
        REFERENCES inventory_vehicles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS inventory_documents (
    id              CHAR(36)     NOT NULL DEFAULT (UUID()),
    vehicle_id      CHAR(36)     NOT NULL,
    document_name   VARCHAR(255) NOT NULL,
    file_path       VARCHAR(500) NOT NULL,
    file_name       VARCHAR(255),
    mime_type       VARCHAR(100),
    file_size_bytes BIGINT,
    status          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    created_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT fk_inv_doc_vehicle FOREIGN KEY (vehicle_id)
        REFERENCES inventory_vehicles(id) ON DELETE CASCADE
);
