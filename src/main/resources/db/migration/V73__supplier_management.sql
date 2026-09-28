-- =============================================================================
-- Supplier master data + per-vehicle supplier association.
--
-- Suppliers are companies that consign vehicles/parts to auctions. They mirror
-- the `vendors` master data (transport/inspection/shipping booking companies)
-- but their `type` is multi-valued -- a supplier may deal in cars, bikes,
-- auto parts, or any combination -- so the types live in a child table.
--
-- The Purchasing tab gets a single-select Supplier dropdown beside the auction
-- name; the chosen supplier is stored on case_vehicles.supplier_id.
--
-- Permissions SUPPLIER_READ/WRITE/DELETE are their own audience (ADMIN +
-- BIDDING), distinct from VENDOR_*.
-- =============================================================================

CREATE TABLE IF NOT EXISTS suppliers (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
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

    INDEX idx_suppliers_status (status)
);

CREATE TABLE IF NOT EXISTS supplier_types (
    supplier_id CHAR(36) NOT NULL,
    type ENUM('CAR', 'BIKE', 'AUTO_PARTS') NOT NULL,
    PRIMARY KEY (supplier_id, type),
    CONSTRAINT fk_supplier_types_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers(id) ON DELETE CASCADE
);

ALTER TABLE case_vehicles
    ADD COLUMN supplier_id CHAR(36) NULL AFTER original_auction_name,
    ADD CONSTRAINT fk_case_vehicles_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers(id) ON DELETE SET NULL;

-- Supplier master-data permissions
INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'SUPPLIER_READ'),
    (UUID(), 'SUPPLIER_WRITE'),
    (UUID(), 'SUPPLIER_DELETE');

-- ADMIN + BIDDING create/view/edit/delete suppliers day-to-day
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name IN ('ADMIN', 'BIDDING')
  AND p.name IN ('SUPPLIER_READ', 'SUPPLIER_WRITE', 'SUPPLIER_DELETE');
