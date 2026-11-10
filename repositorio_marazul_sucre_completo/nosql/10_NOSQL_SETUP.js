use marazul_sucre

db.trip_logs.drop()

db.createCollection("trip_logs", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["trip_id", "status", "log_date", "vessel", "zone", "responsible", "notes"],
      properties: {
        trip_id: { bsonType: ["int", "long", "double"], minimum: 1 },
        status: { enum: ["FINALIZADA", "CANCELADA"] },
        log_date: { bsonType: "date" },
        vessel: { bsonType: "object", required: ["vessel_id", "name"] },
        zone: {
          bsonType: "object",
          required: ["zone_id", "name", "zone_type"],
          properties: {
            zone_type: { enum: ["GOLFO", "MAR_ABIERTO", "CIENAGA", "RIO", "MANGLAR", "ESTANQUE"] }
          }
        },
        responsible: { bsonType: "object", required: ["fisherman_id", "full_name"] },
        incidents: {
          bsonType: "array",
          items: { bsonType: "object", required: ["type"], properties: { type: { bsonType: "string" } } }
        },
        notes: { bsonType: "string", minLength: 10 }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
})

db.trip_logs.createIndex({ trip_id: 1 }, { unique: true, name: "uq_trip_logs_trip_id" })

db.trip_logs.createIndex({ "zone.zone_type": 1, log_date: -1 }, { name: "idx_trip_logs_zone_type_date" })

db.trip_logs.createIndex({ "incidents.type": 1 }, { name: "idx_trip_logs_incident_type" })

db.trip_logs.createIndex({ notes: "text" }, { name: "txt_trip_logs_notes", default_language: "spanish" })

db.trip_logs.getIndexes()
