USE marazul_sucre;

DROP USER IF EXISTS 'usr_operador1'@'%';
DROP USER IF EXISTS 'usr_comercial1'@'%';
DROP USER IF EXISTS 'usr_inspector1'@'%';
DROP ROLE IF EXISTS 'rol_operador_muelle';
DROP ROLE IF EXISTS 'rol_gestor_comercial';
DROP ROLE IF EXISTS 'rol_inspector_aunap';

CREATE ROLE 'rol_operador_muelle';
CREATE ROLE 'rol_gestor_comercial';
CREATE ROLE 'rol_inspector_aunap';

GRANT SELECT, INSERT, UPDATE ON marazul_sucre.fishing_trips TO 'rol_operador_muelle';
GRANT SELECT, INSERT, UPDATE ON marazul_sucre.catches       TO 'rol_operador_muelle';

GRANT SELECT, INSERT, UPDATE ON marazul_sucre.sales        TO 'rol_gestor_comercial';
GRANT SELECT, INSERT, UPDATE ON marazul_sucre.sale_details TO 'rol_gestor_comercial';

GRANT SELECT ON marazul_sucre.fishing_trips TO 'rol_inspector_aunap';
GRANT SELECT ON marazul_sucre.catches       TO 'rol_inspector_aunap';
GRANT SELECT ON marazul_sucre.species       TO 'rol_inspector_aunap';

GRANT DELETE ON marazul_sucre.sales TO 'rol_gestor_comercial';

SELECT grantee, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'marazul_sucre'
  AND table_name = 'sales'
  AND privilege_type = 'DELETE'
  AND grantee LIKE '%rol_gestor_comercial%';

REVOKE DELETE ON marazul_sucre.sales FROM 'rol_gestor_comercial';

SELECT grantee, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'marazul_sucre'
  AND table_name = 'sales'
  AND privilege_type = 'DELETE'
  AND grantee LIKE '%rol_gestor_comercial%';

CREATE USER 'usr_operador1'@'%'  IDENTIFIED BY 'Muelle#Op1_2026';
CREATE USER 'usr_comercial1'@'%' IDENTIFIED BY 'Ventas#Com1_2026';
CREATE USER 'usr_inspector1'@'%' IDENTIFIED BY 'Aunap#Insp1_2026';

GRANT 'rol_operador_muelle'  TO 'usr_operador1'@'%';
GRANT 'rol_gestor_comercial' TO 'usr_comercial1'@'%';
GRANT 'rol_inspector_aunap'  TO 'usr_inspector1'@'%';

SET DEFAULT ROLE 'rol_operador_muelle'  TO 'usr_operador1'@'%';
SET DEFAULT ROLE 'rol_gestor_comercial' TO 'usr_comercial1'@'%';
SET DEFAULT ROLE 'rol_inspector_aunap'  TO 'usr_inspector1'@'%';

SHOW GRANTS FOR 'usr_operador1'@'%'  USING 'rol_operador_muelle';
SHOW GRANTS FOR 'usr_comercial1'@'%' USING 'rol_gestor_comercial';
SHOW GRANTS FOR 'usr_inspector1'@'%' USING 'rol_inspector_aunap';
