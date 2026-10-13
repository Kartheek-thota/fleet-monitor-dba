-- Stage 5: distributed PostgreSQL design notes and partitioning example.
-- Production topology:
--   fleet-primary: read/write leader
--   fleet-replica-1: streaming replica for read-heavy reports
--   fleet-replica-2: disaster-recovery replica
--   PgBouncer: connection pooling
--   application: routes writes to primary and safe reads to replicas
--
-- PostgreSQL logical replication can publish selected tables:
-- CREATE PUBLICATION fleet_publication FOR TABLE fleet.vehicles, fleet.schedules;
-- On a subscriber:
-- CREATE SUBSCRIPTION fleet_subscription
-- CONNECTION 'host=PRIMARY dbname=fleet_monitor user=replication password=...'
-- PUBLICATION fleet_publication;
--
-- For high-volume telemetry, partition by event time. This table is a local
-- demonstration of the distribution-friendly data model.
CREATE TABLE IF NOT EXISTS fleet.vehicle_events (
    event_id BIGSERIAL,
    vehicle_id BIGINT NOT NULL REFERENCES fleet.vehicles(vehicle_id),
    event_type VARCHAR(30) NOT NULL,
    event_time TIMESTAMPTZ NOT NULL,
    latitude NUMERIC(9, 6),
    longitude NUMERIC(9, 6),
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (event_id, event_time)
) PARTITION BY RANGE (event_time);

CREATE TABLE IF NOT EXISTS fleet.vehicle_events_current
PARTITION OF fleet.vehicle_events
FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

CREATE INDEX IF NOT EXISTS idx_vehicle_events_vehicle_time
    ON fleet.vehicle_events(vehicle_id, event_time DESC);
