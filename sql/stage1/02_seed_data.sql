-- FleetMonitor sample data
INSERT INTO fleet.vehicles
    (registration_number, make, model, manufacture_year, vehicle_type, status, odometer_km)
VALUES
    ('KA-01-AB-1001', 'Tata', 'Prima', 2021, 'truck', 'active', 84210.5),
    ('KA-01-CD-2002', 'Ashok Leyland', 'Dost', 2020, 'van', 'maintenance', 61200.0),
    ('KA-01-EF-3003', 'Mahindra', 'Bolero', 2022, 'car', 'active', 35400.2),
    ('KA-01-GH-4004', 'Volvo', '9400', 2019, 'bus', 'active', 120345.8)
ON CONFLICT (registration_number) DO NOTHING;

INSERT INTO fleet.drivers (full_name, phone, license_number)
VALUES
    ('Anil Kumar', '+91-9000000001', 'KA-DL-10001'),
    ('Priya Sharma', '+91-9000000002', 'KA-DL-10002'),
    ('Ravi Singh', '+91-9000000003', 'KA-DL-10003')
ON CONFLICT (license_number) DO NOTHING;

INSERT INTO fleet.routes (route_code, origin, destination, distance_km)
VALUES
    ('BLR-MYS', 'Bengaluru', 'Mysuru', 145.00),
    ('BLR-HYD', 'Bengaluru', 'Hyderabad', 570.00),
    ('BLR-CHN', 'Bengaluru', 'Chennai', 350.00)
ON CONFLICT (route_code) DO NOTHING;

INSERT INTO fleet.schedules
    (vehicle_id, driver_id, route_id, scheduled_start, scheduled_end, status)
SELECT v.vehicle_id, d.driver_id, r.route_id,
       now() + interval '1 day', now() + interval '1 day 4 hours', 'planned'
FROM fleet.vehicles v
JOIN fleet.drivers d ON d.license_number = 'KA-DL-10001'
JOIN fleet.routes r ON r.route_code = 'BLR-MYS'
WHERE v.registration_number = 'KA-01-AB-1001'
  AND NOT EXISTS (SELECT 1 FROM fleet.schedules s WHERE s.vehicle_id = v.vehicle_id);

INSERT INTO fleet.maintenance (vehicle_id, maintenance_type, description, cost, status)
SELECT vehicle_id, 'Preventive service', 'Oil, filters, and brake inspection', 12500, 'open'
FROM fleet.vehicles
WHERE registration_number = 'KA-01-CD-2002'
  AND NOT EXISTS (
      SELECT 1 FROM fleet.maintenance m
      WHERE m.vehicle_id = fleet.vehicles.vehicle_id AND m.status = 'open'
  );
