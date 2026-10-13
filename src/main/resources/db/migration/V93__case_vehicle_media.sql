-- =============================================================================
-- Order photos (the order page's Media tab).
--
-- Staff upload photos of each vehicle on an order, in four categories (yard in,
-- auction, original vehicle, port delivery), and choose which ones the customer
-- sees in the portal (is_public). An inventory vehicle's edit page also lists
-- the photos from the orders it has been on (joined through
-- case_vehicles.inventory_vehicle_id).
--
-- The table was first created on staging by Hibernate (ddl-auto=update); this
-- migration gives every other database the same table. IF NOT EXISTS leaves the
-- staging copy as it is. Rows go with their order vehicle; deleting an order
-- also removes the stored files.
-- =============================================================================

CREATE TABLE IF NOT EXISTS case_vehicle_media (
    id CHAR(36) PRIMARY KEY,
    case_vehicle_id CHAR(36) NOT NULL,
    category VARCHAR(50) NOT NULL COMMENT 'YARD_IN, AUCTION, ORIGINAL_VEHICLE, PORT_DELIVERY',
    is_public BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'shown to the customer in the portal',
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(1000) NOT NULL,
    content_type VARCHAR(255) NULL,
    uploaded_by_user_id CHAR(36) NULL,
    created_at DATETIME(6) NULL DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    INDEX idx_case_vehicle_media_vehicle (case_vehicle_id, created_at)
);
