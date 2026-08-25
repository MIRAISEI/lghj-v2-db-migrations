-- V60: Batch transport bookings. Staff routinely book one truck for several
-- vehicles picked up from the same place and dropped at the same yard/port,
-- and those vehicles often belong to different cases (different customers).
-- transport_arrangements is a standalone bookable unit (vendor + destination
-- + schedule + status) that any number of case_shipment_vehicles rows can
-- link to via the new nullable transport_arrangement_id FK below. NULL means
-- "not grouped" -- the vehicle's own transport_vendor_id/destination_id/
-- schedule_date/etc. columns (added in V50) stay authoritative exactly as
-- before. Only the PRIMARY transport leg is groupable in this version --
-- the local-yard-to-port leg (port_* columns, V59) is intentionally excluded
-- for now.

CREATE TABLE transport_arrangements (
    id CHAR(36) NOT NULL PRIMARY KEY,
    transport_vendor_id CHAR(36) NULL,
    destination_id CHAR(36) NULL,
    pickup_location VARCHAR(255) NULL,
    schedule_date DATE NULL,
    departure_date DATE NULL,
    on_contract TINYINT(1) NOT NULL DEFAULT 0,
    transport_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_status VARCHAR(50) NULL,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_transport_arrangements_transport_vendor
        FOREIGN KEY (transport_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL,
    CONSTRAINT fk_transport_arrangements_destination
        FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    INDEX idx_transport_arrangements_transport_vendor (transport_vendor_id),
    INDEX idx_transport_arrangements_destination (destination_id),
    INDEX idx_transport_arrangements_status (transport_status)
);

ALTER TABLE case_shipment_vehicles
    ADD COLUMN transport_arrangement_id CHAR(36) NULL,
    ADD CONSTRAINT fk_case_shipment_vehicles_transport_arrangement
        FOREIGN KEY (transport_arrangement_id) REFERENCES transport_arrangements(id) ON DELETE SET NULL,
    ADD INDEX idx_case_shipment_vehicles_transport_arrangement (transport_arrangement_id);
