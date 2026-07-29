-- V52: Consolidate transport/inspection/shipping booking companies (V49) into
-- one `booking_companies` table distinguished by `type`, since all three share
-- an identical shape and audience. V49/V50 are already published (1.5.0) and
-- must not be edited in place -- this fixes forward instead.
--
-- The three tables were created in this same 1.5.0 release with no application
-- code ever having shipped against them, so there is no real data to migrate.

-- Drop the V50 FKs first -- they reference the tables we're about to drop.
ALTER TABLE case_shipments
    DROP FOREIGN KEY fk_case_shipments_shipping_booking_company;

ALTER TABLE case_shipment_vehicles
    DROP FOREIGN KEY fk_case_shipment_vehicles_transport_booking_company,
    DROP FOREIGN KEY fk_case_shipment_vehicles_inspection_booking_company;

DROP TABLE IF EXISTS transport_booking_companies;
DROP TABLE IF EXISTS inspection_booking_companies;
DROP TABLE IF EXISTS shipping_booking_companies;

CREATE TABLE IF NOT EXISTS booking_companies (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    type ENUM('TRANSPORT', 'INSPECTION', 'SHIPPING') NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    address VARCHAR(500),
    notes VARCHAR(1000),
    status TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1: active, 0: inactive',

    deleted_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_booking_companies_type_status (type, status)
);

-- Re-point the V50 FK columns at the consolidated table.
ALTER TABLE case_shipments
    ADD CONSTRAINT fk_case_shipments_shipping_booking_company
        FOREIGN KEY (shipping_booking_company_id) REFERENCES booking_companies(id) ON DELETE SET NULL;

ALTER TABLE case_shipment_vehicles
    ADD CONSTRAINT fk_case_shipment_vehicles_transport_booking_company
        FOREIGN KEY (transport_booking_company_id) REFERENCES booking_companies(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_case_shipment_vehicles_inspection_booking_company
        FOREIGN KEY (inspection_booking_company_id) REFERENCES booking_companies(id) ON DELETE SET NULL;
