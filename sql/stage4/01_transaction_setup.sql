-- Stage 4 setup: optimistic-lock version column and safe update function
ALTER TABLE fleet.vehicles
    ADD COLUMN IF NOT EXISTS row_version INTEGER NOT NULL DEFAULT 1;

CREATE OR REPLACE FUNCTION fleet.update_vehicle_status_optimistic(
    p_vehicle_id BIGINT,
    p_expected_version INTEGER,
    p_status VARCHAR
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    updated_rows INTEGER;
BEGIN
    UPDATE fleet.vehicles
    SET status = p_status, row_version = row_version + 1
    WHERE vehicle_id = p_vehicle_id AND row_version = p_expected_version;
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    RETURN updated_rows = 1;
END;
$$;
