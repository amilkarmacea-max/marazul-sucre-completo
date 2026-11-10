SET NAMES utf8mb4;
USE marazul_sucre;

SELECT @@autocommit AS `autocommit (1 = activo)`;

SET @buyer_id    = 1;
SET @employee_id = 16;

SELECT catch_id INTO @catch_a1 FROM catches
 WHERE species_id = 7 AND available_weight_kg >= 100 ORDER BY landed_at DESC LIMIT 1;
SELECT catch_id INTO @catch_a2 FROM catches
 WHERE species_id = 5 AND available_weight_kg >= 100 ORDER BY landed_at DESC LIMIT 1;

SELECT catch_id INTO @catch_short FROM catches
 WHERE available_weight_kg BETWEEN 5 AND 20 ORDER BY landed_at DESC LIMIT 1;

SELECT catch_id INTO @catch_sierra FROM catches
 WHERE species_id = 1 AND available_weight_kg >= 50 ORDER BY landed_at DESC LIMIT 1;

SELECT c.catch_id, s.common_name AS species_name, c.weight_kg, c.available_weight_kg
FROM catches AS c INNER JOIN species AS s ON s.species_id = c.species_id
WHERE c.catch_id IN (@catch_a1, @catch_a2, @catch_short, @catch_sierra)
ORDER BY c.catch_id;

START TRANSACTION;

    INSERT INTO sales (buyer_id, employee_id, sale_date, status)
    VALUES (@buyer_id, @employee_id, NOW(), 'REGISTRADA');
    SET @sale_a = LAST_INSERT_ID();

    INSERT INTO sale_details (sale_id, catch_id, sold_weight_kg, unit_price)
    VALUES (@sale_a, @catch_a1, 25.00,  9500.00);

    INSERT INTO sale_details (sale_id, catch_id, sold_weight_kg, unit_price)
    VALUES (@sale_a, @catch_a2, 10.50, 28000.00);

    UPDATE catches SET available_weight_kg = available_weight_kg - 25.00 WHERE catch_id = @catch_a1;
    UPDATE catches SET available_weight_kg = available_weight_kg - 10.50 WHERE catch_id = @catch_a2;

COMMIT;

ROLLBACK;

SELECT sa.sale_id, sa.status, d.detail_id, d.catch_id, d.sold_weight_kg, d.unit_price, d.subtotal
FROM sales AS sa INNER JOIN sale_details AS d ON d.sale_id = sa.sale_id
WHERE sa.sale_id = @sale_a;

SELECT catch_id, weight_kg, available_weight_kg
FROM catches WHERE catch_id IN (@catch_a1, @catch_a2) ORDER BY catch_id;

DROP PROCEDURE IF EXISTS pr_tcl_sell_validated_catch;

DELIMITER $$
CREATE PROCEDURE pr_tcl_sell_validated_catch (
    IN p_buyer_id     INT,
    IN p_employee_id  INT,
    IN p_catch_id     INT,
    IN p_weight_kg    DECIMAL(8,2),
    IN p_price_per_kg DECIMAL(10,2)
)
BEGIN
    DECLARE v_available_kg DECIMAL(8,2) DEFAULT NULL;
    DECLARE v_sale_id      INT;

    START TRANSACTION;

    INSERT INTO sales (buyer_id, employee_id, sale_date, status)
    VALUES (p_buyer_id, p_employee_id, NOW(), 'REGISTRADA');
    SET v_sale_id = LAST_INSERT_ID();

    SELECT available_weight_kg INTO v_available_kg
    FROM catches
    WHERE catch_id = p_catch_id
    FOR UPDATE;

    IF v_available_kg IS NULL THEN
        ROLLBACK;
        SELECT CONCAT('ADVERTENCIA: la captura ', p_catch_id,
                      ' no existe. Venta revertida (ROLLBACK).') AS message;

    ELSEIF p_weight_kg > v_available_kg THEN
        ROLLBACK;
        SELECT CONCAT('ADVERTENCIA: se intentó vender ', p_weight_kg, ' kg de la captura ',
                      p_catch_id, ' y solo hay ', v_available_kg,
                      ' kg disponibles. Venta revertida (ROLLBACK).') AS message;

    ELSE
        INSERT INTO sale_details (sale_id, catch_id, sold_weight_kg, unit_price)
        VALUES (v_sale_id, p_catch_id, p_weight_kg, p_price_per_kg);

        UPDATE catches
        SET available_weight_kg = available_weight_kg - p_weight_kg
        WHERE catch_id = p_catch_id;

        COMMIT;
        SELECT CONCAT('OK: venta ', v_sale_id, ' confirmada (COMMIT). Se vendieron ', p_weight_kg,
                      ' kg; quedan ', v_available_kg - p_weight_kg, ' kg disponibles.') AS message;
    END IF;
END$$
DELIMITER ;

SELECT (SELECT COUNT(*) FROM sales) AS sales_before,
       (SELECT available_weight_kg FROM catches WHERE catch_id = @catch_short) AS available_before;

CALL pr_tcl_sell_validated_catch(@buyer_id, @employee_id, @catch_short, 500.00, 20000.00);

SELECT (SELECT COUNT(*) FROM sales) AS sales_after,
       (SELECT available_weight_kg FROM catches WHERE catch_id = @catch_short) AS available_after;

CALL pr_tcl_sell_validated_catch(@buyer_id, @employee_id, @catch_short, 5.00, 20000.00);
SELECT (SELECT COUNT(*) FROM sales) AS sales_final,
       (SELECT available_weight_kg FROM catches WHERE catch_id = @catch_short) AS available_final;

DROP PROCEDURE IF EXISTS pr_tcl_sell_validated_catch;

START TRANSACTION;

    INSERT INTO sales (buyer_id, employee_id, sale_date, status)
    VALUES (@buyer_id, @employee_id, NOW(), 'REGISTRADA');
    SET @sale_c = LAST_INSERT_ID();

    INSERT INTO sale_details (sale_id, catch_id, sold_weight_kg, unit_price)
    VALUES (@sale_c, @catch_sierra, 50.00, 21500.00);
    UPDATE catches SET available_weight_kg = available_weight_kg - 50.00
    WHERE catch_id = @catch_sierra;

    SAVEPOINT sp_item1;

    INSERT INTO sale_details (sale_id, catch_id, sold_weight_kg, unit_price)
    VALUES (@sale_c, @catch_short, 500.00, 25000.00);

    SELECT d.detail_id, d.catch_id, d.sold_weight_kg, c.available_weight_kg AS available_kg,
           IF(d.sold_weight_kg > c.available_weight_kg,
              'INVÁLIDO: excede lo disponible', 'OK') AS validation
    FROM sale_details AS d INNER JOIN catches AS c ON c.catch_id = d.catch_id
    WHERE d.sale_id = @sale_c;

    ROLLBACK TO SAVEPOINT sp_item1;

    SELECT d.detail_id, d.catch_id, d.sold_weight_kg, d.unit_price, d.subtotal
    FROM sale_details AS d WHERE d.sale_id = @sale_c;

COMMIT;

SELECT sa.sale_id, sa.status, COUNT(d.detail_id) AS line_items, SUM(d.subtotal) AS sale_total
FROM sales AS sa INNER JOIN sale_details AS d ON d.sale_id = sa.sale_id
WHERE sa.sale_id = @sale_c
GROUP BY sa.sale_id, sa.status;

SELECT catch_id, weight_kg, available_weight_kg
FROM catches WHERE catch_id = @catch_sierra;

SELECT c.catch_id,
       c.weight_kg,
       COALESCE(v.sold_kg, 0)                          AS sold_kg,
       c.available_weight_kg                           AS available_kg,
       IF(c.available_weight_kg = c.weight_kg - COALESCE(v.sold_kg, 0),
          'COHERENTE', 'DESCUADRADO')                  AS check_status
FROM catches AS c
LEFT JOIN (SELECT d.catch_id, SUM(d.sold_weight_kg) AS sold_kg
           FROM sale_details AS d
           INNER JOIN sales AS sa ON sa.sale_id = d.sale_id
           WHERE sa.status <> 'ANULADA'
           GROUP BY d.catch_id) AS v ON v.catch_id = c.catch_id
WHERE c.catch_id IN (@catch_a1, @catch_a2, @catch_short, @catch_sierra)
ORDER BY c.catch_id;
