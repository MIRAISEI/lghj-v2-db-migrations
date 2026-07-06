CREATE TABLE IF NOT EXISTS audit_logs (
    id CHAR(36) NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    email VARCHAR(255) NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    reason VARCHAR(500) NULL,
    status VARCHAR(32) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_audit_logs PRIMARY KEY (id)
);

CREATE INDEX idx_audit_logs_email_created_at ON audit_logs (email, created_at DESC);
CREATE INDEX idx_audit_logs_event_type_created_at ON audit_logs (event_type, created_at DESC);
CREATE INDEX idx_audit_logs_ip_address_created_at ON audit_logs (ip_address, created_at DESC);
