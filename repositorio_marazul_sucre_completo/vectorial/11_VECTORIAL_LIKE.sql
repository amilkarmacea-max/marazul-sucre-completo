USE marazul_sucre;

SELECT common_name, organoleptic_description
FROM species
WHERE organoleptic_description LIKE '%pescado blanco de carne firme para ceviche fresco%';

SELECT common_name, organoleptic_description
FROM species
WHERE organoleptic_description LIKE '%ceviche%';

SELECT common_name, organoleptic_description
FROM species
WHERE organoleptic_description LIKE '%fiesta de playa%';

SELECT common_name, organoleptic_description
FROM species
WHERE organoleptic_description LIKE '%freír entero%';
