-- Run in pgAdmin Query Tool session B while session A is open.
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- This sees the last committed value, not session A's uncommitted value.
SELECT registration_number, status
FROM fleet.vehicles
WHERE registration_number = 'KA-01-AB-1001';

-- This UPDATE waits for session A's row lock, then proceeds or rolls back.
UPDATE fleet.vehicles
SET status = 'active'
WHERE registration_number = 'KA-01-AB-1001';

COMMIT;
