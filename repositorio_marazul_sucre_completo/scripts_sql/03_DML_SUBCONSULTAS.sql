SET NAMES utf8mb4;
USE marazul_sucre;

SELECT
    c.catch_id          AS `Código de Captura`,
    s.common_name       AS `Especie`,
    c.landed_at         AS `Fecha de Desembarque`,
    c.weight_kg         AS `Peso (kg)`
FROM catches AS c
INNER JOIN species AS s ON s.species_id = c.species_id
WHERE NOT EXISTS (
        SELECT 1
        FROM sale_details AS d
        WHERE d.catch_id = c.catch_id
      )
ORDER BY c.landed_at DESC, c.catch_id;

SELECT
    s.common_name                  AS `Especie`,
    ROUND(SUM(c.weight_kg), 2)     AS `Volumen Total (kg)`
FROM catches AS c
INNER JOIN species AS s ON s.species_id = c.species_id
GROUP BY s.species_id, s.common_name
HAVING SUM(c.weight_kg) > (
        SELECT AVG(por_especie.total_kg)
        FROM (
            SELECT SUM(weight_kg) AS total_kg
            FROM catches
            GROUP BY species_id
        ) AS por_especie
      )
ORDER BY `Volumen Total (kg)` DESC;

SELECT ROUND(AVG(total_kg), 2) AS `Promedio de kg por especie`
FROM (SELECT SUM(weight_kg) AS total_kg FROM catches GROUP BY species_id) AS x;

SELECT
    t.trip_id                       AS `id_jornada`,
    t.zone_id                       AS `id_zona`,
    ROUND(SUM(c.weight_kg), 2)      AS `Total kg capturados`
FROM fishing_trips AS t
INNER JOIN catches AS c ON c.trip_id = t.trip_id
GROUP BY t.trip_id, t.zone_id
HAVING SUM(c.weight_kg) > (
        SELECT SUM(c2.weight_kg) / COUNT(DISTINCT t2.trip_id)
        FROM fishing_trips AS t2
        INNER JOIN catches AS c2 ON c2.trip_id = t2.trip_id
        WHERE t2.zone_id = t.zone_id
      )
ORDER BY t.zone_id, `Total kg capturados` DESC;

SELECT
    jt.trip_id                      AS `id_jornada`,
    jt.zone_id                      AS `id_zona`,
    ROUND(jt.total_kg, 2)           AS `Total kg capturados`
FROM (
        SELECT t.trip_id, t.zone_id, SUM(c.weight_kg) AS total_kg
        FROM fishing_trips AS t
        INNER JOIN catches AS c ON c.trip_id = t.trip_id
        GROUP BY t.trip_id, t.zone_id
     ) AS jt
INNER JOIN (
        SELECT zone_id, AVG(total_kg) AS avg_kg
        FROM (
            SELECT t.trip_id, t.zone_id, SUM(c.weight_kg) AS total_kg
            FROM fishing_trips AS t
            INNER JOIN catches AS c ON c.trip_id = t.trip_id
            GROUP BY t.trip_id, t.zone_id
        ) AS x
        GROUP BY zone_id
     ) AS za ON za.zone_id = jt.zone_id
WHERE jt.total_kg > za.avg_kg
ORDER BY jt.zone_id, `Total kg capturados` DESC;

SELECT v.vessel_id AS `Embarcación`, v.name AS `Nombre`, v.vessel_type AS `Tipo`
FROM vessels AS v
WHERE v.vessel_id IN (
        SELECT t.vessel_id
        FROM fishing_trips AS t
        WHERE t.zone_id IN (
                SELECT z.zone_id
                FROM fishing_zones AS z
                WHERE z.zone_type IN ('MAR_ABIERTO', 'GOLFO')
              )
      )
ORDER BY v.name;

SELECT c.catch_id AS `Captura`, s.common_name AS `Especie`, c.weight_kg AS `Peso (kg)`
FROM catches AS c
INNER JOIN species AS s ON s.species_id = c.species_id
WHERE c.weight_kg > ALL (
        SELECT AVG(weight_kg) FROM catches GROUP BY species_id
      )
ORDER BY c.weight_kg DESC;

SELECT b.buyer_id AS `Comprador`, b.name AS `Nombre`, b.buyer_type AS `Tipo`
FROM buyers AS b
WHERE EXISTS (
        SELECT 1
        FROM sales AS sa
        INNER JOIN sale_details AS d ON d.sale_id  = sa.sale_id
        INNER JOIN catches      AS c ON c.catch_id = d.catch_id
        INNER JOIN species      AS s ON s.species_id = c.species_id
        WHERE sa.buyer_id = b.buyer_id
          AND sa.status   = 'PAGADA'
          AND s.common_name = 'Langosta espinosa'
      )
ORDER BY b.name;

SELECT
    o.name                                             AS `Organización`,
    org.total_kg                                       AS `Kilos Capturados`,
    ROUND(org.total_kg / (SELECT SUM(weight_kg) FROM catches) * 100, 2)
                                                       AS `% del Total`
FROM (
        SELECT v.organization_id, ROUND(SUM(c.weight_kg), 2) AS total_kg
        FROM vessels AS v
        INNER JOIN fishing_trips AS t ON t.vessel_id = v.vessel_id
        INNER JOIN catches       AS c ON c.trip_id   = t.trip_id
        GROUP BY v.organization_id
     ) AS org
INNER JOIN organizations AS o ON o.organization_id = org.organization_id
ORDER BY org.total_kg DESC;
