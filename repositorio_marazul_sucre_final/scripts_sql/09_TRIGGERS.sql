USE marazul_sucre;

DROP TRIGGER IF EXISTS tr_initialize_available_weight;

DELIMITER $$

CREATE TRIGGER tr_initialize_available_weight
BEFORE INSERT ON catches
FOR EACH ROW
BEGIN
    SET NEW.available_weight_kg = NEW.weight_kg;
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS tr_prevent_negative_available_weight;

DELIMITER $$

CREATE TRIGGER tr_prevent_negative_available_weight
BEFORE UPDATE ON catches
FOR EACH ROW
BEGIN
    IF NEW.available_weight_kg < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Available catch weight cannot be negative.';
    END IF;
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS tr_audit_catch_changes;

DELIMITER $$

CREATE TRIGGER tr_audit_catch_changes
AFTER UPDATE ON catches
FOR EACH ROW
BEGIN
    IF NOT (OLD.weight_kg <=> NEW.weight_kg)
       OR NOT (OLD.available_weight_kg <=> NEW.available_weight_kg) THEN
        INSERT INTO catch_audit (
            changed_at,
            db_user,
            catch_id,
            old_weight,
            new_weight,
            old_available,
            new_available
        )
        VALUES (
            CURRENT_TIMESTAMP,
            CURRENT_USER(),
            OLD.catch_id,
            OLD.weight_kg,
            NEW.weight_kg,
            OLD.available_weight_kg,
            NEW.available_weight_kg
        );
    END IF;
END$$

DELIMITER ;

DROP TABLE IF EXISTS sales_audit;

CREATE TABLE sales_audit (
    audit_id        INT           NOT NULL AUTO_INCREMENT,
    changed_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    db_user         VARCHAR(288)  NOT NULL,
    sale_detail_id  INT           NOT NULL,
    old_weight_kg   DECIMAL(8,2)  NULL,
    new_weight_kg   DECIMAL(8,2)  NULL,
    old_unit_price  DECIMAL(10,2) NULL,
    new_unit_price  DECIMAL(10,2) NULL,
    CONSTRAINT pk_sales_audit PRIMARY KEY (audit_id),
    INDEX idx_sales_audit_sale_detail_id (sale_detail_id)
) ENGINE = InnoDB;

DROP TRIGGER IF EXISTS tr_audit_sale_detail_changes;

DELIMITER $$

CREATE TRIGGER tr_audit_sale_detail_changes
AFTER UPDATE ON sale_details
FOR EACH ROW
BEGIN
    IF NOT (OLD.sold_weight_kg <=> NEW.sold_weight_kg)
       OR NOT (OLD.unit_price <=> NEW.unit_price) THEN
        INSERT INTO sales_audit (
            changed_at,
            db_user,
            sale_detail_id,
            old_weight_kg,
            new_weight_kg,
            old_unit_price,
            new_unit_price
        )
        VALUES (
            CURRENT_TIMESTAMP,
            CURRENT_USER(),
            OLD.detail_id,
            OLD.sold_weight_kg,
            NEW.sold_weight_kg,
            OLD.unit_price,
            NEW.unit_price
        );
    END IF;
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS tr_prevent_sales_audit_update;
DROP TRIGGER IF EXISTS tr_prevent_sales_audit_delete;

DELIMITER $$

CREATE TRIGGER tr_prevent_sales_audit_update
BEFORE UPDATE ON sales_audit
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'sales_audit is immutable: updates are not allowed.';
END$$

CREATE TRIGGER tr_prevent_sales_audit_delete
BEFORE DELETE ON sales_audit
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'sales_audit is immutable: deletes are not allowed.';
END$$

DELIMITER ;

START TRANSACTION;
INSERT INTO catches (species_id, trip_id, weight_kg, piece_count, avg_size_cm, available_weight_kg)
VALUES (1, 266, 42.50, 30, 55.0, 0.00);
SELECT catch_id, weight_kg, available_weight_kg
FROM catches
WHERE catch_id = LAST_INSERT_ID();
ROLLBACK;

START TRANSACTION;
UPDATE catches
SET available_weight_kg = available_weight_kg - 1.00
WHERE catch_id = 355;
SELECT * FROM catch_audit ORDER BY audit_id DESC LIMIT 1;
ROLLBACK;

SELECT detail_id, sold_weight_kg, unit_price FROM sale_details WHERE detail_id = 1;
UPDATE sale_details SET unit_price = unit_price + 1000.00 WHERE detail_id = 1;
UPDATE sale_details SET unit_price = unit_price - 1000.00 WHERE detail_id = 1;
SELECT * FROM sales_audit ORDER BY audit_id DESC;

UPDATE catches SET available_weight_kg = -5.00 WHERE catch_id = 1;

UPDATE sales_audit SET new_unit_price = 0.00 WHERE audit_id = 1;

DELETE FROM sales_audit WHERE audit_id = 1;
