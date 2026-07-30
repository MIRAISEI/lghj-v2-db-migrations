-- V49: Vendor/master-data tables for Transport, Inspection, and Shipping
-- workflows (vendors + destinations), plus their permissions.
--
-- Transport/Inspection/Shipping vendors share an identical shape and are
-- managed by the same audience, so they live in one table distinguished by
-- `type` rather than three near-identical tables.

CREATE TABLE IF NOT EXISTS vendors (
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

    INDEX idx_vendors_type_status (type, status)
);

CREATE TABLE IF NOT EXISTS destinations (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100),
    port_code VARCHAR(20),
    address VARCHAR(500),
    notes VARCHAR(1000),
    status TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1: active, 0: inactive',

    deleted_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_destinations_status (status)
);

-- Vendor/destination master-data permissions
INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'VENDOR_READ'),
    (UUID(), 'VENDOR_WRITE'),
    (UUID(), 'VENDOR_DELETE'),
    (UUID(), 'CASE_LOGISTICS_MANAGE');

-- ADMIN gets everything
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN' AND p.name IN ('VENDOR_READ', 'VENDOR_WRITE', 'VENDOR_DELETE', 'CASE_LOGISTICS_MANAGE');

-- SHIPPING staff maintain the vendor/destination lists and record logistics on cases day-to-day
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'SHIPPING' AND p.name IN ('VENDOR_READ', 'VENDOR_WRITE', 'VENDOR_DELETE', 'CASE_LOGISTICS_MANAGE');

-- BIDDING/SALES/FINANCE only need to view the selected vendor/destination on a case
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name IN ('BIDDING', 'SALES', 'FINANCE') AND p.name = 'VENDOR_READ';
