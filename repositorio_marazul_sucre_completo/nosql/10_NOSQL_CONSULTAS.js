use marazul_sucre

db.trip_logs.countDocuments()

db.trip_logs.aggregate([
  { $group: { _id: { zone_type: "$zone.zone_type", status: "$status" }, logs: { $sum: 1 } } },
  { $sort: { "_id.zone_type": 1, "_id.status": 1 } }
])

db.trip_logs.findOne({ trip_id: 109 }, { _id: 0 })

db.trip_logs.aggregate([
  { $match: { status: "FINALIZADA" } },
  { $project: { zone_type: "$zone.zone_type", fields: { $objectToArray: "$$ROOT" } } },
  { $unwind: "$fields" },
  { $group: { _id: "$zone_type", fields: { $addToSet: "$fields.k" } } },
  { $project: { specific_fields: { $setDifference: ["$fields", ["_id", "trip_id", "status", "log_date", "vessel", "zone", "responsible", "crew_size", "gears", "weather", "incidents", "notes", "tags"]] } } },
  { $sort: { _id: 1 } }
])

db.trip_logs.find(
  { "sea.wave_height_m": { $gte: 1.5 }, "incidents.type": "REGRESO_ANTICIPADO" },
  { _id: 0, trip_id: 1, "zone.name": 1, log_date: 1, "sea.wave_height_m": 1, "weather.wind_knots": 1 }
).sort({ "sea.wave_height_m": -1 })

db.trip_logs.find(
  { "zone.zone_type": "ESTANQUE", "pond.dissolved_oxygen_mg_l": { $lt: 4 } },
  { _id: 0, trip_id: 1, log_date: 1, "pond.pond_code": 1, "pond.dissolved_oxygen_mg_l": 1, "pond.mortality_count": 1 }
).sort({ "pond.dissolved_oxygen_mg_l": 1 })

db.trip_logs.aggregate([
  { $unwind: "$incidents" },
  { $match: { "incidents.type": "AVISTAMIENTO" } },
  { $group: { _id: { zone_type: "$zone.zone_type", species: "$incidents.species" }, sightings: { $sum: 1 }, individuals: { $sum: "$incidents.count" } } },
  { $sort: { "_id.zone_type": 1, sightings: -1 } }
])

db.trip_logs.aggregate([
  { $match: { $text: { $search: "tormenta" } } },
  { $sort: { score: { $meta: "textScore" } } },
  { $limit: 5 },
  { $project: { _id: 0, trip_id: 1, "zone.name": 1, score: { $round: [{ $meta: "textScore" }, 3] }, notes: { $split: ["$notes", ". "] } } }
])

db.trip_logs.aggregate([
  { $unwind: "$incidents" },
  { $match: { "incidents.type": "FALLA_MECANICA", "incidents.hours_lost": { $ne: null } } },
  { $group: { _id: { zone_type: "$zone.zone_type", component: "$incidents.component" }, failures: { $sum: 1 }, hours_lost: { $sum: "$incidents.hours_lost" } } },
  { $project: { failures: 1, hours_lost: { $round: ["$hours_lost", 1] } } },
  { $sort: { hours_lost: -1 } }
])

db.trip_logs.updateOne(
  { trip_id: 251 },
  { $push: { incidents: { type: "COLOR_ANOMALO_DEL_AGUA", color: "pardo rojizo", extent_ha: 3.5, dead_fish_seen: true } } }
)

db.trip_logs.find(
  { "incidents.type": "COLOR_ANOMALO_DEL_AGUA" },
  { _id: 0, trip_id: 1, "zone.name": 1, log_date: 1, incidents: { $elemMatch: { type: "COLOR_ANOMALO_DEL_AGUA" } } }
)

db.trip_logs.aggregate([
  { $unwind: "$incidents" },
  { $group: { _id: "$incidents.type", total: { $sum: 1 } } },
  { $sort: { total: -1 } }
])

db.trip_logs.find({ "incidents.type": "FALLA_MECANICA" }).explain("executionStats").queryPlanner.winningPlan
