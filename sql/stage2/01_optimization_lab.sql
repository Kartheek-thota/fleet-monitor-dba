-- FleetMonitor Stage 2: query optimization lab
ANALYZE fleet.vehicles;
ANALYZE fleet.schedules;
ANALYZE fleet.maintenance;

-- Baseline plan. The filter is intentionally not covered by the composite index.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT vehicle_id, registration_number, status
FROM fleet.vehicles
WHERE status = 'active'
ORDER BY registration_number;

-- Join and aggregation plan used by the dashboard.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT v.registration_number, COUNT(s.schedule_id) AS completed_trips,
       COALESCE(SUM(r.distance_km), 0) AS total_distance_km
FROM fleet.vehicles v
LEFT JOIN fleet.schedules s ON s.vehicle_id = v.vehicle_id AND s.status = 'completed'
LEFT JOIN fleet.routes r ON r.route_id = s.route_id
GROUP BY v.vehicle_id, v.registration_number
ORDER BY total_distance_km DESC;

-- Demonstrate a covering index for a frequent dashboard query.
CREATE INDEX IF NOT EXISTS idx_vehicles_status_registration
    ON fleet.vehicles(status, registration_number)
    INCLUDE (make, model, vehicle_type);

ANALYZE fleet.vehicles;

EXPLAIN (ANALYZE, BUFFERS)
SELECT registration_number, make, model, vehicle_type
FROM fleet.vehicles
WHERE status = 'active'
ORDER BY registration_number;

-- Useful administration checks:
SELECT relname, n_live_tup, last_analyze
FROM pg_stat_user_tables
WHERE schemaname = 'fleet'
ORDER BY relname;
