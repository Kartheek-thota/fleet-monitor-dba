-- FleetMonitor Stage 1: normalized PostgreSQL schema
CREATE SCHEMA IF NOT EXISTS fleet;

CREATE TABLE IF NOT EXISTS fleet.vehicles (
    vehicle_id BIGSERIAL PRIMARY KEY,
    registration_number VARCHAR(20) NOT NULL UNIQUE,
    make VARCHAR(60) NOT NULL,
    model VARCHAR(60) NOT NULL,
    manufacture_year SMALLINT CHECK (manufacture_year BETWEEN 1980 AND 2100),
    vehicle_type VARCHAR(30) NOT NULL CHECK (vehicle_type IN ('truck', 'van', 'car', 'bus')),
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'maintenance', 'inactive')),
    odometer_km NUMERIC(12, 1) NOT NULL DEFAULT 0 CHECK (odometer_km >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fleet.drivers (
    driver_id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    phone VARCHAR(30),
    license_number VARCHAR(40) NOT NULL UNIQUE,
    active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS fleet.routes (
    route_id BIGSERIAL PRIMARY KEY,
    route_code VARCHAR(30) NOT NULL UNIQUE,
    origin VARCHAR(120) NOT NULL,
    destination VARCHAR(120) NOT NULL,
    distance_km NUMERIC(10, 2) NOT NULL CHECK (distance_km > 0)
);

CREATE TABLE IF NOT EXISTS fleet.schedules (
    schedule_id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL REFERENCES fleet.vehicles(vehicle_id),
    driver_id BIGINT NOT NULL REFERENCES fleet.drivers(driver_id),
    route_id BIGINT NOT NULL REFERENCES fleet.routes(route_id),
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'planned'
        CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    CHECK (scheduled_end > scheduled_start)
);

CREATE TABLE IF NOT EXISTS fleet.maintenance (
    maintenance_id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL REFERENCES fleet.vehicles(vehicle_id),
    maintenance_type VARCHAR(60) NOT NULL,
    description TEXT,
    cost NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (cost >= 0),
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'open'
        CHECK (status IN ('open', 'in_progress', 'completed')),
    CHECK (completed_at IS NULL OR completed_at >= opened_at)
);

CREATE INDEX IF NOT EXISTS idx_vehicles_status ON fleet.vehicles(status);
CREATE INDEX IF NOT EXISTS idx_schedules_start_status ON fleet.schedules(scheduled_start, status);
CREATE INDEX IF NOT EXISTS idx_schedules_vehicle ON fleet.schedules(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_vehicle_status ON fleet.maintenance(vehicle_id, status);

CREATE OR REPLACE VIEW fleet.vehicle_operations AS
WITH schedule_counts AS (
    SELECT vehicle_id, COUNT(*) AS total_schedules
    FROM fleet.schedules
    WHERE status <> 'cancelled'
    GROUP BY vehicle_id
),
maintenance_counts AS (
    SELECT vehicle_id, COUNT(*) AS open_maintenance
    FROM fleet.maintenance
    WHERE status <> 'completed'
    GROUP BY vehicle_id
)
SELECT
    v.vehicle_id, v.registration_number, v.make, v.model, v.vehicle_type,
    v.status AS vehicle_status, v.odometer_km,
    COALESCE(sc.total_schedules, 0) AS total_schedules,
    COALESCE(mc.open_maintenance, 0) AS open_maintenance
FROM fleet.vehicles v
LEFT JOIN schedule_counts sc ON sc.vehicle_id = v.vehicle_id
LEFT JOIN maintenance_counts mc ON mc.vehicle_id = v.vehicle_id;
