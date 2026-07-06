-- Add Stripe customer tracking and payment method gate to users
ALTER TABLE users ADD COLUMN stripe_customer_id VARCHAR(255) NULL UNIQUE;
ALTER TABLE users ADD COLUMN payment_method_configured BIT NOT NULL DEFAULT 0;
