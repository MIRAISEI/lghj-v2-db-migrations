-- =============================================================================
-- Customer-less orders: an inventory / dealer-direct order can be created before
-- a customer is known, so staff can arrange transport / inspection / shipping
-- first. cases.customer_id becomes nullable; the existing FK to users(id) stays
-- (a NULL simply skips the reference). Advance payment is not required while the
-- order has no customer, and is enforced from the moment one is assigned.
-- =============================================================================

ALTER TABLE cases
    MODIFY COLUMN customer_id CHAR(36) NULL;
