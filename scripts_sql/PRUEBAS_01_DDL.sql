USE marazul_sucre;

SELECT 'fishermen' AS tabla, COUNT(*) AS registros FROM fishermen
UNION ALL SELECT 'vessels', COUNT(*) FROM vessels
UNION ALL SELECT 'fishing_trips', COUNT(*) FROM fishing_trips
UNION ALL SELECT 'trip_crew', COUNT(*) FROM trip_crew
UNION ALL SELECT 'catches', COUNT(*) FROM catches
UNION ALL SELECT 'quality_inspections', COUNT(*) FROM quality_inspections
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'sale_details', COUNT(*) FROM sale_details
UNION ALL SELECT 'buyers', COUNT(*) FROM buyers;

INSERT INTO quality_inspections (catch_id, employee_id, temperature_c, freshness_level)
VALUES (1, 11, 20.0, 'EXCELENTE');

UPDATE vessels SET autonomy_category = 'OCEANICA' WHERE vessel_id = 1;

UPDATE catches SET available_weight_kg = -1 WHERE catch_id = 1;

INSERT INTO trip_crew (trip_id, fisherman_id, crew_role) VALUES (1, 26, 'RESPONSABLE');

DELETE FROM catches WHERE catch_id = 3;

EXPLAIN ANALYZE
SELECT catch_id, SUM(sold_weight_kg) AS kilos_vendidos
FROM sale_details
WHERE catch_id BETWEEN 1 AND 100
GROUP BY catch_id;
