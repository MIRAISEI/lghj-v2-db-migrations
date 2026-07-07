-- V42: Auto Parts metadata (EAV key/value attributes, e.g. color, weight, dimensions)

CREATE TABLE IF NOT EXISTS auto_parts_meta (
    id           CHAR(36)     NOT NULL DEFAULT (UUID()),
    auto_part_id CHAR(36)     NOT NULL,
    meta_key     VARCHAR(100) NOT NULL,
    meta_value   TEXT,
    created_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT fk_auto_parts_meta_part FOREIGN KEY (auto_part_id)
        REFERENCES auto_parts(id) ON DELETE CASCADE,
    INDEX idx_auto_parts_meta_part_id (auto_part_id),
    INDEX idx_auto_parts_meta_key (meta_key)
);
