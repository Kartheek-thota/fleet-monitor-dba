// Run with: mongosh mongodb://localhost:27017/fleet_monitor mongodb/01_setup.js
db = db.getSiblingDB("fleet_monitor");

db.gps_locations.drop();
db.maintenance_logs.drop();

db.createCollection("gps_locations", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["vehicle_id", "recorded_at", "location"],
      properties: {
        vehicle_id: { bsonType: ["long", "int", "double", "decimal"] },
        recorded_at: { bsonType: "date" },
        location: {
          bsonType: "object",
          required: ["type", "coordinates"],
          properties: {
            type: { enum: ["Point"] },
            coordinates: { bsonType: "array", minItems: 2, maxItems: 2 }
          }
        },
        speed_kph: { bsonType: ["double", "int", "long", "decimal"], minimum: 0 }
      }
    }
  },
  validationLevel: "strict"
});

db.createCollection("maintenance_logs");

db.gps_locations.createIndex({ vehicle_id: 1, recorded_at: -1 });
db.gps_locations.createIndex({ location: "2dsphere" });
db.maintenance_logs.createIndex({ vehicle_id: 1, opened_at: -1 });

db.gps_locations.insertMany([
  {
    vehicle_id: Long("1"),
    recorded_at: new Date(),
    location: { type: "Point", coordinates: [77.5946, 12.9716] },
    speed_kph: 42.5
  },
  {
    vehicle_id: Long("3"),
    recorded_at: new Date(),
    location: { type: "Point", coordinates: [78.4867, 17.3850] },
    speed_kph: 55.0
  }
]);

db.maintenance_logs.insertOne({
  vehicle_id: Long("2"),
  opened_at: new Date(),
  type: "Preventive service",
  status: "open",
  parts: [{ name: "Engine oil", quantity: 6, unit_cost: 850 }],
  notes: "Replace oil and inspect brakes"
});

print("MongoDB FleetMonitor collections, validation, indexes, and sample documents created.");
