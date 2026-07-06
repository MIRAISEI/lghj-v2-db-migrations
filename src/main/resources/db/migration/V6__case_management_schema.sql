-- Case Management Schema for Vehicle Export Auction Bidding
-- Merged from V4 + V5 + V6 + V7 — clean baseline (no prior migrations applied)
-- Supports: 1 case -> 1+ bid groups -> 1+ vehicles
-- Includes: partial bidding, advance payments, remarks, admin assignment, vehicle metadata

-- =============================================================================
-- 1. CASES (Core case table)
-- =============================================================================
CREATE TABLE IF NOT EXISTS cases (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    customer_id CHAR(36) NOT NULL COMMENT 'Customer who owns the case',

    -- Case Status (Group-level)
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT',

    -- Group-Level Financials (sum of all vehicles)
    total_cif_amount DECIMAL(15,2) COMMENT 'Sum of CIF for all vehicles',
    total_deposit_required DECIMAL(15,2),
    total_lc_amount DECIMAL(15,2),
    total_balance_amount DECIMAL(15,2),
    total_paid_amount DECIMAL(15,2) DEFAULT 0,

    -- Admin Assignment (V6)
    customer_assigned_by_admin_id CHAR(36) COMMENT 'Admin who assigned this case to a customer',
    customer_assigned_at TIMESTAMP COMMENT 'When admin assigned this case',

    -- Metadata
    created_by_user_id CHAR(36) COMMENT 'Who created case (null=customer, uuid=staff)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,

    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (customer_assigned_by_admin_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_customer_id (customer_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_customer_assigned_by_admin (customer_assigned_by_admin_id)
);

-- =============================================================================
-- 2. CASE BID GROUPS
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_bid_groups (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_id CHAR(36) NOT NULL,
    bid_group_id CHAR(36) NOT NULL COMMENT 'Links to customer_bids_groups (V1 migration)',
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_primary BOOLEAN DEFAULT FALSE COMMENT 'Primary group for case',

    -- V5: Partial bidding support
    num_vehicles_included INT UNSIGNED COMMENT 'How many vehicles are included in this bid group',
    max_bid_value DECIMAL(15,2) COMMENT 'Maximum bid value for this group',

    -- V6: Group-level remarks
    group_remarks TEXT COMMENT 'Remarks for this bid group',

    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    INDEX idx_case_id (case_id),
    INDEX idx_bid_group_id (bid_group_id),
    UNIQUE KEY unique_case_bid_group (case_id, bid_group_id)
);

-- =============================================================================
-- 3. CASE VEHICLES (Individual Vehicle Tracking)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_vehicles (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_id CHAR(36) NOT NULL,
    vehicle_position INT COMMENT 'Order within case (1, 2, 3...)',
    position_in_case INT NULL COMMENT 'Vehicle position within the case (V7)',

    -- Vehicle Reference (from auction/bid system)
    vehicle_id CHAR(36) COMMENT 'Links to auction vehicle',
    vehicle_reference VARCHAR(255) COMMENT 'Vehicle lot number or reference',
    lot_no VARCHAR(255) COMMENT 'Auction lot number (V5)',
    bid_date VARCHAR(255) COMMENT 'Date of bid (V5)',
    auction VARCHAR(255) COMMENT 'Auction house (V5)',
    original_auction_name VARCHAR(255) COMMENT 'Original auction name (V5)',
    vehicle_brand BIGINT UNSIGNED COMMENT 'Brand reference ID (V5)',
    vehicle_model BIGINT UNSIGNED COMMENT 'Model reference ID (V5)',
    vehicle_year INT,

    -- Per-Vehicle Bidding & Pricing
    vehicle_status ENUM(
        'PENDING',
        'IN_BIDDING',
        'BID_WIN',
        'BID_LOSS',
        'IGNORED'
    ) NOT NULL DEFAULT 'PENDING' COMMENT 'Per-vehicle auction result',
    intended_max_bid DECIMAL(15,2),
    actual_bid_amount DECIMAL(15,2),
    winning_bid_price DECIMAL(15,2),

    -- Per-Vehicle Pricing (calculated independently)
    country VARCHAR(100) COMMENT 'Destination for this vehicle (may differ)',
    vehicle_category VARCHAR(100),
    pricing_rule_applied VARCHAR(100),
    cif_amount DECIMAL(15,2) COMMENT 'Individual CIF for this vehicle',
    cif_breakdown_json JSON COMMENT 'Detailed fee breakdown per vehicle',
    metadata_json JSON COMMENT 'Additional metadata (V5)',

    -- Per-Vehicle Deposit (may be different)
    deposit_amount DECIMAL(15,2),
    deposit_verified_at TIMESTAMP,

    -- Per-Vehicle LC / Balance (can be submitted separately)
    lc_amount DECIMAL(15,2),
    lc_verified_at TIMESTAMP,
    balance_amount DECIMAL(15,2),
    balance_verified_at TIMESTAMP,

    -- Shipping Assignment (flexible)
    assigned_to_shipment_id CHAR(36) COMMENT 'Which shipment group this vehicle is in',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    INDEX idx_case_id (case_id),
    INDEX idx_vehicle_status (vehicle_status),
    INDEX idx_assigned_shipment (assigned_to_shipment_id)
);

-- =============================================================================
-- 4. CASE BID GROUP VEHICLES (V7: links vehicles to bid groups)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_bid_group_vehicles (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_bid_group_id CHAR(36) NOT NULL COMMENT 'Links to case_bid_groups',
    case_vehicle_id CHAR(36) NOT NULL COMMENT 'Links to case_vehicles',
    position_in_group INT UNSIGNED COMMENT 'Position of vehicle within the bid group',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (case_bid_group_id) REFERENCES case_bid_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    INDEX idx_case_bid_group_id (case_bid_group_id),
    INDEX idx_case_vehicle_id (case_vehicle_id),
    INDEX idx_bid_group_id_position (case_bid_group_id, position_in_group),
    UNIQUE KEY unique_bid_group_vehicle (case_bid_group_id, case_vehicle_id)
);

-- =============================================================================
-- 5. CASE VEHICLE METADATA (V7)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_vehicle_metadata (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_vehicle_id CHAR(36) NOT NULL COMMENT 'Links to case_vehicles',
    meta_key VARCHAR(100) NOT NULL,
    meta_value TEXT,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),

    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    INDEX idx_case_vehicle_id (case_vehicle_id),
    INDEX idx_meta_key (meta_key)
);

-- =============================================================================
-- 6. CASE DOCUMENTS (Per-Vehicle + Case-Level)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_documents (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_id CHAR(36) NOT NULL,
    case_vehicle_id CHAR(36) COMMENT 'NULL=case-level doc, UUID=vehicle-specific doc',

    document_type VARCHAR(100) NOT NULL
        COMMENT 'DEPOSIT_PROOF, LC_DOCUMENT, BALANCE_PROOF, YARD_PHOTOS, BL, BANK_DOCS, CI_INVOICE, etc.',

    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),

    -- Verification
    uploaded_by_user_id CHAR(36) NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_by_user_id CHAR(36),
    verified_at TIMESTAMP,
    verification_status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    rejection_reason TEXT,

    -- Metadata
    required_for_stage VARCHAR(50),
    is_mandatory BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (verified_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_case_id (case_id),
    INDEX idx_case_vehicle_id (case_vehicle_id),
    INDEX idx_document_type (document_type),
    INDEX idx_verification_status (verification_status)
);

-- =============================================================================
-- 7. CASE ADVANCE PAYMENTS (V5)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_advance_payments (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_id CHAR(36) NOT NULL,
    required_by_admin_id CHAR(36) NULL COMMENT 'Admin who set the requirement',
    required_amount DECIMAL(15,2) NOT NULL,
    required_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Payment proof
    payment_proof_document_id CHAR(36) COMMENT 'Links to case_documents',
    payment_amount_received DECIMAL(15,2),
    payment_received_at TIMESTAMP,
    verified_by_finance_id CHAR(36) COMMENT 'Finance user who verified',
    verified_at TIMESTAMP,
    verification_status ENUM('PENDING', 'VERIFIED', 'REJECTED') DEFAULT 'PENDING',
    verification_notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    FOREIGN KEY (required_by_admin_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (payment_proof_document_id) REFERENCES case_documents(id) ON DELETE SET NULL,
    FOREIGN KEY (verified_by_finance_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_case_id (case_id),
    INDEX idx_verification_status (verification_status)
);

-- =============================================================================
-- 8. CASE BID GROUP REMARKS (V6: bid-group-level only, one per group)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_bid_group_remarks (
    id VARCHAR(36) PRIMARY KEY,
    case_bid_group_id VARCHAR(36) NOT NULL,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (case_bid_group_id) REFERENCES case_bid_groups(id) ON DELETE CASCADE,
    INDEX idx_case_bid_group (case_bid_group_id),
    UNIQUE KEY unique_bid_group_remarks (case_bid_group_id)
);

-- =============================================================================
-- 9. CASE SHIPMENTS (Flexible Grouping of Vehicles)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_shipments (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_id CHAR(36) NOT NULL,
    shipment_number INT COMMENT 'Shipment 1, 2, 3... within case',

    vessel_name VARCHAR(255),
    etd_estimated DATE COMMENT 'Estimated Time of Departure',
    etd_updated_at TIMESTAMP,
    eta_estimated DATE COMMENT 'Estimated Time of Arrival',

    bl_document_id CHAR(36) COMMENT 'Bill of Lading for this shipment',
    bl_uploaded_at TIMESTAMP,

    shipment_status ENUM('PENDING', 'IN_YARD', 'INSPECTING', 'BOOKED', 'IN_TRANSIT', 'DELIVERED') DEFAULT 'PENDING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    INDEX idx_case_id (case_id),
    INDEX idx_shipment_status (shipment_status)
);

-- =============================================================================
-- 10. CASE SHIPMENT VEHICLES (Vehicle -> Shipment Mapping)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_shipment_vehicles (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    shipment_id CHAR(36) NOT NULL,
    case_vehicle_id CHAR(36) NOT NULL,

    yard_location VARCHAR(255),
    yard_in_at TIMESTAMP,
    inspection_company VARCHAR(100),
    inspection_result ENUM('PENDING', 'PASS', 'FAIL') DEFAULT 'PENDING',
    inspection_at TIMESTAMP,

    dhl_tracking_number VARCHAR(100) COMMENT 'DHL tracking for this vehicle''s docs',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (shipment_id) REFERENCES case_shipments(id) ON DELETE CASCADE,
    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    INDEX idx_shipment_id (shipment_id),
    INDEX idx_case_vehicle_id (case_vehicle_id),
    UNIQUE KEY unique_vehicle_shipment (case_vehicle_id, shipment_id)
);

-- =============================================================================
-- 11. CASE STATUS HISTORY (Group-Level)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_status_history (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_id CHAR(36) NOT NULL,
    from_status VARCHAR(50),
    to_status VARCHAR(50) NOT NULL,
    changed_by_user_id CHAR(36) NULL,
    changed_by_role VARCHAR(50),
    acte_by_user_id CHAR(36) COMMENT 'User who acted on this transition (V5)',
    transition_reason TEXT,
    vehicles_completed INT COMMENT 'How many vehicles completed at this status',
    vehicles_total INT COMMENT 'Total vehicles in case',
    -- Microsecond precision so transitions order reliably against case_activities
    -- on the merged timeline, even within the same second.
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (acte_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_case_id (case_id),
    INDEX idx_created_at (created_at),
    INDEX idx_acte_by_user (acte_by_user_id)
);

-- =============================================================================
-- 12. CASE MESSAGES (Threaded)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_messages (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_id CHAR(36) NOT NULL,
    case_vehicle_id CHAR(36) COMMENT 'NULL=case-level msg, UUID=vehicle-specific msg',
    sender_user_id CHAR(36) NULL,
    sender_role VARCHAR(50),
    message_text TEXT NOT NULL,
    message_type ENUM('USER_MESSAGE', 'SYSTEM_NOTE', 'STATUS_CHANGE') DEFAULT 'USER_MESSAGE',
    visibility ENUM('CUSTOMER_AND_STAFF', 'STAFF_ONLY') DEFAULT 'CUSTOMER_AND_STAFF',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    edited_at TIMESTAMP,

    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_case_id (case_id),
    INDEX idx_case_vehicle_id (case_vehicle_id),
    INDEX idx_created_at (created_at)
);

-- =============================================================================
-- 13. CASE ACTIVITIES (Audit Trail)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_activities (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_id CHAR(36) NOT NULL,
    case_vehicle_id CHAR(36) COMMENT 'NULL=case-level, UUID=vehicle-specific activity',
    activity_type VARCHAR(100) NOT NULL
        COMMENT 'STATUS_CHANGED, DOCUMENT_UPLOADED, DOCUMENT_VERIFIED, ASSIGNED_TO_SHIPMENT, etc.',
    actor_user_id CHAR(36) NULL,
    actor_role VARCHAR(50),
    old_value TEXT,
    new_value TEXT,
    description TEXT,
    metadata_json JSON,

    -- Microsecond precision so activities order reliably against
    -- case_status_history on the merged timeline, even within the same second.
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_case_id (case_id),
    INDEX idx_activity_type (activity_type),
    INDEX idx_created_at (created_at)
);

-- =============================================================================
-- 14. CASE STAFF ASSIGNMENTS (Group-Level)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_staff_assignments (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_id CHAR(36) NOT NULL,
    assigned_role VARCHAR(50) NOT NULL COMMENT 'BIDDING, SALES, FINANCE, SHIPPING',
    assigned_to_user_id CHAR(36),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by_user_id CHAR(36),
    unassigned_at TIMESTAMP,

    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_case_id (case_id),
    INDEX idx_assigned_role (assigned_role)
);

-- =============================================================================
-- 15. CASE FEEDBACK (Per-Vehicle)
-- =============================================================================
CREATE TABLE IF NOT EXISTS case_feedback (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_vehicle_id CHAR(36) NOT NULL UNIQUE COMMENT 'One feedback per vehicle',
    submitted_by_user_id CHAR(36) NULL,
    rating INT,
    feedback_text TEXT NOT NULL,
    media_files JSON,

    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (submitted_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_case_vehicle_id (case_vehicle_id)
);