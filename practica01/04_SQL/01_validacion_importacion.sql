-- 1. Conteo de la tabla simple
SELECT COUNT(*) AS registros FROM practica01.metro_simple_raw;

-- 2. Conteo de la tabla desglosada
SELECT COUNT(*) AS registros FROM practica01.metro_desglosada_raw;

-- 3. Fechas de la tabla simple
SELECT MIN(fecha) AS fecha_minima, MAX(fecha) AS fecha_maxima FROM practica01.metro_simple_raw;

-- 4. Fechas de la tabla desglosada
SELECT MIN(fecha) AS fecha_minima, MAX(fecha) AS fecha_maxima FROM practica01.metro_desglosada_raw;


-- =========================================================
-- RESULTADOS ESPERADOS
--
-- metro_simple_raw:
-- registros:    1,180,920
-- fecha mínima: 2010-01-01
-- fecha máxima: 2026-07-31
--
-- metro_desglosada_raw:
-- registros:    1,192,230
-- fecha mínima: 2021-01-01
-- fecha máxima: 2026-07-31
-- =========================================================