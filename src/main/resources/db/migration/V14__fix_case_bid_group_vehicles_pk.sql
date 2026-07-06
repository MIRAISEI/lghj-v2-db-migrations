-- Fix case_bid_group_vehicles: table had a standalone UUID `id` PK that Hibernate's
-- @ManyToMany join-table mapping never sets, causing "Field 'id' doesn't have a default
-- value" on every manual-case creation. Replace it with a composite PK on the two FKs.

ALTER TABLE case_bid_group_vehicles
    DROP PRIMARY KEY,
    DROP COLUMN id,
    ADD PRIMARY KEY (case_bid_group_id, case_vehicle_id);
