CREATE TABLE IF NOT EXISTS payments (
    id CHAR(36) NOT NULL,
    order_id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    stripe_payment_intent_id VARCHAR(255) NULL,
    amount DECIMAL(19,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    status VARCHAR(16) NOT NULL,
    idempotency_key VARCHAR(128) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_payments PRIMARY KEY (id),
    CONSTRAINT uk_payments_stripe_payment_intent_id UNIQUE (stripe_payment_intent_id)
);

CREATE INDEX idx_payments_order_id ON payments (order_id);
CREATE INDEX idx_payments_user_id ON payments (user_id);

CREATE TABLE IF NOT EXISTS payment_events (
    id CHAR(36) NOT NULL,
    payment_id CHAR(36) NOT NULL,
    stripe_event_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    payload LONGTEXT NULL,
    processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_payment_events PRIMARY KEY (id),
    CONSTRAINT uk_payment_events_stripe_event_id UNIQUE (stripe_event_id)
);

CREATE INDEX idx_payment_events_payment_id ON payment_events (payment_id);

CREATE TABLE IF NOT EXISTS refunds (
    id CHAR(36) NOT NULL,
    payment_id CHAR(36) NOT NULL,
    stripe_refund_id VARCHAR(255) NULL,
    amount DECIMAL(19,2) NOT NULL,
    status VARCHAR(16) NOT NULL,
    reason VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_refunds PRIMARY KEY (id)
);

CREATE INDEX idx_refunds_payment_id ON refunds (payment_id);

CREATE TABLE IF NOT EXISTS subscriptions (
    id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    stripe_id VARCHAR(255) NOT NULL,
    stripe_status VARCHAR(255) NOT NULL,
    stripe_price VARCHAR(255) NULL,
    quantity INT NULL,
    trial_ends_at DATETIME(6) NULL,
    ends_at DATETIME(6) NULL,
    deleted_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_subscriptions PRIMARY KEY (id),
    CONSTRAINT uk_subscriptions_stripe_id UNIQUE (stripe_id)
);

CREATE INDEX idx_subscriptions_user_id_stripe_status ON subscriptions (user_id, stripe_status);

CREATE TABLE IF NOT EXISTS subscription_items (
    id CHAR(36) NOT NULL,
    subscription_id CHAR(36) NOT NULL,
    stripe_id VARCHAR(255) NOT NULL,
    stripe_product VARCHAR(255) NOT NULL,
    stripe_price VARCHAR(255) NOT NULL,
    membership_package_id CHAR(36) NULL,
    cycle INT NULL,
    quantity INT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_subscription_items PRIMARY KEY (id),
    CONSTRAINT uk_subscription_items_stripe_id UNIQUE (stripe_id),
    CONSTRAINT uk_subscription_items_subscription_price UNIQUE (subscription_id, stripe_price)
);

CREATE INDEX idx_subscription_items_membership_package_id ON subscription_items (membership_package_id);
