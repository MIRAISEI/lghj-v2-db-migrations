-- =============================================================================
-- One exchange rate per order instead of one per payment stage.
--
-- V81 kept a separate rate for each payment stage (case_exchange_rates.target =
-- ADVANCE / BALANCE). Orders now have a single rate: staff set it once and every
-- payment uses it. The table stays append-only, and that history is what lets
-- each payment keep the rate that was current when it was paid (a paid advance
-- doesn't change when the rate is updated later; anything still unpaid uses the
-- newest row).
--
-- target becomes a nullable legacy column: new rows leave it NULL, existing
-- rows keep the stage they were set for (read as part of the one per-order
-- history, ordered by created_at).
-- =============================================================================

ALTER TABLE case_exchange_rates
    MODIFY COLUMN target ENUM('ADVANCE', 'BALANCE') NULL
        COMMENT 'Legacy (pre-V82): payment stage the rate was set for. NULL for per-order rates';

-- Per-order history / "rate at time T" lookups no longer filter on target.
ALTER TABLE case_exchange_rates
    ADD INDEX idx_case_exchange_rates_case_created (case_id, created_at);
