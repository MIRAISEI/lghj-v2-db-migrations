-- V64: Let any transport leg (not just the primary one) join a batch
-- transport_arrangement -- staff can group "Transportation #2", "#3", etc.
-- across vehicles the same way the primary leg already does, e.g. several
-- vehicles all making the same local-yard-to-port hop together.

ALTER TABLE case_shipment_vehicle_legs
    ADD COLUMN transport_arrangement_id CHAR(36) NULL,
    ADD CONSTRAINT fk_case_shipment_vehicle_legs_transport_arrangement
        FOREIGN KEY (transport_arrangement_id) REFERENCES transport_arrangements(id) ON DELETE SET NULL,
    ADD INDEX idx_case_shipment_vehicle_legs_transport_arrangement (transport_arrangement_id);
