CREATE TABLE IF NOT EXISTS roles (
    id CHAR(36) NOT NULL,
    name VARCHAR(64) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_roles PRIMARY KEY (id),
    CONSTRAINT uk_roles_name UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS permissions (
    id CHAR(36) NOT NULL,
    name VARCHAR(64) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_permissions PRIMARY KEY (id),
    CONSTRAINT uk_permissions_name UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) NOT NULL,
    username VARCHAR(80) NOT NULL,
    email VARCHAR(255) NOT NULL,
    email_verified_at DATETIME(6) NULL,
    password VARCHAR(255) NOT NULL,
    status VARCHAR(32) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uk_users_username UNIQUE (username),
    CONSTRAINT uk_users_email UNIQUE (email),
    CONSTRAINT chk_users_status CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'LOCKED', 'CLOSED'))
);

CREATE INDEX idx_users_status ON users (status);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id CHAR(36) NOT NULL,
    role_id CHAR(36) NOT NULL,
    CONSTRAINT pk_user_roles PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles (id)
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id CHAR(36) NOT NULL,
    permission_id CHAR(36) NOT NULL,
    CONSTRAINT pk_role_permissions PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles (id),
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions (id)
);

CREATE TABLE IF NOT EXISTS users_meta (
    id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    meta_key VARCHAR(100) NOT NULL,
    meta_value TEXT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_users_meta PRIMARY KEY (id),
    CONSTRAINT uk_users_meta_user_key UNIQUE (user_id, meta_key),
    CONSTRAINT fk_users_meta_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_users_meta_key ON users_meta (meta_key);

CREATE TABLE IF NOT EXISTS user_status_history (
    id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    previous_status VARCHAR(32) NULL,
    new_status VARCHAR(32) NOT NULL,
    reason VARCHAR(255) NULL,
    changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_user_status_history PRIMARY KEY (id),
    CONSTRAINT fk_user_status_history_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_user_status_history_previous CHECK (previous_status IS NULL OR previous_status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'LOCKED', 'CLOSED')),
    CONSTRAINT chk_user_status_history_new CHECK (new_status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'LOCKED', 'CLOSED'))
);

CREATE INDEX idx_user_status_history_user_changed_at ON user_status_history (user_id, changed_at DESC);

CREATE TABLE IF NOT EXISTS otp_tokens (
    id CHAR(36) NOT NULL,
    email VARCHAR(255) NOT NULL,
    otp VARCHAR(20) NOT NULL,
    expires_at DATETIME(6) NOT NULL,
    used BIT(1) NOT NULL DEFAULT b'0',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_otp_tokens PRIMARY KEY (id)
);

CREATE INDEX idx_otp_tokens_email_used_expires_at ON otp_tokens (email, used, expires_at DESC);

INSERT IGNORE INTO permissions (id, name)
VALUES
    (UUID(), 'USER_READ'),
    (UUID(), 'USER_WRITE'),
    (UUID(), 'USER_DELETE'),
    (UUID(), 'ROLE_READ'),
    (UUID(), 'ROLE_WRITE'),
    (UUID(), 'ROLE_DELETE');

INSERT IGNORE INTO roles (id, name)
VALUES
    (UUID(), 'ADMIN'),
    (UUID(), 'BIDDING'),
    (UUID(), 'SALES'),
    (UUID(), 'FINANCE'),
    (UUID(), 'SHIPPING'),
    (UUID(), 'CUSTOMER'),
    (UUID(), 'SUPPORT');