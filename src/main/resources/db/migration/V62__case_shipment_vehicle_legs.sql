-- V62: Replace the fixed primary+port two-leg model (V59/V61, never
-- published) with an unbounded ordered chain of transport legs per vehicle.
-- A local yard destination can itself lead to another local yard before
-- finally reaching a shipping yard, so a single fixed "port" leg wasn't
-- enough. The primary leg (vendor/destination/schedule/status/payment on
-- case_shipment_vehicles itself, still groupable via transport_arrangements)
-- is unchanged; this table holds every leg AFTER the primary one, ordered by
-- leg_order starting at 1.

CREATE TABLE case_shipment_vehicle_legs (
    id CHAR(36) NOT NULL PRIMARY KEY,
    case_shipment_vehicle_id CHAR(36) NOT NULL,
    leg_order INT NOT NULL,
    transport_vendor_id CHAR(36) NULL,
    destination_id CHAR(36) NULL,
    schedule_date DATE NULL,
    departure_date DATE NULL,
    on_contract TINYINT(1) NOT NULL DEFAULT 0,
    transport_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_status VARCHAR(50) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT unique_case_shipment_vehicle_leg_order UNIQUE (case_shipment_vehicle_id, leg_order),
    CONSTRAINT fk_case_shipment_vehicle_legs_shipment_vehicle
        FOREIGN KEY (case_shipment_vehicle_id) REFERENCES case_shipment_vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_case_shipment_vehicle_legs_transport_vendor
        FOREIGN KEY (transport_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL,
    CONSTRAINT fk_case_shipment_vehicle_legs_destination
        FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    INDEX idx_case_shipment_vehicle_legs_shipment_vehicle (case_shipment_vehicle_id),
    INDEX idx_case_shipment_vehicle_legs_transport_vendor (transport_vendor_id),
    INDEX idx_case_shipment_vehicle_legs_destination (destination_id)
);
