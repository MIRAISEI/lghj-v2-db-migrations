-- Extend vehicle_status enum to support inventory promotion of bid-won vehicles
ALTER TABLE case_vehicles
    MODIFY COLUMN vehicle_status
        ENUM('PENDING','IN_BIDDING','BID_WIN','BID_LOSS','IGNORED','IN_INVENTORY')
        NOT NULL DEFAULT 'PENDING';
