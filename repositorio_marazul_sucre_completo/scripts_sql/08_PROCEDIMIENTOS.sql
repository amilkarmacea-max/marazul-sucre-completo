USE marazul_sucre;

DROP PROCEDURE IF EXISTS pr_register_catch;

DELIMITER $$

CREATE PROCEDURE pr_register_catch(
    IN p_trip_id     INT,
    IN p_species_id  INT,
    IN p_weight_kg   DECIMAL(8,2),
    IN p_piece_count INT
)
BEGIN
    DECLARE v_trip_status VARCHAR(12) DEFAULT NULL;

    IF p_weight_kg IS NULL OR p_weight_kg <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Catch weight must be greater than zero.';
    END IF;

    IF p_piece_count IS NULL OR p_piece_count <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Piece count must be greater than zero.';
    END IF;

    SELECT status
      INTO v_trip_status
    FROM fishing_trips
    WHERE trip_id = p_trip_id;

    IF v_trip_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Fishing trip was not found.';
    END IF;

    IF v_trip_status <> 'EN_CURSO' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Catches can only be registered for a trip in progress.';
    END IF;

    INSERT INTO catches (
        species_id,
        trip_id,
        weight_kg,
        piece_count,
        avg_size_cm,
        available_weight_kg,
        landed_at
    )
    VALUES (
        p_species_id,
        p_trip_id,
        p_weight_kg,
        p_piece_count,
        NULL,
        p_weight_kg,
        CURRENT_TIMESTAMP
    );
END$$

DELIMITER ;

START TRANSACTION;
CALL pr_register_catch(266, 1, 50.00, 10);
SELECT catch_id, trip_id, species_id, weight_kg, available_weight_kg, landed_at
FROM catches
WHERE catch_id = LAST_INSERT_ID();
ROLLBACK;

DROP PROCEDURE IF EXISTS pr_dispatch_catch;

DELIMITER $$

CREATE PROCEDURE pr_dispatch_catch(
    IN p_sale_id        INT,
    IN p_catch_id       INT,
    IN p_weight_to_sell DECIMAL(8,2),
    IN p_unit_price     DECIMAL(10,2)
)
BEGIN
    DECLARE v_available_weight DECIMAL(8,2) DEFAULT NULL;
    DECLARE v_not_found        TINYINT      DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_not_found = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_weight_to_sell IS NULL OR p_weight_to_sell <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Sale weight must be greater than zero.';
    END IF;

    IF p_unit_price IS NULL OR p_unit_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Unit price must be greater than zero.';
    END IF;

    START TRANSACTION;

    SELECT available_weight_kg
      INTO v_available_weight
    FROM catches
    WHERE catch_id = p_catch_id
    FOR UPDATE;

    IF v_not_found = 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Catch record was not found.';
    END IF;

    IF p_weight_to_sell > v_available_weight THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient available catch weight.';
    END IF;

    INSERT INTO sale_details (sale_id, catch_id, sold_weight_kg, unit_price)
    VALUES (p_sale_id, p_catch_id, p_weight_to_sell, p_unit_price);

    UPDATE catches
    SET available_weight_kg = available_weight_kg - p_weight_to_sell
    WHERE catch_id = p_catch_id;

    COMMIT;
END$$

DELIMITER ;

SELECT catch_id, available_weight_kg FROM catches WHERE catch_id = 355;
CALL pr_dispatch_catch(258, 355, 5.00, 26000.00);
SELECT catch_id, available_weight_kg FROM catches WHERE catch_id = 355;
SELECT detail_id, sale_id, catch_id, sold_weight_kg, unit_price, subtotal
FROM sale_details
WHERE sale_id = 258 AND catch_id = 355;

DROP PROCEDURE IF EXISTS pr_process_complete_sale;

DELIMITER $$

CREATE PROCEDURE pr_process_complete_sale(
    IN  p_buyer_id       INT,
    IN  p_employee_id    INT,
    IN  p_catch_id       INT,
    IN  p_weight_to_sell DECIMAL(8,2),
    IN  p_unit_price     DECIMAL(10,2),
    OUT p_result_code    INT
)
BEGIN
    DECLARE v_buyer_count      INT          DEFAULT 0;
    DECLARE v_available_weight DECIMAL(8,2) DEFAULT NULL;
    DECLARE v_sale_id          INT          DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result_code = -2;
    END;

    SET p_result_code = -2;

    SELECT COUNT(*)
      INTO v_buyer_count
    FROM buyers
    WHERE buyer_id = p_buyer_id;

    IF v_buyer_count = 0
       OR p_weight_to_sell IS NULL OR p_weight_to_sell <= 0
       OR p_unit_price IS NULL OR p_unit_price <= 0 THEN
        SET p_result_code = -2;
    ELSE
        START TRANSACTION;

        SELECT available_weight_kg
          INTO v_available_weight
        FROM catches
        WHERE catch_id = p_catch_id
        FOR UPDATE;

        IF v_available_weight IS NULL THEN
            ROLLBACK;
            SET p_result_code = -2;
        ELSEIF p_weight_to_sell > v_available_weight THEN
            ROLLBACK;
            SET p_result_code = -1;
        ELSE
            INSERT INTO sales (buyer_id, employee_id, sale_date, status)
            VALUES (p_buyer_id, p_employee_id, CURRENT_TIMESTAMP, 'REGISTRADA');

            SET v_sale_id = LAST_INSERT_ID();

            INSERT INTO sale_details (sale_id, catch_id, sold_weight_kg, unit_price)
            VALUES (v_sale_id, p_catch_id, p_weight_to_sell, p_unit_price);

            UPDATE catches
            SET available_weight_kg = available_weight_kg - p_weight_to_sell
            WHERE catch_id = p_catch_id;

            COMMIT;
            SET p_result_code = 0;
        END IF;
    END IF;
END$$

DELIMITER ;

SET @result_code = NULL;
CALL pr_process_complete_sale(1, 16, 534, 5.00, 32000.00, @result_code);
SELECT @result_code AS result_code;
SELECT s.sale_id, s.buyer_id, s.sale_date, d.catch_id, d.sold_weight_kg, d.subtotal
FROM sales AS s
INNER JOIN sale_details AS d ON d.sale_id = s.sale_id
ORDER BY s.sale_id DESC
LIMIT 1;

CALL pr_process_complete_sale(1, 16, 534, 99999.00, 32000.00, @result_code);
SELECT @result_code AS result_code;

CALL pr_process_complete_sale(99999, 16, 534, 5.00, 32000.00, @result_code);
SELECT @result_code AS result_code;

CALL pr_register_catch(266, 1, 0.00, 10);

CALL pr_dispatch_catch(258, 355, 99999.00, 26000.00);
