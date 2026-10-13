-- Run in pgAdmin Query Tool session A.
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT vehicle_id, status, row_version
FROM fleet.vehicles
WHERE registration_number = 'KA-01-AB-1001'
FOR UPDATE;

-- Keep this transaction open while running session B.
UPDATE fleet.vehicles
SET status = 'maintenance'
WHERE registration_number = 'KA-01-AB-1001';

-- COMMIT;  -- execute after observing session B
-- ROLLBACK; -- use instead if this was only a demonstration
