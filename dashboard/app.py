import os
from datetime import datetime, timezone

import pandas as pd
import plotly.express as px
import streamlit as st
from psycopg_pool import ConnectionPool

try:
    from pymongo import MongoClient
except ImportError:
    MongoClient = None

st.set_page_config(page_title="FleetMonitor", page_icon="🚚", layout="wide")
st.title("FleetMonitor")
st.caption("PostgreSQL operations dashboard with optional MongoDB telemetry")

def setting(name: str, default=None):
    """Read Streamlit Secrets first, then environment variables."""
    try:
        value = st.secrets.get(name)
    except Exception:
        value = None
    return value if value not in (None, "") else os.getenv(name, default)


database_url = setting("DATABASE_URL")
if not database_url:
    st.error("DATABASE_URL is not configured.")
    st.info("Add it to .streamlit/secrets.toml or the Streamlit Cloud Secrets settings.")
    st.stop()

@st.cache_resource
def get_pool():
    return ConnectionPool(database_url, min_size=1, max_size=4, open=True)

def query_df(sql: str, params=None) -> pd.DataFrame:
    with get_pool().connection() as conn:
        return pd.read_sql_query(sql, conn, params=params)

try:
    vehicles = query_df("""
        SELECT vehicle_id, registration_number, make, model, vehicle_type,
               vehicle_status, odometer_km, total_schedules, open_maintenance
        FROM fleet.vehicle_operations
        ORDER BY registration_number
    """)
    schedule_summary = query_df("""
        SELECT s.status, COUNT(*) AS trip_count
        FROM fleet.schedules s
        GROUP BY s.status
        ORDER BY trip_count DESC
    """)
except Exception as exc:
    st.error(f"PostgreSQL connection failed: {exc}")
    st.info("Set DATABASE_URL and run the PostgreSQL Stage 1 scripts first.")
    st.stop()

active_count = int((vehicles["vehicle_status"] == "active").sum())
maintenance_count = int((vehicles["vehicle_status"] == "maintenance").sum())
open_work = int(vehicles["open_maintenance"].sum())

metric_cols = st.columns(4)
metric_cols[0].metric("Vehicles", len(vehicles))
metric_cols[1].metric("Active", active_count)
metric_cols[2].metric("In maintenance", maintenance_count)
metric_cols[3].metric("Open work orders", open_work)

left, right = st.columns(2)
with left:
    st.subheader("Fleet status")
    st.plotly_chart(
        px.pie(vehicles, names="vehicle_status", hole=0.45),
        use_container_width=True,
    )
with right:
    st.subheader("Schedules")
    st.plotly_chart(
        px.bar(schedule_summary, x="status", y="trip_count", text_auto=True),
        use_container_width=True,
    )

st.subheader("Vehicle operations")
st.dataframe(vehicles, use_container_width=True, hide_index=True)

mongo_uri = setting("MONGODB_URI")
mongo_db_name = setting("MONGODB_DATABASE", "fleet_monitor")
if mongo_uri and MongoClient:
    try:
        client = MongoClient(mongo_uri, serverSelectionTimeoutMS=2000)
        mongo_db = client[mongo_db_name]
        latest = list(mongo_db.gps_locations.find(
            {}, {"_id": 0, "vehicle_id": 1, "recorded_at": 1, "location": 1, "speed_kph": 1}
        ).sort("recorded_at", -1).limit(100))
        st.subheader("Latest GPS telemetry")
        if latest:
            gps = pd.DataFrame(latest)
            gps["longitude"] = gps["location"].apply(lambda x: x["coordinates"][0])
            gps["latitude"] = gps["location"].apply(lambda x: x["coordinates"][1])
            st.map(gps[["latitude", "longitude"]], zoom=5)
            st.dataframe(gps.drop(columns=["location"]), use_container_width=True, hide_index=True)
        else:
            st.info("MongoDB is connected, but no GPS documents were found.")
    except Exception as exc:
        st.warning(f"MongoDB telemetry unavailable: {exc}")
else:
    st.info("Set MONGODB_URI to display MongoDB GPS telemetry.")

st.caption(f"Last refreshed: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}")
