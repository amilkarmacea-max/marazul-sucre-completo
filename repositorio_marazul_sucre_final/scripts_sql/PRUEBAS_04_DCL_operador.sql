SELECT CURRENT_USER() AS cuenta, CURRENT_ROLE() AS rol_activo;
START TRANSACTION;
INSERT INTO fishing_trips (vessel_id, zone_id, coordinator_id, departure_at) VALUES (1, 1, 1, '2026-11-12 05:00:00');
UPDATE catches SET piece_count = piece_count + 1 WHERE catch_id = 1;
SELECT COUNT(*) AS jornadas_en_la_transaccion FROM fishing_trips;
ROLLBACK;
DELETE FROM catches WHERE catch_id = 1;
SELECT COUNT(*) FROM sales;
INSERT INTO sale_details (sale_id, catch_id, sold_weight_kg, unit_price) VALUES (1, 1, 1, 1000);
