CREATE TABLE IF NOT EXISTS email_verification_tokens (
    id          CHAR(36)     NOT NULL,
    user_id     CHAR(36)     NOT NULL,
    token       VARCHAR(255) NOT NULL,
    expires_at  DATETIME(6)  NOT NULL,
    used        BIT          NOT NULL DEFAULT 0,
    used_at     DATETIME(6)  NULL,
    created_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_email_verification_tokens PRIMARY KEY (id),
    CONSTRAINT uk_email_verification_tokens_token UNIQUE (token),
    CONSTRAINT fk_email_verification_tokens_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
