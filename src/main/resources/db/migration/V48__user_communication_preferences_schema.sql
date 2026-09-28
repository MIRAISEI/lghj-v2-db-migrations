-- V48: Communication preferences per user (which channels they may be
-- contacted through: WhatsApp, phone call, email).

CREATE TABLE IF NOT EXISTS user_communication_preferences (
    id                CHAR(36)    NOT NULL DEFAULT (UUID()),
    user_id           CHAR(36)    NOT NULL,
    whatsapp_enabled  BOOLEAN     NOT NULL DEFAULT FALSE,
    call_enabled      BOOLEAN     NOT NULL DEFAULT FALSE,
    email_enabled     BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at        DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at        DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_user_communication_preferences_user (user_id),
    CONSTRAINT fk_user_communication_preferences_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);
