\encoding UTF8
\set ON_ERROR_STOP on

/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metrobús

    Capa: INGESTA RAW -> STAGING

    OBJETIVO:
    Cargar los CSV RAW preservando su representación
    original en columnas TEXT.

    IMPORTANTE:
    - Ejecutar mediante psql.
    - Ejecutar desde la raíz del repositorio.
    - Los archivos RAW permanecen intactos.
    - No se aplica limpieza ni tipado.
    - El literal NaN permanece como texto.
    - No se imponen restricciones de unicidad.
*/


-- =========================================================
-- 1. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 2. REINICIO CONTROLADO DE STAGING
-- =========================================================

TRUNCATE TABLE proyecto.metrobus_simple_stage;
TRUNCATE TABLE proyecto.metrobus_desglosada_stage;


-- =========================================================
-- 3. INGESTA METROBÚS SIMPLE
--
-- RAW:
-- fecha,anio,mes,linea,afluencia
-- =========================================================

\echo
\echo ==========================================
\echo Iniciando carga de Metrobus Simple...
\echo ==========================================

\copy proyecto.metrobus_simple_stage (fecha, anio, mes, linea, afluencia) FROM 'proyecto/data/raw/metrobus/datos_metrobus_simple_raw.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga de Metrobus Simple terminada.


-- =========================================================
-- 4. INGESTA METROBÚS DESGLOSADA
--
-- RAW:
-- fecha,mes,anio,linea,tipo_pago,afluencia
-- =========================================================

\echo
\echo ==========================================
\echo Iniciando carga de Metrobus Desglosada...
\echo ==========================================

\copy proyecto.metrobus_desglosada_stage (fecha, mes, anio, linea, tipo_pago, afluencia) FROM 'proyecto/data/raw/metrobus/datos_metrobus_desglosada_raw.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga de Metrobus Desglosada terminada.


-- =========================================================
-- 5. CONTEOS POST-INGESTA
-- =========================================================

\echo
\echo ==========================================
\echo Conteos STAGING
\echo ==========================================

SELECT
    'metrobus_simple_stage' AS tabla,
    COUNT(*) AS registros
FROM proyecto.metrobus_simple_stage

UNION ALL

SELECT
    'metrobus_desglosada_stage',
    COUNT(*)
FROM proyecto.metrobus_desglosada_stage;


-- =========================================================
-- 6. CONCILIACIÓN CONTRA EL MANIFEST
-- =========================================================

\echo
\echo ==========================================
\echo Conciliacion contra manifest
\echo ==========================================

SELECT
    'Metrobus Simple' AS fuente,
    54159::bigint AS esperado,
    COUNT(*) AS obtenido,
    COUNT(*) - 54159::bigint AS diferencia
FROM proyecto.metrobus_simple_stage

UNION ALL

SELECT
    'Metrobus Desglosada',
    29386::bigint,
    COUNT(*),
    COUNT(*) - 29386::bigint
FROM proyecto.metrobus_desglosada_stage;


-- =========================================================
-- 7. COMPROBACIÓN DEL LITERAL NaN
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion del literal NaN
\echo ==========================================

SELECT
    COUNT(*) AS registros_nan_simple
FROM proyecto.metrobus_simple_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan';


SELECT
    fecha,
    anio,
    mes,
    linea,
    afluencia
FROM proyecto.metrobus_simple_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan'
ORDER BY fecha, linea
LIMIT 10;


-- =========================================================
-- 8. VERIFICACIÓN DEL HALLAZGO INICIAL
-- =========================================================

\echo
\echo ==========================================
\echo Verificacion del hallazgo 2005-07-26
\echo ==========================================

SELECT
    fecha,
    anio,
    mes,
    linea,
    afluencia
FROM proyecto.metrobus_simple_stage
WHERE fecha = '2005-07-26'
ORDER BY linea;


-- =========================================================
-- 9. CONTROL AUTOMÁTICO DE CONTEOS
-- =========================================================

DO $$
DECLARE
    simple_count      BIGINT;
    desglosada_count  BIGINT;
BEGIN

    SELECT COUNT(*)
    INTO simple_count
    FROM proyecto.metrobus_simple_stage;

    SELECT COUNT(*)
    INTO desglosada_count
    FROM proyecto.metrobus_desglosada_stage;

    IF simple_count <> 54159 THEN
        RAISE EXCEPTION
            'Conteo Metrobús Simple incorrecto. Esperado: 54159. Obtenido: %',
            simple_count;
    END IF;

    IF desglosada_count <> 29386 THEN
        RAISE EXCEPTION
            'Conteo Metrobús Desglosada incorrecto. Esperado: 29386. Obtenido: %',
            desglosada_count;
    END IF;

    RAISE NOTICE
        'Conteos correctos. Simple: %, Desglosada: %',
        simple_count,
        desglosada_count;

END
$$;


-- =========================================================
-- 10. TOTAL DE REGISTROS
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_stage)
    +
    (SELECT COUNT(*)
     FROM proyecto.metrobus_desglosada_stage)
    AS total_registros_stage;


-- =========================================================
-- 11. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;


\echo
\echo ==========================================
\echo INGESTA METROBUS COMPLETADA
\echo ==========================================