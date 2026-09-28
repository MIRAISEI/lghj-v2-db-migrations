-- V56: Fix-forward for any database that already applied the original
-- V52__consolidate_booking_companies.sql (creating a single `booking_companies`
-- table) before that file was deleted and its rename folded directly into
-- V49/V50 (commit 1c63976). Those databases still physically have
-- `booking_companies` + the old `*_booking_company_id` FK columns, even
-- though Flyway now believes V49/V50 already created `vendors` directly.
--
-- A fresh database never touches this: V49 creates `vendors` straight away
-- and `booking_companies` never exists, so the guard below no-ops. Existing
-- vendor rows and their ids (and therefore the FK values referencing them)
-- are preserved by the plain RENAME/CHANGE COLUMN statements — nothing is
-- copied or recreated.

CREATE PROCEDURE _v56_migrate_legacy_booking_companies()
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = 'booking_companies'
    ) THEN
        ALTER TABLE case_shipments
            DROP FOREIGN KEY fk_case_shipments_shipping_booking_company;

        ALTER TABLE case_shipment_vehicles
            DROP FOREIGN KEY fk_case_shipment_vehicles_transport_booking_company,
            DROP FOREIGN KEY fk_case_shipment_vehicles_inspection_booking_company;

        RENAME TABLE booking_companies TO vendors;
        ALTER TABLE vendors RENAME INDEX idx_booking_companies_type_status TO idx_vendors_type_status;

        ALTER TABLE case_shipments
            CHANGE COLUMN shipping_booking_company_id shipping_vendor_id CHAR(36) NULL,
            RENAME INDEX idx_case_shipments_shipping_booking_company TO idx_case_shipments_shipping_vendor,
            ADD CONSTRAINT fk_case_shipments_shipping_vendor
                FOREIGN KEY (shipping_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL;

        ALTER TABLE case_shipment_vehicles
            CHANGE COLUMN transport_booking_company_id transport_vendor_id CHAR(36) NULL,
            CHANGE COLUMN inspection_booking_company_id inspection_vendor_id CHAR(36) NULL,
            RENAME INDEX idx_case_shipment_vehicles_transport_booking_company TO idx_case_shipment_vehicles_transport_vendor,
            RENAME INDEX idx_case_shipment_vehicles_inspection_booking_company TO idx_case_shipment_vehicles_inspection_vendor,
            ADD CONSTRAINT fk_case_shipment_vehicles_transport_vendor
                FOREIGN KEY (transport_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL,
            ADD CONSTRAINT fk_case_shipment_vehicles_inspection_vendor
                FOREIGN KEY (inspection_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL;
    END IF;
END;

CALL _v56_migrate_legacy_booking_companies();
DROP PROCEDURE _v56_migrate_legacy_booking_companies;
