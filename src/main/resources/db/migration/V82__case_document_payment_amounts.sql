-- =============================================================================
-- Balance payment in instalments.
--
-- The balance can now be paid over several receipts. Each BALANCE_PROOF is one
-- instalment and carries its own amounts:
--
--   declared_amount  what the customer (or staff on their behalf) entered when
--                    uploading the receipt. Unverified input, shown to the
--                    reviewer for reference only.
--   verified_amount  what the reviewer confirmed from the receipt when approving
--                    it. Only this figure is taken off the balance; the balance
--                    left = Σ(CIF − LC) − advance − Σ verified_amount of the
--                    APPROVED balance proofs.
--
-- Nullable and generic (not balance-specific) so other payment proofs can use
-- them later.
--
-- Backfill:
--   * A PENDING balance proof gets the amount declared on it, which was held on
--     cases.total_balance_amount (only one proof can be pending at a time).
--   * Balance proofs APPROVED before this migration are left with a NULL
--     verified_amount. They were approved as "balance paid in full", and the
--     APIs keep reading them that way.
-- =============================================================================

ALTER TABLE case_documents
    ADD COLUMN declared_amount DECIMAL(15,2) NULL,
    ADD COLUMN verified_amount DECIMAL(15,2) NULL;

UPDATE case_documents d
    JOIN cases c ON c.id = d.case_id
SET d.declared_amount = c.total_balance_amount
WHERE d.document_type = 'BALANCE_PROOF'
  AND d.verification_status = 'PENDING'
  AND d.deleted_at IS NULL;
