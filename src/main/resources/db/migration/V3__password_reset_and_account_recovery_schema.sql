-- V3__password_reset_and_account_recovery_schema.sql
-- Create password reset tokens table
CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id CHAR(36) NOT NULL PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    used_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_password_reset_tokens_user_id ON password_reset_tokens(user_id);
CREATE INDEX idx_password_reset_tokens_token ON password_reset_tokens(token);

-- Create recovery codes table
CREATE TABLE IF NOT EXISTS recovery_codes (
    id CHAR(36) NOT NULL PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    code VARCHAR(20) NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    used_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_recovery_codes_user_id ON recovery_codes(user_id);
CREATE INDEX idx_recovery_codes_code ON recovery_codes(code);

-- Create recovery questions table
CREATE TABLE IF NOT EXISTS recovery_questions (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    question VARCHAR(255) NOT NULL UNIQUE,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Insert default recovery questions
INSERT IGNORE INTO recovery_questions (question, active) VALUES
    ('What is your mother''s maiden name?', TRUE),
    ('What was the name of your first pet?', TRUE),
    ('In what city were you born?', TRUE),
    ('What is your favorite book?', TRUE),
    ('What is the name of your elementary school?', TRUE),
    ('What was your childhood nickname?', TRUE),
    ('What is your favorite movie?', TRUE),
    ('What was the make and model of your first car?', TRUE);

-- Create user recovery answers table
CREATE TABLE IF NOT EXISTS user_recovery_answers (
    id CHAR(36) NOT NULL PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    question_id INT NOT NULL,
    answer_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES recovery_questions(id) ON DELETE RESTRICT,
    UNIQUE KEY unique_user_question (user_id, question_id)
);

CREATE INDEX idx_user_recovery_answers_user_id ON user_recovery_answers(user_id);

-- Create session termination logs table
CREATE TABLE IF NOT EXISTS session_termination_logs (
    id CHAR(36) NOT NULL PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    session_id CHAR(36) NOT NULL,
    ip_address VARCHAR(255),
    user_agent VARCHAR(500),
    termination_reason VARCHAR(50) NOT NULL,
    termination_type VARCHAR(50) NOT NULL,
    initiated_by VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_session_termination_logs_user_id ON session_termination_logs(user_id);
CREATE INDEX idx_session_termination_logs_created_at ON session_termination_logs(created_at);
