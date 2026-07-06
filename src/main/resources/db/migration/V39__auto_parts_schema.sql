-- V39: Auto Parts schema (catalog items, images, price, tags, public inquiries)

CREATE TABLE IF NOT EXISTS auto_parts (
    id                 CHAR(36)     NOT NULL DEFAULT (UUID()),
    name               VARCHAR(255) NOT NULL,
    slug               VARCHAR(255) NOT NULL,
    vehicle_brand_id   BIGINT UNSIGNED NULL,
    vehicle_model_id   BIGINT UNSIGNED NULL,
    grade              VARCHAR(255),
    manufacture_year   INT NULL,
    stock_type         VARCHAR(50)  NOT NULL DEFAULT 'Real Stock',
    stock_id           VARCHAR(255),
    description        TEXT,
    status             VARCHAR(50)  NOT NULL DEFAULT 'ACTIVE',
    created_at         DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at         DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY auto_parts_slug_unique (slug),
    INDEX idx_auto_parts_status (status),
    INDEX idx_auto_parts_stock_id (stock_id),
    INDEX idx_auto_parts_brand_id (vehicle_brand_id),
    INDEX idx_auto_parts_model_id (vehicle_model_id),
    CONSTRAINT fk_auto_parts_brand FOREIGN KEY (vehicle_brand_id) REFERENCES vehicle_brands(id) ON DELETE SET NULL,
    CONSTRAINT fk_auto_parts_model FOREIGN KEY (vehicle_model_id) REFERENCES vehicle_models(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS auto_part_images (
    id              CHAR(36)     NOT NULL DEFAULT (UUID()),
    auto_part_id    CHAR(36)     NOT NULL,
    file_path       VARCHAR(500) NOT NULL,
    file_name       VARCHAR(255),
    mime_type       VARCHAR(100),
    file_size_bytes BIGINT,
    status          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    is_primary      TINYINT(1)   NOT NULL DEFAULT 0,
    sort_order      INT          NOT NULL DEFAULT 0,
    created_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT fk_auto_part_img_part FOREIGN KEY (auto_part_id)
        REFERENCES auto_parts(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS auto_part_prices (
    id           CHAR(36)      NOT NULL DEFAULT (UUID()),
    auto_part_id CHAR(36)      NOT NULL,
    price        DECIMAL(15,2),
    qty          INT,
    used_qty     INT           NOT NULL DEFAULT 0,
    created_at   DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at   DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY auto_part_prices_auto_part_id_unique (auto_part_id),
    CONSTRAINT fk_auto_part_price_part FOREIGN KEY (auto_part_id)
        REFERENCES auto_parts(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS auto_part_tags (
    auto_part_id CHAR(36)        NOT NULL,
    tag_id       BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (auto_part_id, tag_id),
    CONSTRAINT fk_auto_part_tags_part FOREIGN KEY (auto_part_id)
        REFERENCES auto_parts(id) ON DELETE CASCADE,
    CONSTRAINT fk_auto_part_tags_tag FOREIGN KEY (tag_id)
        REFERENCES vehicle_tags(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS auto_parts_inquiries (
    id              CHAR(36)     NOT NULL DEFAULT (UUID()),
    name            VARCHAR(255) NOT NULL,
    email           VARCHAR(255),
    phone           VARCHAR(255),
    skype           VARCHAR(255),
    model           VARCHAR(255),
    chassis_no      VARCHAR(255),
    part_condition  VARCHAR(255),
    shipping_method VARCHAR(255),
    message         TEXT,
    status          VARCHAR(50)  NOT NULL DEFAULT 'NEW',
    created_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    INDEX idx_auto_parts_inquiries_status (status)
);
