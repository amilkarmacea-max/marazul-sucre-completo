USE marazul_sucre;

CREATE OR REPLACE VIEW vw_available_catches_at_dock AS
SELECT
    c.catch_id            AS catch_code,
    sp.common_name        AS common_species_name,
    c.available_weight_kg AS available_weight_kg,
    c.landed_at           AS landing_date,
    v.name                AS vessel_name
FROM catches AS c
INNER JOIN species AS sp
    ON sp.species_id = c.species_id
INNER JOIN fishing_trips AS ft
    ON ft.trip_id = c.trip_id
INNER JOIN vessels AS v
    ON v.vessel_id = ft.vessel_id
WHERE c.available_weight_kg > 0;

SELECT * FROM vw_available_catches_at_dock;

CREATE OR REPLACE VIEW vw_fishing_trip_summary AS
SELECT
    ft.trip_id                         AS trip_id,
    v.name                             AS vessel_name,
    fz.name                            AS zone_name,
    ft.departure_at                    AS departure_date,
    COALESCE(tc.fisher_count, 0)       AS fisher_count,
    COALESCE(ca.total_caught_kg, 0.00) AS total_caught_kg
FROM fishing_trips AS ft
INNER JOIN vessels AS v
    ON v.vessel_id = ft.vessel_id
INNER JOIN fishing_zones AS fz
    ON fz.zone_id = ft.zone_id
LEFT JOIN (
    SELECT trip_id, COUNT(*) AS fisher_count
    FROM trip_crew
    GROUP BY trip_id
) AS tc
    ON tc.trip_id = ft.trip_id
LEFT JOIN (
    SELECT trip_id, SUM(weight_kg) AS total_caught_kg
    FROM catches
    GROUP BY trip_id
) AS ca
    ON ca.trip_id = ft.trip_id;

SELECT * FROM vw_fishing_trip_summary;

CREATE OR REPLACE VIEW vw_fish_marketing_kpis AS
SELECT
    sp.common_name                     AS species_name,
    COALESCE(ca.total_caught_kg, 0.00) AS total_caught_kg,
    COALESCE(sa.total_sold_kg, 0.00)   AS total_sold_kg,
    COALESCE(sa.total_revenue, 0.00)   AS total_revenue,
    CASE
        WHEN COALESCE(ca.total_caught_kg, 0) = 0 THEN 0.00
        ELSE ROUND(COALESCE(sa.total_sold_kg, 0) / ca.total_caught_kg * 100, 2)
    END                                AS turnover_percentage,
    CASE
        WHEN COALESCE(sa.total_revenue, 0) > 40000000 THEN 'ALTO'
        WHEN COALESCE(sa.total_revenue, 0) > 20000000 THEN 'MEDIO'
        ELSE 'BAJO'
    END                                AS performance_level
FROM species AS sp
LEFT JOIN (
    SELECT species_id, SUM(weight_kg) AS total_caught_kg
    FROM catches
    GROUP BY species_id
) AS ca
    ON ca.species_id = sp.species_id
LEFT JOIN (
    SELECT
        c.species_id,
        SUM(sd.sold_weight_kg)                  AS total_sold_kg,
        SUM(sd.sold_weight_kg * sd.unit_price)  AS total_revenue
    FROM sale_details AS sd
    INNER JOIN sales   AS s ON s.sale_id  = sd.sale_id
    INNER JOIN catches AS c ON c.catch_id = sd.catch_id
    WHERE s.status <> 'ANULADA'
    GROUP BY c.species_id
) AS sa
    ON sa.species_id = sp.species_id;

SELECT * FROM vw_fish_marketing_kpis ORDER BY total_revenue DESC;
