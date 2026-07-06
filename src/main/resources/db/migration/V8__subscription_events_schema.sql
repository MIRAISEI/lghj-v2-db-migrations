CREATE TABLE IF NOT EXISTS subscription_events (
    id          CHAR(36)     NOT NULL,
    stripe_event_id VARCHAR(255) NOT NULL,
    event_type  VARCHAR(255) NOT NULL,
    subscription_id CHAR(36) NULL,
    processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_subscription_events PRIMARY KEY (id),
    CONSTRAINT uk_subscription_events_stripe_event_id UNIQUE (stripe_event_id)
);
