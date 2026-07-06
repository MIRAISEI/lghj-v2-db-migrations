-- V18__newsletter_subscribers_schema.sql
-- Create newsletter subscribers table for the footer "Subscribe Newsletter" form
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    email VARCHAR(255) NOT NULL,
    ip VARCHAR(255) NULL,
    user_agent VARCHAR(512) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_newsletter_subscribers_email (email)
);
