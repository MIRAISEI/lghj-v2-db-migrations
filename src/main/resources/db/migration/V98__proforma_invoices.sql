-- V98: Proforma invoices per case vehicle, version history, and invoice number sequence

-- 1. Sequence table for generating gapless, monotonic invoice numbers
CREATE TABLE IF NOT EXISTS proforma_invoice_sequences (
    id INT PRIMARY KEY,
    next_val BIGINT NOT NULL
);

INSERT INTO proforma_invoice_sequences (id, next_val)
SELECT 1, 1001 WHERE NOT EXISTS (SELECT 1 FROM proforma_invoice_sequences WHERE id = 1);

-- 2. Master table for proforma invoices (one per case_vehicle)
CREATE TABLE IF NOT EXISTS proforma_invoices (
    id VARCHAR(36) PRIMARY KEY,
    case_id VARCHAR(36) NOT NULL,
    case_vehicle_id VARCHAR(36) NOT NULL,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    current_version INT NOT NULL DEFAULT 1,
    applicant_name VARCHAR(255) NOT NULL,
    applicant_address TEXT,
    description TEXT NOT NULL,
    chassis_number VARCHAR(100) NOT NULL,
    year_of_manufacture INT,
    destination VARCHAR(255) NOT NULL,
    hs_code VARCHAR(50),
    fob_amount DECIMAL(15, 2) NOT NULL,
    freight_amount DECIMAL(15, 2) NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    invoice_date DATE NOT NULL,
    created_by_user_id VARCHAR(36),
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT uq_case_vehicle_pi UNIQUE (case_id, case_vehicle_id),
    INDEX idx_pi_case_id (case_id),
    INDEX idx_pi_case_vehicle_id (case_vehicle_id)
);

-- 3. Version history table capturing snapshots of each generation
CREATE TABLE IF NOT EXISTS proforma_invoice_versions (
    id VARCHAR(36) PRIMARY KEY,
    proforma_invoice_id VARCHAR(36) NOT NULL,
    version INT NOT NULL,
    case_document_id VARCHAR(36) NOT NULL,
    applicant_name VARCHAR(255) NOT NULL,
    applicant_address TEXT,
    description TEXT NOT NULL,
    chassis_number VARCHAR(100) NOT NULL,
    year_of_manufacture INT,
    destination VARCHAR(255) NOT NULL,
    hs_code VARCHAR(50),
    fob_amount DECIMAL(15, 2) NOT NULL,
    freight_amount DECIMAL(15, 2) NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    invoice_date DATE NOT NULL,
    created_by_user_id VARCHAR(36),
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_piv_pi FOREIGN KEY (proforma_invoice_id) REFERENCES proforma_invoices(id) ON DELETE CASCADE,
    CONSTRAINT uq_pi_version UNIQUE (proforma_invoice_id, version),
    INDEX idx_piv_doc_id (case_document_id),
    INDEX idx_piv_pi (proforma_invoice_id)
);
