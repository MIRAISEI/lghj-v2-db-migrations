-- =============================================================================
-- Receipts for money added to a customer's wallet by hand.
--
-- Adding money to a wallet (a WALLET_ADJUSTMENT change request with a positive
-- amount) needs proof that the money was received, the same way an order's
-- advance / balance payments need a receipt. The file is stored when staff file
-- the request, so the approver can check it before approving; the ledger row
-- written on approval points at it (wallet_ledger_entries.wallet_receipt_id).
--
-- Like the ledger (V89) there are no foreign keys: a receipt outlives the user,
-- the change request or anything else it mentions. Rows are only inserted.
--
-- Note: wallet money is never spent automatically. A verified receipt pays its
-- own payment and anything over stays in the wallet until staff or the customer
-- put it towards a payment (this supersedes the V89 header's wording).
-- =============================================================================

CREATE TABLE IF NOT EXISTS wallet_receipts (
    id CHAR(36) PRIMARY KEY,
    customer_id CHAR(36) NOT NULL,
    change_request_id CHAR(36) NULL COMMENT 'the WALLET_ADJUSTMENT request it was filed with',
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100) NULL,
    file_size_bytes BIGINT NULL,
    uploaded_by_user_id CHAR(36) NULL,
    uploaded_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_wallet_receipts_customer (customer_id, uploaded_at),
    INDEX idx_wallet_receipts_request (change_request_id)
);

ALTER TABLE wallet_ledger_entries
    ADD COLUMN wallet_receipt_id CHAR(36) NULL COMMENT 'receipt of money added by hand (wallet_receipts)' AFTER source_document_id;
