\encoding UTF8
\set ON_ERROR_STOP on

/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metro

    Capa: INGESTA RAW -> STAGING

    IMPORTANTE:
    - Ejecutar este archivo mediante psql.
    - Ejecutarlo desde la raíz del repositorio.
    - Los archivos RAW permanecen sin modificaciones.
    - La limpieza de mojibake se realizará posteriormente.
*/


-- =========================================================
-- 1. REINICIO CONTROLADO DE STAGING
-- =========================================================

TRUNCATE TABLE proyecto.metro_simple_stage;
TRUNCATE TABLE proyecto.metro_desglosada_stage;


-- =========================================================
-- 2. INGESTA METRO SIMPLE
-- =========================================================

\echo Iniciando carga de Metro Simple...

\copy proyecto.metro_simple_stage (fecha, anio, mes, linea, estacion, afluencia) FROM 'proyecto/data/raw/metro/datos_metro_simple_raw.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga de Metro Simple terminada.


-- =========================================================
-- 3. INGESTA METRO DESGLOSADA
-- =========================================================

\echo Iniciando carga de Metro Desglosada...

\copy proyecto.metro_desglosada_stage (fecha, mes, anio, linea, estacion, tipo_pago, afluencia) FROM 'proyecto/data/raw/metro/datos_metro_desglosada_raw.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga de Metro Desglosada terminada.


-- =========================================================
-- 4. CONTEOS POST-INGESTA
-- =========================================================

SELECT
    'metro_simple_stage' AS tabla,
    COUNT(*) AS registros
FROM proyecto.metro_simple_stage

UNION ALL

SELECT
    'metro_desglosada_stage',
    COUNT(*)
FROM proyecto.metro_desglosada_stage;


-- =========================================================
-- 5. CONCILIACIÓN CONTRA EL MANIFEST
-- =========================================================

SELECT
    'Metro Simple' AS fuente,
    1180920::bigint AS esperado,
    COUNT(*) AS obtenido,
    COUNT(*) - 1180920::bigint AS diferencia
FROM proyecto.metro_simple_stage

UNION ALL

SELECT
    'Metro Desglosada',
    1192230::bigint,
    COUNT(*),
    COUNT(*) - 1192230::bigint
FROM proyecto.metro_desglosada_stage;


-- =========================================================
-- 6. TOTAL DE REGISTROS EN STAGING
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.metro_simple_stage)
    +
    (SELECT COUNT(*)
     FROM proyecto.metro_desglosada_stage)
    AS total_registros_stage;