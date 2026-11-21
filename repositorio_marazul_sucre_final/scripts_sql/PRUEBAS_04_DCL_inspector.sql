SELECT CURRENT_USER() AS cuenta, CURRENT_ROLE() AS rol_activo;
SELECT COUNT(*) AS capturas_visibles FROM catches;
SELECT species_id, common_name FROM species LIMIT 3;
INSERT INTO species (common_name, scientific_name, min_size_cm, habitat_type, organoleptic_description) VALUES ('Prueba', 'Prueba prueba', 10, 'MARINO', 'x');
UPDATE catches SET weight_kg = weight_kg WHERE catch_id = 1;
DELETE FROM fishing_trips WHERE trip_id = 1;
SELECT COUNT(*) FROM sales;
