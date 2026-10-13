-- Optimistic concurrency: two clients first read the same version.
SELECT vehicle_id, registration_number, status, row_version
FROM fleet.vehicles
WHERE registration_number = 'KA-01-AB-1001';

-- Replace 1 with the version read by the client.
SELECT fleet.update_vehicle_status_optimistic(
    (SELECT vehicle_id FROM fleet.vehicles WHERE registration_number = 'KA-01-AB-1001'),
    1,
    'maintenance'
) AS update_succeeded;

-- The first client returns true; a second client using the same old version returns false.
