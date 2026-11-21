\encoding UTF8
\set ON_ERROR_STOP on

/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Cablebús

    Capa: INGESTA RAW -> STAGING

    OBJETIVO:
    Cargar el CSV RAW de Cablebús preservando su
    representación original mediante columnas TEXT.

    Fuente física:
    fecha,mes,anio,linea,tipo_pago,afluencia

    Perfilado RAW previo:
    - 7,972 registros.
    - 0 filas malformadas.
    - 0 NaN.
    - 207 ceros.
    - 0 negativos.
    - 0 valores decimales.
    - 0 duplicados exactos.
    - 0 colisiones en:
      fecha × linea × tipo_pago.

    Representaciones originales de linea observadas:

        Línea 1
        Línea 2
        Linea 1
        Linea 2
        Linea 3

    IMPORTANTE:
    - Ejecutar mediante psql.
    - Ejecutar desde la raíz del repositorio.
    - RAW permanece intacto.
    - No se aplica limpieza.
    - No se aplica tipado.
    - No se homologan valores de linea.
    - Los ceros permanecen como texto.
    - No se imponen restricciones UNIQUE.
*/


-- =========================================================
-- 1. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 2. REINICIO CONTROLADO DE STAGING
-- =========================================================

TRUNCATE TABLE proyecto.cablebus_desglosada_stage;


-- =========================================================
-- 3. INGESTA CABLEBÚS DESGLOSADA
--
-- RAW:
-- fecha,mes,anio,linea,tipo_pago,afluencia
-- =========================================================

\echo
\echo ==========================================
\echo Iniciando carga de Cablebus Desglosada...
\echo ==========================================

\copy proyecto.cablebus_desglosada_stage (fecha, mes, anio, linea, tipo_pago, afluencia) FROM 'proyecto/data/raw/cablebus/afluencia_desglosada_cb_09_2026.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga de Cablebus Desglosada terminada.


-- =========================================================
-- 4. CONTEO POST-INGESTA
-- =========================================================

\echo
\echo ==========================================
\echo Conteo STAGING Cablebus
\echo ==========================================

SELECT
    COUNT(*) AS registros_stage
FROM proyecto.cablebus_desglosada_stage;


-- =========================================================
-- 5. CONCILIACIÓN CONTRA MANIFEST
-- =========================================================

\echo
\echo ==========================================
\echo Conciliacion contra manifest
\echo ==========================================

SELECT
    'Cablebus Desglosada' AS fuente,
    7972::bigint AS esperado,
    COUNT(*) AS obtenido,
    COUNT(*) - 7972::bigint AS diferencia
FROM proyecto.cablebus_desglosada_stage;


-- =========================================================
-- 6. COMPROBACIÓN DE NaN
--
-- Perfilado RAW previo:
-- 0 literales NaN.
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de NaN
\echo ==========================================

SELECT
    COUNT(*) AS registros_nan
FROM proyecto.cablebus_desglosada_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan';


-- =========================================================
-- 7. COMPROBACIÓN DE CEROS
--
-- Perfilado RAW previo:
-- 207 ceros.
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de ceros
\echo ==========================================

SELECT
    COUNT(*) AS registros_cero
FROM proyecto.cablebus_desglosada_stage
WHERE BTRIM(afluencia) = '0';


-- =========================================================
-- 8. DOMINIO ORIGINAL DE TIPO DE PAGO
-- =========================================================

\echo
\echo ==========================================
\echo Dominio original de tipo_pago
\echo ==========================================

SELECT
    tipo_pago,
    COUNT(*) AS registros
FROM proyecto.cablebus_desglosada_stage
GROUP BY tipo_pago
ORDER BY tipo_pago;


-- =========================================================
-- 9. DOMINIO ORIGINAL DE LINEA
--
-- No se aplica homologación.
-- =========================================================

\echo
\echo ==========================================
\echo Dominio original de linea
\echo ==========================================

SELECT
    linea,
    COUNT(*) AS registros,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max
FROM proyecto.cablebus_desglosada_stage
GROUP BY linea
ORDER BY linea;


-- =========================================================
-- 10. MUESTRA SIN TRANSFORMAR
-- =========================================================

\echo
\echo ==========================================
\echo Muestra RAW preservada en STAGING
\echo ==========================================

SELECT
    fecha,
    mes,
    anio,
    linea,
    tipo_pago,
    afluencia
FROM proyecto.cablebus_desglosada_stage
ORDER BY
    fecha,
    linea,
    tipo_pago
LIMIT 10;


-- =========================================================
-- 11. CONTROL AUTOMÁTICO DE INTEGRIDAD
-- =========================================================

DO $$
DECLARE
    total_stage BIGINT;
    total_nan   BIGINT;
    total_ceros BIGINT;
BEGIN

    SELECT COUNT(*)
    INTO total_stage
    FROM proyecto.cablebus_desglosada_stage;

    SELECT COUNT(*)
    INTO total_nan
    FROM proyecto.cablebus_desglosada_stage
    WHERE LOWER(BTRIM(afluencia)) = 'nan';

    SELECT COUNT(*)
    INTO total_ceros
    FROM proyecto.cablebus_desglosada_stage
    WHERE BTRIM(afluencia) = '0';

    IF total_stage <> 7972 THEN
        RAISE EXCEPTION
            'Conteo Cablebus incorrecto. Esperado: 7972. Obtenido: %',
            total_stage;
    END IF;

    IF total_nan <> 0 THEN
        RAISE EXCEPTION
            'Conteo NaN Cablebus incorrecto. Esperado: 0. Obtenido: %',
            total_nan;
    END IF;

    IF total_ceros <> 207 THEN
        RAISE EXCEPTION
            'Conteo de ceros Cablebus incorrecto. Esperado: 207. Obtenido: %',
            total_ceros;
    END IF;

    RAISE NOTICE
        'Integridad STAGING Cablebus correcta. Registros: %, NaN: %, ceros: %',
        total_stage,
        total_nan,
        total_ceros;

END
$$;


-- =========================================================
-- 12. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;


\echo
\echo ==========================================
\echo INGESTA CABLEBUS COMPLETADA
\echo ==========================================