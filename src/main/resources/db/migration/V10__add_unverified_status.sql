-- Add UNVERIFIED to the users status check constraint
ALTER TABLE users DROP CONSTRAINT chk_users_status;
ALTER TABLE users ADD CONSTRAINT chk_users_status
    CHECK (status IN ('UNVERIFIED', 'PENDING', 'ACTIVE', 'SUSPENDED', 'LOCKED', 'CLOSED'));

-- Add UNVERIFIED to user_status_history check constraints
ALTER TABLE user_status_history DROP CONSTRAINT chk_user_status_history_previous;
ALTER TABLE user_status_history DROP CONSTRAINT chk_user_status_history_new;

ALTER TABLE user_status_history ADD CONSTRAINT chk_user_status_history_previous
    CHECK (previous_status IS NULL OR previous_status IN ('UNVERIFIED', 'PENDING', 'ACTIVE', 'SUSPENDED', 'LOCKED', 'CLOSED'));
ALTER TABLE user_status_history ADD CONSTRAINT chk_user_status_history_new
    CHECK (new_status IN ('UNVERIFIED', 'PENDING', 'ACTIVE', 'SUSPENDED', 'LOCKED', 'CLOSED'));