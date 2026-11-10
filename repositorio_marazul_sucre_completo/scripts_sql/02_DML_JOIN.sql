SET NAMES utf8mb4;
USE marazul_sucre;

SELECT
    CONCAT(f.first_names, ' ', f.last_names) AS `Nombre del Pescador`,
    f.document_number                        AS `Documento`,
    v.name                                   AS `Nombre de la Embarcación`,
    z.name                                   AS `Nombre de la Zona de Pesca`,
    t.departure_at                           AS `Fecha de Salida`,
    t.status                                 AS `Estado de la Jornada`
FROM fishermen      AS f
INNER JOIN trip_crew     AS tc ON tc.fisherman_id = f.fisherman_id
INNER JOIN fishing_trips AS t  ON t.trip_id       = tc.trip_id
INNER JOIN vessels       AS v  ON v.vessel_id     = t.vessel_id
INNER JOIN fishing_zones AS z  ON z.zone_id       = t.zone_id
ORDER BY t.departure_at DESC, `Nombre del Pescador`;

SELECT
    YEAR(t.return_at)                           AS `Año`,
    MONTH(t.return_at)                          AS `Mes`,
    s.common_name                               AS `Especie`,
    ROUND(SUM(c.weight_kg), 2)                  AS `Volumen Total (kg)`,
    ROUND(SUM(c.weight_kg) / SUM(c.piece_count), 3) AS `Peso Promedio por Pieza (kg)`
FROM catches       AS c
INNER JOIN species       AS s ON s.species_id = c.species_id
INNER JOIN fishing_trips AS t ON t.trip_id    = c.trip_id
WHERE t.return_at IS NOT NULL
GROUP BY YEAR(t.return_at), MONTH(t.return_at), s.species_id, s.common_name
ORDER BY `Año` ASC, `Mes` ASC, `Volumen Total (kg)` DESC;

SELECT
    z.name                                         AS `Nombre de la Zona`,
    s.common_name                                  AS `Nombre de la Especie`,
    ROUND(SUM(c.weight_kg), 2)                     AS `Kilos Totales Capturados`,
    ROUND(SUM(COALESCE(sold.sold_kg, 0)), 2)       AS `Kilos Totales Vendidos`,
    ROUND(SUM(COALESCE(sold.sold_kg, 0)) / SUM(c.weight_kg) * 100, 2)
                                                   AS `Porcentaje de Venta (%)`
FROM fishing_zones AS z
INNER JOIN fishing_trips AS t ON t.zone_id    = z.zone_id
INNER JOIN catches       AS c ON c.trip_id    = t.trip_id
INNER JOIN species       AS s ON s.species_id = c.species_id
LEFT  JOIN (
        SELECT d.catch_id, SUM(d.sold_weight_kg) AS sold_kg
        FROM sale_details AS d
        INNER JOIN sales  AS sa ON sa.sale_id = d.sale_id
        WHERE sa.status <> 'ANULADA'
        GROUP BY d.catch_id
     ) AS sold ON sold.catch_id = c.catch_id
WHERE t.status = 'FINALIZADA'
GROUP BY z.zone_id, z.name, s.species_id, s.common_name
ORDER BY `Porcentaje de Venta (%)` DESC, `Kilos Totales Capturados` DESC;

SELECT
    t.trip_id                                AS `Jornada`,
    t.status                                 AS `Estado`,
    v.name                                   AS `Embarcación`,
    COUNT(c.catch_id)                        AS `Número de Capturas`,
    COALESCE(SUM(c.weight_kg), 0)            AS `Kilos Capturados`
FROM fishing_trips AS t
INNER JOIN vessels AS v ON v.vessel_id = t.vessel_id
LEFT  JOIN catches AS c ON c.trip_id   = t.trip_id
GROUP BY t.trip_id, t.status, v.name
ORDER BY `Kilos Capturados` ASC, t.trip_id;

SELECT
    b.buyer_id                               AS `Comprador`,
    b.name                                   AS `Nombre`,
    b.buyer_type                             AS `Tipo`,
    COUNT(s.sale_id)                         AS `Número de Ventas`
FROM sales AS s
RIGHT JOIN buyers AS b ON b.buyer_id = s.buyer_id
GROUP BY b.buyer_id, b.name, b.buyer_type
ORDER BY `Número de Ventas` ASC, b.name;

SELECT
    s1.habitat_type                          AS `Hábitat`,
    s1.common_name                           AS `Especie 1`,
    s2.common_name                           AS `Especie 2`
FROM species AS s1
INNER JOIN species AS s2
        ON s2.habitat_type = s1.habitat_type
       AND s1.species_id   < s2.species_id
ORDER BY s1.habitat_type, s1.common_name, s2.common_name;

SELECT
    z.name                                   AS `Zona de Pesca`,
    g.name                                   AS `Arte de Pesca`,
    COUNT(tg.trip_id)                        AS `Jornadas`
FROM fishing_zones AS z
CROSS JOIN fishing_gears AS g
LEFT  JOIN fishing_trips AS t  ON t.zone_id  = z.zone_id
LEFT  JOIN trip_gears    AS tg ON tg.trip_id = t.trip_id
                              AND tg.gear_id = g.gear_id
GROUP BY z.zone_id, z.name, g.gear_id, g.name
ORDER BY z.name, `Jornadas` DESC, g.name;
