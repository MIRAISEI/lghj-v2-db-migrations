-- V7__user_consents_schema.sql
-- Create user consents table
CREATE TABLE IF NOT EXISTS user_consents (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    user_id CHAR(36) NOT NULL,
    terms_accepted_at TIMESTAMP NOT NULL,
    privacy_accepted_at TIMESTAMP NOT NULL,
    marketing_opt_in_at TIMESTAMP NULL,
    ip VARCHAR(255) NULL,
    user_agent VARCHAR(255) NULL,
    UNIQUE KEY uq_user_consents_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
