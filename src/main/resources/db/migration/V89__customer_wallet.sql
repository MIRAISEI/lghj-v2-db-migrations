-- =============================================================================
-- Customer wallet: a JPY ledger of every yen a customer has paid us and every
-- yen applied to what they owe.
--
-- 1. Every verified payment (advance receipt, balance instalment, repair
--    charge receipt) is credited to the customer's wallet. Every amount due
--    on an order (the advance, the balance, an agreed repair charge) is paid
--    by applying wallet money to it. Whatever is left over -- an overpayment,
--    money released by a lowered due or a cancelled order -- stays as wallet
--    balance and is applied automatically to the customer's next outstanding
--    due, oldest first.
--
-- 2. wallet_ledger_entries is the source of truth. Amounts are signed JPY
--    (credit +, debit -). It is append-only: mistakes are fixed by a new
--    reversing row (reverses_entry_id), never by editing. idempotency_key
--    makes a repeated action (e.g. re-verifying the same receipt) a no-op.
--    Like case_audit_events (V85) it has no foreign keys on purpose, so the
--    money trail survives if an order, document or user row is later removed;
--    actor_name / reason are display snapshots.
--
-- 3. customer_wallets caches the balance (= SUM(amount) of the customer's
--    entries) and is the row every write locks (SELECT ... FOR UPDATE), so two
--    concurrent verifications can't spend the same credit twice.
--
-- 4. case_wallet_allocations: how much wallet money is currently applied to
--    each due of an order. admin-api and public-api both read this one view,
--    so "how much of this due is paid" is defined in one place.
--
-- 5. inspection_charges.verified_amount: repair charges get the same
--    staff-entered verified amount as advance / balance receipts, because that
--    is the amount credited to the wallet. settled_amount is what the charge
--    closed at (receipt + wallet money already applied to it), so a charge
--    verified for less than required counts as settled at that figure, the
--    way an under-paid verified advance always has.
--
-- 6. Permissions: WALLET_READ (see wallets), WALLET_REFUND (request paying
--    wallet money back to the customer outside the system) and WALLET_ADJUST
--    (request a manual correction). Refunds and adjustments are change_requests
--    (entity_type WALLET) approved by CHANGE_REQUEST_APPROVE holders. Kept in
--    sync with both PermissionName enums.
--
-- Needs the TRIGGER privilege like V88 (scripts/grant-migration-privileges.sql).
-- =============================================================================

CREATE TABLE IF NOT EXISTS customer_wallets (
    customer_id CHAR(36) PRIMARY KEY COMMENT 'users.id (no FK: the wallet outlives the user row)',
    balance DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'cached SUM(wallet_ledger_entries.amount)',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
);

CREATE TABLE IF NOT EXISTS wallet_ledger_entries (
    id CHAR(36) PRIMARY KEY,
    customer_id CHAR(36) NOT NULL,
    amount DECIMAL(15,2) NOT NULL COMMENT 'signed JPY: + credit, - debit',
    entry_type VARCHAR(32) NOT NULL COMMENT 'PAYMENT_CREDIT, PAYMENT_VOID, DUE_APPLIED, DUE_RELEASED, REFUND_OUT, ADJUSTMENT',

    case_id CHAR(36) NULL,
    case_vehicle_id CHAR(36) NULL,
    due_type VARCHAR(16) NULL COMMENT 'ADVANCE, BALANCE, REPAIR (DUE_APPLIED / DUE_RELEASED only)',
    inspection_charge_id CHAR(36) NULL COMMENT 'REPAIR dues and repair receipts',
    source_document_id CHAR(36) NULL COMMENT 'the receipt (case_documents) a PAYMENT_CREDIT / PAYMENT_VOID is for',
    reverses_entry_id CHAR(36) NULL,
    change_request_id CHAR(36) NULL COMMENT 'approved refund / adjustment request',

    idempotency_key VARCHAR(191) NOT NULL,
    exchange_rate_snapshot DECIMAL(19,8) NULL COMMENT 'display only: order rate when the entry was written',
    currency_snapshot VARCHAR(8) NULL,
    external_reference VARCHAR(255) NULL COMMENT 'bank / transfer reference of a refund',
    reason VARCHAR(1000) NULL,

    actor_user_id CHAR(36) NULL COMMENT 'NULL = system / automatic',
    actor_name VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    UNIQUE KEY uk_wallet_ledger_idempotency (idempotency_key),
    INDEX idx_wallet_ledger_customer_created (customer_id, created_at),
    INDEX idx_wallet_ledger_case_due (case_id, due_type, inspection_charge_id),
    INDEX idx_wallet_ledger_source_document (source_document_id)
);

DROP TRIGGER IF EXISTS wallet_ledger_entries_no_update;
CREATE TRIGGER wallet_ledger_entries_no_update
    BEFORE UPDATE ON wallet_ledger_entries
    FOR EACH ROW
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'wallet_ledger_entries is append-only: rows cannot be updated';

DROP TRIGGER IF EXISTS wallet_ledger_entries_no_delete;
CREATE TRIGGER wallet_ledger_entries_no_delete
    BEFORE DELETE ON wallet_ledger_entries
    FOR EACH ROW
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'wallet_ledger_entries is append-only: rows cannot be deleted';

-- Applied amount per due: DUE_APPLIED rows are negative (money leaves the
-- wallet), DUE_RELEASED rows positive, so the applied amount is -SUM.
CREATE OR REPLACE VIEW case_wallet_allocations AS
SELECT case_id,
       due_type,
       inspection_charge_id,
       customer_id,
       -SUM(amount) AS applied_amount
FROM wallet_ledger_entries
WHERE entry_type IN ('DUE_APPLIED', 'DUE_RELEASED')
GROUP BY case_id, due_type, inspection_charge_id, customer_id;

ALTER TABLE inspection_charges
    ADD COLUMN verified_amount DECIMAL(15,2) NULL COMMENT 'staff-confirmed amount received (credited to the wallet); 0 when the wallet paid it all' AFTER payment_amount_received,
    ADD COLUMN settled_amount DECIMAL(15,2) NULL COMMENT 'what the charge closed at when verified: receipt + wallet money already applied, capped at required_amount' AFTER verified_amount;

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'WALLET_READ'),
    (UUID(), 'WALLET_REFUND'),
    (UUID(), 'WALLET_ADJUST');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- Approvers of change requests review wallet refunds / adjustments, so they
-- need to see wallets.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT DISTINCT rp.role_id, wallet.id
FROM role_permissions rp
JOIN permissions approve ON approve.id = rp.permission_id AND approve.name = 'CHANGE_REQUEST_APPROVE'
JOIN permissions wallet ON wallet.name = 'WALLET_READ';
