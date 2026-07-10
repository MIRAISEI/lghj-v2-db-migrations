-- V43: Stock price inquiries (public "Get a Price Quote" requests on stock vehicles)

CREATE TABLE IF NOT EXISTS stock_price_inquiries (
    id            CHAR(36)     NOT NULL DEFAULT (UUID()),
    user_id       CHAR(36)     NULL,
    name          VARCHAR(255) NOT NULL,
    email         VARCHAR(255),
    phone         VARCHAR(255),
    country       VARCHAR(255),
    vehicle_id    CHAR(36),
    stock_no      VARCHAR(255),
    vehicle_title VARCHAR(512),
    message       TEXT,
    status        VARCHAR(50)  NOT NULL DEFAULT 'NEW',
    created_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    INDEX idx_stock_price_inquiries_status (status),
    INDEX idx_stock_price_inquiries_user (user_id),
    CONSTRAINT fk_stock_price_inquiries_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE SET NULL
);
