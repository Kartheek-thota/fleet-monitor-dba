# pgAdmin 4 demonstration guide

## Stage 1

Create `fleet_monitor`, open **Query Tool**, and run the schema and seed scripts. In the Browser tree, expand **Schemas > fleet > Tables** and inspect the relationships.

## Stage 2

Run the optimization lab and capture the `EXPLAIN (ANALYZE, BUFFERS)` output. Explain the difference between estimated cost and actual time, and describe shared-hit versus shared-read buffers.

## Stage 3

Run the MongoDB scripts in `mongosh` or MongoDB Compass. Show the GeoJSON document, the `2dsphere` index, and the aggregation pipeline.

## Stage 4

Open two Query Tool tabs connected to the same database. Run Session A, then Session B. Session B demonstrates that uncommitted changes are not visible and that row locks serialize conflicting updates. The optimistic function demonstrates a version conflict without holding a long-running lock.

## Stage 5

Present the primary/replica topology, logical replication option, PgBouncer pooling, and time-partitioned telemetry table. Emphasize that replication and failover require server-level configuration beyond a single local pgAdmin database.

## Stage 6

Start Streamlit from the project root. Use PostgreSQL for fleet KPIs and set `MONGODB_URI` for GPS telemetry.
