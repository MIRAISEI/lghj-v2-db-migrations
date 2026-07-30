-- V50: Link case shipments/shipment-vehicles to the vendor and destination
-- master-data tables (V49). ON DELETE SET NULL throughout -- deactivating/
-- soft-deleting a vendor must not cascade-delete case history.

ALTER TABLE case_shipments
    ADD COLUMN shipping_vendor_id CHAR(36) NULL AFTER shipment_number,
    ADD COLUMN destination_id CHAR(36) NULL AFTER shipping_vendor_id,
    ADD CONSTRAINT fk_case_shipments_shipping_vendor
        FOREIGN KEY (shipping_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_case_shipments_destination
        FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    ADD INDEX idx_case_shipments_shipping_vendor (shipping_vendor_id),
    ADD INDEX idx_case_shipments_destination (destination_id);

ALTER TABLE case_shipment_vehicles
    ADD COLUMN transport_vendor_id CHAR(36) NULL AFTER yard_in_at,
    ADD COLUMN destination_id CHAR(36) NULL AFTER transport_vendor_id,
    ADD COLUMN inspection_vendor_id CHAR(36) NULL AFTER inspection_company,
    ADD CONSTRAINT fk_case_shipment_vehicles_transport_vendor
        FOREIGN KEY (transport_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_case_shipment_vehicles_destination
        FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_case_shipment_vehicles_inspection_vendor
        FOREIGN KEY (inspection_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL,
    ADD INDEX idx_case_shipment_vehicles_transport_vendor (transport_vendor_id),
    ADD INDEX idx_case_shipment_vehicles_destination (destination_id),
    ADD INDEX idx_case_shipment_vehicles_inspection_vendor (inspection_vendor_id);
