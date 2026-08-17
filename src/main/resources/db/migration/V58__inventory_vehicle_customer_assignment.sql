-- Customer assignment for inventory vehicles.
-- Vehicles promoted from a bidding request (source_case_id IS NOT NULL) are
-- auto-assigned to the case's customer and that assignment is locked;
-- manually-created inventory vehicles can be assigned/reassigned by staff.

ALTER TABLE inventory_vehicles
    ADD COLUMN assigned_customer_id  CHAR(36)    NULL COMMENT 'Customer assigned to this vehicle',
    ADD COLUMN assigned_by_admin_id  CHAR(36)    NULL COMMENT 'Admin who manually assigned the customer; NULL when auto-assigned from a bidding request',
    ADD COLUMN assigned_at           DATETIME(6) NULL COMMENT 'When the customer was assigned',
    ADD CONSTRAINT fk_inv_assigned_customer FOREIGN KEY (assigned_customer_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_inv_assigned_by_admin FOREIGN KEY (assigned_by_admin_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD INDEX idx_inv_assigned_customer_id (assigned_customer_id);
