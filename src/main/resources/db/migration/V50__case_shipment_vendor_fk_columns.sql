-- V50: Link case shipments/shipment-vehicles to the new vendor and
-- destination master-data tables (V49). ON DELETE SET NULL throughout —
-- deactivating/soft-deleting a vendor must not cascade-delete case history.

ALTER TABLE case_shipments
    ADD COLUMN shipping_booking_company_id CHAR(36) NULL AFTER shipment_number,
    ADD COLUMN destination_id CHAR(36) NULL AFTER shipping_booking_company_id,
    ADD CONSTRAINT fk_case_shipments_shipping_booking_company
        FOREIGN KEY (shipping_booking_company_id) REFERENCES shipping_booking_companies(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_case_shipments_destination
        FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    ADD INDEX idx_case_shipments_shipping_booking_company (shipping_booking_company_id),
    ADD INDEX idx_case_shipments_destination (destination_id);

ALTER TABLE case_shipment_vehicles
    ADD COLUMN transport_booking_company_id CHAR(36) NULL AFTER yard_in_at,
    ADD COLUMN destination_id CHAR(36) NULL AFTER transport_booking_company_id,
    ADD COLUMN inspection_booking_company_id CHAR(36) NULL AFTER inspection_company,
    ADD CONSTRAINT fk_case_shipment_vehicles_transport_booking_company
        FOREIGN KEY (transport_booking_company_id) REFERENCES transport_booking_companies(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_case_shipment_vehicles_destination
        FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_case_shipment_vehicles_inspection_booking_company
        FOREIGN KEY (inspection_booking_company_id) REFERENCES inspection_booking_companies(id) ON DELETE SET NULL,
    ADD INDEX idx_case_shipment_vehicles_transport_booking_company (transport_booking_company_id),
    ADD INDEX idx_case_shipment_vehicles_destination (destination_id),
    ADD INDEX idx_case_shipment_vehicles_inspection_booking_company (inspection_booking_company_id);
