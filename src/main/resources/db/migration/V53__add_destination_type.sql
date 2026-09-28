-- V53: Distinguish destinations by type -- Local Yard (a domestic holding yard
-- a vehicle is transported to before shipment) vs Shipping Yard (the port/yard
-- it departs from). `destinations` (V49) is already published, so this adds
-- the column via ALTER rather than editing V49 in place.

ALTER TABLE destinations
    ADD COLUMN type ENUM('LOCAL_YARD', 'SHIPPING_YARD') NOT NULL DEFAULT 'LOCAL_YARD' AFTER name,
    ADD INDEX idx_destinations_type_status (type, status);
