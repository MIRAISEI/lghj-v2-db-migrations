-- =============================================================================
-- Per-vehicle purchase tracking for won auction vehicles.
--
-- Staff record a purchase outcome (PENDING -> PURCHASED / CANCELLED) for each
-- won vehicle, from BOTH the bid-win confirmation dialog and the Purchasing
-- tab in the CRM. The "Purchase Value" reuses the pre-existing
-- case_vehicles.winning_bid_price column (until now never written by any code);
-- the "Purchase Receipt" is a case_documents row with
-- document_type = 'PURCHASE_RECEIPT'. Only purchase_status is a new column.
-- =============================================================================

ALTER TABLE case_vehicles
    ADD COLUMN purchase_status ENUM('PENDING', 'PURCHASED', 'CANCELLED') NOT NULL DEFAULT 'PENDING'
    COMMENT 'Staff-set purchase outcome for a won vehicle'
    AFTER winning_bid_price;
