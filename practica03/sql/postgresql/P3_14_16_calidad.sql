-- Controles de solo lectura. Cada SELECT produce una cuadrícula.
SELECT anio_fuente, COUNT(*) AS registros,
       COUNT(*)-COUNT(municipio_um) AS municipio_um_nulos,
       COUNT(*)-COUNT(clues) AS clues_nulos, COUNT(*)-COUNT(fecha_resultado) AS fecha_resultado_nulos,
       ROUND(100.0*(COUNT(*)-COUNT(fecha_resultado))/COUNT(*),2) AS pct_sin_fecha_resultado,
       COUNT(*)-COUNT(edad) AS edad_nula, MIN(edad) AS edad_minima, MAX(edad) AS edad_maxima
FROM public.covid_historica GROUP BY anio_fuente ORDER BY anio_fuente;

SELECT anio_fuente, edad, COUNT(*) AS registros_con_esa_edad,
       SUM(COUNT(*)) OVER(PARTITION BY anio_fuente) AS total_100_o_mas_en_fuente
FROM public.covid_historica WHERE edad >= 100 GROUP BY anio_fuente, edad ORDER BY anio_fuente, edad DESC;

SELECT conname, pg_get_constraintdef(oid), convalidated FROM pg_constraint
WHERE conrelid='p3_covid.fact_registro_covid'::regclass AND contype='f' ORDER BY conname;

SELECT s.anio_fuente,p.edad,SUM(f.cantidad_registros) AS registros
FROM p3_covid.fact_registro_covid f JOIN p3_covid.dim_fuente s USING(id_fuente)
JOIN p3_covid.dim_perfil_demografico p USING(id_perfil)
GROUP BY s.anio_fuente,p.edad ORDER BY s.anio_fuente,p.edad;

-- Completitud después de la carga, ponderada por registro de vigilancia.
WITH detalle AS (
    SELECT s.anio_fuente, u.municipio_um, u.clues, f.id_fecha_resultado, p.edad
    FROM p3_covid.fact_registro_covid f JOIN p3_covid.dim_fuente s USING(id_fuente)
    JOIN p3_covid.dim_unidad_medica u USING(id_unidad_medica)
    JOIN p3_covid.dim_perfil_demografico p USING(id_perfil)
)
SELECT d.anio_fuente, c.campo, COUNT(*) FILTER (WHERE c.ausente) AS nulos,
       ROUND(100.0*COUNT(*) FILTER (WHERE c.ausente)/COUNT(*), 2) AS porcentaje
FROM detalle d CROSS JOIN LATERAL (VALUES ('municipio_um',municipio_um IS NULL),
    ('clues',clues IS NULL), ('fecha_resultado',id_fecha_resultado IS NULL),
    ('edad',edad IS NULL)) c(campo,ausente)
GROUP BY d.anio_fuente,c.campo ORDER BY 1,2;

SELECT s.anio_fuente, p.nacionalidad, COUNT(*) FROM p3_covid.fact_registro_covid f
JOIN p3_covid.dim_fuente s USING(id_fuente) JOIN p3_covid.dim_perfil_demografico p USING(id_perfil)
GROUP BY 1,2 ORDER BY 1,2;

SELECT s.anio_fuente, r.estado_validacion, COUNT(DISTINCT id_residencia) AS parejas, COUNT(*) AS registros
FROM p3_covid.fact_registro_covid f JOIN p3_covid.dim_fuente s USING(id_fuente)
JOIN p3_covid.dim_residencia r USING(id_residencia) GROUP BY 1,2 ORDER BY 1,2;
