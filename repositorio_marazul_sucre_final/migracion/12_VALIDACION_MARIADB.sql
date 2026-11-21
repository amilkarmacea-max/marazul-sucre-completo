USE marazul_sucre;

SELECT 'buyers' AS tabla, COUNT(*) AS filas FROM buyers
UNION ALL
SELECT 'catch_audit' AS tabla, COUNT(*) AS filas FROM catch_audit
UNION ALL
SELECT 'catches' AS tabla, COUNT(*) AS filas FROM catches
UNION ALL
SELECT 'collection_centers' AS tabla, COUNT(*) AS filas FROM collection_centers
UNION ALL
SELECT 'countries' AS tabla, COUNT(*) AS filas FROM countries
UNION ALL
SELECT 'departments' AS tabla, COUNT(*) AS filas FROM departments
UNION ALL
SELECT 'employees' AS tabla, COUNT(*) AS filas FROM employees
UNION ALL
SELECT 'fishermen' AS tabla, COUNT(*) AS filas FROM fishermen
UNION ALL
SELECT 'fishing_gears' AS tabla, COUNT(*) AS filas FROM fishing_gears
UNION ALL
SELECT 'fishing_trips' AS tabla, COUNT(*) AS filas FROM fishing_trips
UNION ALL
SELECT 'fishing_zones' AS tabla, COUNT(*) AS filas FROM fishing_zones
UNION ALL
SELECT 'maritime_areas' AS tabla, COUNT(*) AS filas FROM maritime_areas
UNION ALL
SELECT 'municipalities' AS tabla, COUNT(*) AS filas FROM municipalities
UNION ALL
SELECT 'organizations' AS tabla, COUNT(*) AS filas FROM organizations
UNION ALL
SELECT 'quality_inspections' AS tabla, COUNT(*) AS filas FROM quality_inspections
UNION ALL
SELECT 'roles' AS tabla, COUNT(*) AS filas FROM roles
UNION ALL
SELECT 'sale_details' AS tabla, COUNT(*) AS filas FROM sale_details
UNION ALL
SELECT 'sales' AS tabla, COUNT(*) AS filas FROM sales
UNION ALL
SELECT 'sales_audit' AS tabla, COUNT(*) AS filas FROM sales_audit
UNION ALL
SELECT 'species' AS tabla, COUNT(*) AS filas FROM species
UNION ALL
SELECT 'species_local_names' AS tabla, COUNT(*) AS filas FROM species_local_names
UNION ALL
SELECT 'trip_crew' AS tabla, COUNT(*) AS filas FROM trip_crew
UNION ALL
SELECT 'trip_gears' AS tabla, COUNT(*) AS filas FROM trip_gears
UNION ALL
SELECT 'users' AS tabla, COUNT(*) AS filas FROM users
UNION ALL
SELECT 'vessels' AS tabla, COUNT(*) AS filas FROM vessels;

SELECT ROUND(SUM(weight_kg),2) AS kg_capturados, ROUND(SUM(available_weight_kg),2) AS kg_disponibles FROM catches;
SELECT ROUND(SUM(subtotal),2) AS total_vendido FROM sale_details;

SELECT COUNT(*) AS filas_vista_disponibles FROM vw_available_catches_at_dock;
SELECT COUNT(*) AS filas_vista_jornadas FROM vw_fishing_trip_summary;
SELECT COUNT(*) AS filas_vista_kpis FROM vw_fish_marketing_kpis;
SELECT fn_get_species_availability(1) AS disponibilidad_especie_1;

UPDATE catches SET available_weight_kg = -1 WHERE catch_id = 1;
INSERT INTO trip_crew (trip_id, fisherman_id, crew_role) VALUES (1, 2, 'RESPONSABLE');
UPDATE sales_audit SET db_user = 'x' LIMIT 1;
