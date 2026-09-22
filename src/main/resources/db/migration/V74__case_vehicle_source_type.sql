-- =============================================================================
-- Non-auction vehicle sourcing: a CaseVehicle can now originate from an
-- existing InventoryVehicle ("pick from stock") or a direct dealer purchase
-- with no auction involved, in addition to today's auction-bid path.
--
-- source_type is a provenance/intake-validation field -- existing rows
-- default to AUCTION (today's only path). inventory_vehicle_id is a forward
-- pointer to inventory_vehicles, populated at creation time for
-- INVENTORY/DEALER_DIRECT vehicles, and by bid-win promotion for AUCTION
-- vehicles (mirroring the existing reverse pointer inventory_vehicles.case_vehicle_id).
-- =============================================================================

ALTER TABLE case_vehicles
    ADD COLUMN source_type ENUM('AUCTION', 'INVENTORY', 'DEALER_DIRECT') NOT NULL DEFAULT 'AUCTION'
        COMMENT 'How this vehicle entered the case'
        AFTER vehicle_status,
    ADD COLUMN inventory_vehicle_id CHAR(36) NULL
        COMMENT 'Forward FK to inventory_vehicles -- set at creation for INVENTORY/DEALER_DIRECT, and by bid-win promotion for AUCTION'
        AFTER source_type,
    ADD CONSTRAINT fk_case_vehicles_inventory_vehicle FOREIGN KEY (inventory_vehicle_id)
        REFERENCES inventory_vehicles(id) ON DELETE SET NULL,
    ADD INDEX idx_case_vehicles_source_type (source_type),
    ADD INDEX idx_case_vehicles_inventory_vehicle_id (inventory_vehicle_id);

-- Backfill the forward pointer from the existing reverse pointer, set today
-- only by CaseService.promoteWinningVehiclesToInventory on bid win.
UPDATE case_vehicles cv
JOIN inventory_vehicles iv ON iv.case_vehicle_id = cv.id
SET cv.inventory_vehicle_id = iv.id
WHERE cv.inventory_vehicle_id IS NULL;
