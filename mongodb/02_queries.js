// FleetMonitor Stage 3 query examples.
db = db.getSiblingDB("fleet_monitor");

// Latest GPS point for each vehicle.
db.gps_locations.aggregate([
  { $sort: { recorded_at: -1 } },
  { $group: { _id: "$vehicle_id", latest: { $first: "$$ROOT" } } }
]);

// Vehicles currently near Bengaluru (longitude, latitude order).
db.gps_locations.find({
  location: {
    $near: {
      $geometry: { type: "Point", coordinates: [77.5946, 12.9716] },
      $maxDistance: 50000
    }
  }
});

// Maintenance cost by vehicle.
db.maintenance_logs.aggregate([
  { $unwind: "$parts" },
  { $group: {
      _id: "$vehicle_id",
      total_cost: { $sum: { $multiply: ["$parts.quantity", "$parts.unit_cost"] } }
  } }
]);
