-- =============================================================================
-- Enforce unique stock IDs on inventory_vehicles and auto_parts
-- =============================================================================
-- The admin app now auto-generates stock_id as "yyyyMMdd-NN" (creation date +
-- daily sequence) instead of accepting free text, so staff can no longer
-- create duplicate stock numbers by hand. This locks the column down with a
-- UNIQUE constraint so the database itself rejects any future collision,
-- regardless of which code path writes the row.
--
-- Any database that already has rows with a NULL/blank stock_id, or with a
-- stock_id duplicated across rows, must be backfilled BEFORE this migration
-- runs -- see admin-api's scripts/backfill-stock-ids.sh, which regenerates
-- those values using the same "yyyyMMdd-NN" scheme. A fresh database (all
-- rows created through the app, which always sets a unique stock_id) needs
-- no backfill and this migration applies cleanly on its own.

ALTER TABLE inventory_vehicles
    MODIFY COLUMN stock_id VARCHAR(255) NOT NULL,
    ADD CONSTRAINT uq_inventory_vehicles_stock_id UNIQUE (stock_id);

ALTER TABLE auto_parts
    MODIFY COLUMN stock_id VARCHAR(255) NOT NULL,
    ADD CONSTRAINT uq_auto_parts_stock_id UNIQUE (stock_id);
