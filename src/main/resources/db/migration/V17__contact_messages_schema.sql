-- V17__contact_messages_schema.sql
-- Create contact messages table for public "Send us a message" form submissions
CREATE TABLE IF NOT EXISTS contact_messages (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    subject VARCHAR(255) NULL,
    message TEXT NOT NULL,
    ip VARCHAR(255) NULL,
    user_agent VARCHAR(512) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_contact_messages_created_at (created_at)
);
