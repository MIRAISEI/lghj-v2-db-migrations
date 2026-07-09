-- V45: In-app notifications (initially: staff alerts when a bid case reaches a
-- status they are permitted to act on).

CREATE TABLE IF NOT EXISTS notifications (
    id             CHAR(36)     NOT NULL DEFAULT (UUID()),
    user_id        CHAR(36)     NOT NULL,
    type           VARCHAR(64)  NOT NULL,
    title          VARCHAR(255) NOT NULL,
    body           TEXT,
    reference_type VARCHAR(64),
    reference_id   VARCHAR(64),
    read_at        DATETIME(6),
    created_at     DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    INDEX idx_notifications_user_created (user_id, created_at),
    INDEX idx_notifications_user_unread (user_id, read_at),
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);
