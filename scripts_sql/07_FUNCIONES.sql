USE marazul_sucre;

DROP FUNCTION IF EXISTS fn_get_species_availability;

DELIMITER $$

CREATE FUNCTION fn_get_species_availability(
    p_species_id INT
)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_available_weight DECIMAL(12,2) DEFAULT 0.00;

    SELECT COALESCE(SUM(available_weight_kg), 0.00)
      INTO v_available_weight
    FROM catches
    WHERE species_id = p_species_id;

    RETURN COALESCE(v_available_weight, 0.00);
END$$

DELIMITER ;

SELECT fn_get_species_availability(1)   AS available_weight_kg;
SELECT fn_get_species_availability(999) AS available_weight_kg;

DROP FUNCTION IF EXISTS fn_calculate_trip_efficiency;

DELIMITER $$

CREATE FUNCTION fn_calculate_trip_efficiency(
    p_trip_id INT
)
RETURNS DECIMAL(7,2)
READS SQL DATA
BEGIN
    DECLARE v_total_caught    DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_vessel_capacity DECIMAL(8,2)  DEFAULT 0.00;

    SELECT
        COALESCE(SUM(c.weight_kg), 0.00),
        COALESCE(MAX(v.load_capacity_kg), 0.00)
      INTO v_total_caught, v_vessel_capacity
    FROM fishing_trips AS ft
    INNER JOIN vessels AS v
        ON v.vessel_id = ft.vessel_id
    LEFT JOIN catches AS c
        ON c.trip_id = ft.trip_id
    WHERE ft.trip_id = p_trip_id;

    IF v_vessel_capacity <= 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND((v_total_caught / v_vessel_capacity) * 100, 2);
END$$

DELIMITER ;

SELECT fn_calculate_trip_efficiency(1) AS trip_efficiency_percentage;

DROP FUNCTION IF EXISTS fn_validate_catch_size;

DELIMITER $$

CREATE FUNCTION fn_validate_catch_size(
    p_species_id      INT,
    p_average_size_cm DECIMAL(5,1)
)
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
    DECLARE v_minimum_size  DECIMAL(5,1) DEFAULT NULL;
    DECLARE v_species_found TINYINT      DEFAULT 1;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_species_found = 0;

    IF p_average_size_cm IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Average size must be provided.';
    END IF;

    SELECT min_size_cm
      INTO v_minimum_size
    FROM species
    WHERE species_id = p_species_id;

    IF v_species_found = 0 THEN
        RETURN 'ESPECIE_NO_REGISTRADA';
    END IF;

    IF p_average_size_cm < v_minimum_size THEN
        RETURN 'VIOLACION_VEDA';
    END IF;

    RETURN 'PERMITIDO';
END$$

DELIMITER ;

SELECT fn_validate_catch_size(1, 30.0)  AS size_validation_result;
SELECT fn_validate_catch_size(1, 60.0)  AS size_validation_result;
SELECT fn_validate_catch_size(999, 60.0) AS size_validation_result;
