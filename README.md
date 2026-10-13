# FleetMonitor DBA Project

## Online deployment

The dashboard can be published with Streamlit Community Cloud. Local addresses such as
`127.0.0.1`, `localhost`, port `5433`, and port `27017` are not reachable from an online
application, so use a hosted PostgreSQL database and MongoDB Atlas.

1. Create a hosted PostgreSQL database and run the Stage 1, Stage 4, and Stage 5 SQL scripts.
2. Create a MongoDB Atlas database and run `mongodb/01_setup.js`.
3. Push this project to GitHub.
4. In Streamlit Community Cloud, deploy `dashboard/app.py`.
5. Add `DATABASE_URL`, `MONGODB_URI`, and `MONGODB_DATABASE` under the app's Secrets settings.

For local testing, copy `.streamlit/secrets.toml.example` to
`.streamlit/secrets.toml` and replace the placeholders. The real secrets file is ignored by Git.

FleetMonitor is a database administration project for tracking vehicles, schedules, GPS positions, and maintenance activity.

## Project stages

1. **PostgreSQL table creation** - normalized fleet schema, constraints, indexes, views, and sample data.
2. **Query optimization** - `ANALYZE`, `EXPLAIN`, `EXPLAIN ANALYZE`, buffer inspection, and index comparison.
3. **MongoDB** - GPS location and maintenance-log documents, validation, indexes, and aggregation examples.
4. **Concurrency** - ACID, committed/uncommitted visibility, pessimistic locking, and optimistic version checks.
5. **Distributed database** - PostgreSQL streaming-replication design and sharding/partitioning notes.
6. **Python dashboard** - Streamlit dashboard connected to PostgreSQL and optionally MongoDB.

## Prerequisites

- PostgreSQL 15+ and pgAdmin 4
- MongoDB 6+ and `mongosh` (for Stage 3)
- Python 3.10+

## PostgreSQL setup in pgAdmin 4

1. Create a database named `fleet_monitor`.
2. Open Query Tool and run `sql/stage1/01_schema.sql`.
3. Run `sql/stage1/02_seed_data.sql`.
4. Run `sql/stage2/01_optimization_lab.sql`.
5. Run the Stage 4 scripts in two pgAdmin Query Tool tabs to observe transaction behavior.
6. Read `sql/stage5/01_distributed_design.sql` for the distributed deployment design.

Run scripts in the order shown. The scripts are idempotent where practical.

## Python dashboard (Jupyter Notebook)

```powershell
cd "C:\Users\karth\OneDrive\Pictures\Desktop\DBA project"
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r dashboard\requirements.txt
$env:DATABASE_URL="postgresql://postgres:your_password@localhost:5432/fleet_monitor"
jupyter notebook dashboard\FleetMonitor_Dashboard.ipynb
```

Open `dashboard\FleetMonitor_Dashboard.ipynb`, run the cells from top to bottom, and set `POSTGRES_PASSWORD` in the notebook or environment if required. The notebook connects to PostgreSQL and MongoDB and displays fleet KPIs, charts, maintenance data, and GPS locations.

The Streamlit version remains available with:

```powershell
streamlit run dashboard\app.py
```

See `docs/pgadmin4-guide.md` for a guided submission/demo flow.
