-- V65: Shipping's own equivalent of V60's transport_arrangements -- one
-- shared shipment booking (booking company/port/date/method/ETD/ETA/loading
-- status/BL status) linkable to many vehicles across different cases, same
-- "never sync while linked, resolve via join" contract as TransportArrangement.
-- shipment_tracking_no stays on case_shipment_vehicles itself (per-vehicle
-- even while grouped), same way payment_status does for transport.

CREATE TABLE shipment_arrangements (
    id CHAR(36) NOT NULL PRIMARY KEY,
    booking_company_id CHAR(36) NULL,
    booking_port_id CHAR(36) NULL,
    booking_date DATE NULL,
    shipping_method VARCHAR(50) NULL,
    etd DATE NULL,
    eta DATE NULL,
    loading_status TINYINT(1) NOT NULL DEFAULT 0,
    bl_status TINYINT(1) NOT NULL DEFAULT 0,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_shipment_arrangements_booking_company
        FOREIGN KEY (booking_company_id) REFERENCES vendors(id) ON DELETE SET NULL,
    CONSTRAINT fk_shipment_arrangements_booking_port
        FOREIGN KEY (booking_port_id) REFERENCES destinations(id) ON DELETE SET NULL,
    INDEX idx_shipment_arrangements_booking_company (booking_company_id),
    INDEX idx_shipment_arrangements_booking_port (booking_port_id)
);

ALTER TABLE case_shipment_vehicles
    ADD COLUMN shipment_arrangement_id CHAR(36) NULL,
    ADD CONSTRAINT fk_case_shipment_vehicles_shipment_arrangement
        FOREIGN KEY (shipment_arrangement_id) REFERENCES shipment_arrangements(id) ON DELETE SET NULL,
    ADD INDEX idx_case_shipment_vehicles_shipment_arrangement (shipment_arrangement_id);
