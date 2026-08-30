-- V66: Inspection-failure resolution workflow.
--
-- Adds attempt history + a failure-resolution decision workflow on top of the
-- existing flat inspection_result/inspection_notes columns on
-- case_shipment_vehicles (left untouched -- these new tables are additive).
--
-- Three tables:
--  - inspection_attempts: append-only log, one row per inspection attempt.
--  - inspection_resolutions: one row per FAIL attempt that needs a staff/
--    customer decision; holds the mutable workflow state machine.
--  - inspection_charges: reusable required-amount -> proof -> verify record,
--    mirrors case_advance_payments' shape, used for both the fix-cost
--    approval and the re-auction-loss payment (charge_type distinguishes).
--
-- Also fixes a pre-existing drift: case_vehicles.vehicle_status's DB ENUM was
-- missing 'IN_INVENTORY', which the Java VehicleStatus enum already has.

ALTER TABLE case_vehicles
    MODIFY COLUMN vehicle_status ENUM(
        'PENDING',
        'IN_BIDDING',
        'BID_WIN',
        'BID_LOSS',
        'IGNORED',
        'IN_INVENTORY'
    ) NOT NULL DEFAULT 'PENDING' COMMENT 'Per-vehicle auction result';

CREATE TABLE IF NOT EXISTS inspection_attempts (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_vehicle_id CHAR(36) NOT NULL,
    case_shipment_vehicle_id CHAR(36) NULL COMMENT 'Shipment context at time of attempt, if any',
    attempt_number INT NOT NULL COMMENT '1, 2, 3... per case_vehicle_id',

    inspection_company VARCHAR(100) NULL,
    inspection_vendor_id CHAR(36) NULL,
    inspection_at TIMESTAMP NULL,
    result ENUM('PENDING', 'PASS', 'FAIL') NOT NULL DEFAULT 'PENDING',
    remark TEXT NULL COMMENT 'Required by the service layer when result = FAIL',
    report_document_id CHAR(36) NULL COMMENT 'Links to case_documents',

    recorded_by_user_id CHAR(36) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (case_shipment_vehicle_id) REFERENCES case_shipment_vehicles(id) ON DELETE SET NULL,
    FOREIGN KEY (inspection_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL,
    FOREIGN KEY (report_document_id) REFERENCES case_documents(id) ON DELETE SET NULL,
    FOREIGN KEY (recorded_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_inspection_attempts_case_vehicle (case_vehicle_id),
    INDEX idx_inspection_attempts_result (result),
    UNIQUE KEY unique_case_vehicle_attempt (case_vehicle_id, attempt_number)
);

CREATE TABLE IF NOT EXISTS inspection_resolutions (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    case_vehicle_id CHAR(36) NOT NULL,
    triggering_attempt_id CHAR(36) NOT NULL COMMENT 'The FAIL attempt this resolution answers',

    status ENUM(
        'OPEN',
        'RESOLVED_REINSPECT',
        'FIX_COST_PENDING_CUSTOMER',
        'FIX_COST_REJECTED',
        'FIX_COST_AWAITING_PROOF',
        'FIX_COST_AWAITING_VERIFICATION',
        'FIX_COST_VERIFIED',
        'FIX_IN_PROGRESS',
        'RESOLVED_FIX_AND_REINSPECT',
        'REAUCTION_PENDING_CUSTOMER',
        'REAUCTION_LOSS_AWAITING_PROOF',
        'REAUCTION_AGREED_NO_LOSS',
        'REAUCTION_LOSS_AWAITING_VERIFICATION',
        'REAUCTION_LOSS_VERIFIED',
        'RESOLVED_REAUCTION'
    ) NOT NULL DEFAULT 'OPEN',
    chosen_path ENUM('REINSPECT', 'FIX_AND_REINSPECT', 'REAUCTION') NULL,
    decided_by_user_id CHAR(36) NULL,
    decided_at TIMESTAMP NULL,
    decision_notes TEXT NULL,

    fix_cost_charge_id CHAR(36) NULL,
    reauction_loss_charge_id CHAR(36) NULL,
    resulting_attempt_id CHAR(36) NULL COMMENT 'Fresh inspection_attempts row this resolution spawned',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (case_vehicle_id) REFERENCES case_vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (triggering_attempt_id) REFERENCES inspection_attempts(id) ON DELETE CASCADE,
    FOREIGN KEY (decided_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (resulting_attempt_id) REFERENCES inspection_attempts(id) ON DELETE SET NULL,
    INDEX idx_inspection_resolutions_case_vehicle (case_vehicle_id),
    INDEX idx_inspection_resolutions_status (status),
    UNIQUE KEY unique_resolution_triggering_attempt (triggering_attempt_id)
);

CREATE TABLE IF NOT EXISTS inspection_charges (
    id CHAR(36) PRIMARY KEY COMMENT 'UUID',
    resolution_id CHAR(36) NOT NULL,
    charge_type ENUM('FIX_COST', 'REAUCTION_LOSS') NOT NULL,

    required_by_admin_id CHAR(36) NULL COMMENT 'Admin who set the requirement',
    required_amount DECIMAL(15,2) NOT NULL,
    required_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    customer_response ENUM('PENDING', 'AGREED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    customer_responded_at TIMESTAMP NULL,

    payment_proof_document_id CHAR(36) NULL COMMENT 'Links to case_documents',
    payment_amount_received DECIMAL(15,2) NULL,
    payment_received_at TIMESTAMP NULL,
    verified_by_finance_id CHAR(36) NULL COMMENT 'Finance user who verified',
    verified_at TIMESTAMP NULL,
    verification_status ENUM('PENDING', 'VERIFIED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    verification_notes TEXT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (resolution_id) REFERENCES inspection_resolutions(id) ON DELETE CASCADE,
    FOREIGN KEY (required_by_admin_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (payment_proof_document_id) REFERENCES case_documents(id) ON DELETE SET NULL,
    FOREIGN KEY (verified_by_finance_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_inspection_charges_resolution (resolution_id),
    INDEX idx_inspection_charges_verification_status (verification_status),
    UNIQUE KEY unique_resolution_charge_type (resolution_id, charge_type)
);

ALTER TABLE inspection_resolutions
    ADD CONSTRAINT fk_inspection_resolutions_fix_cost_charge
        FOREIGN KEY (fix_cost_charge_id) REFERENCES inspection_charges(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_inspection_resolutions_reauction_loss_charge
        FOREIGN KEY (reauction_loss_charge_id) REFERENCES inspection_charges(id) ON DELETE SET NULL;
