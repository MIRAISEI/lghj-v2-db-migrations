-- =============================================================================
-- Retire the inventory ON_HOLD status in favour of RESERVED.
--
-- "On hold" (parked by staff / held for a customer) and "reserved" (held by an
-- order) meant the same thing to staff, so there is one status now: RESERVED.
-- Both are non-public and are excluded from the pool of stock a new order can
-- pick from; only ACTIVE stock is available. Idempotent: re-running is a no-op.
-- =============================================================================

-- A public listing is only ever ACTIVE or DRAFT (see V76): if one somehow carries
-- ON_HOLD, take it off the portal as a draft rather than "reserve" a listing.
UPDATE inventory_vehicles
SET status = 'DRAFT'
WHERE status = 'ON_HOLD'
  AND stock_type = 'Public Stock';

UPDATE inventory_vehicles
SET status = 'RESERVED'
WHERE status = 'ON_HOLD';
