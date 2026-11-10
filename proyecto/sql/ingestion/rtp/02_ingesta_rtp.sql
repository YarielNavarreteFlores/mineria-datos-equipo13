\encoding UTF8
\set ON_ERROR_STOP on

/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: RTP

    Capa: INGESTA RAW -> STAGING

    OBJETIVO:
    Cargar el CSV RAW de RTP preservando su representación
    original mediante columnas TEXT.

    IMPORTANTE:
    - Ejecutar mediante psql desde la raíz del repositorio.
    - RAW permanece intacto.
    - No se aplica limpieza.
    - No se aplica tipado.
    - No se homologan valores de servicio.
    - El literal NaN permanece como texto.
    - Los ceros permanecen como texto.
    - Los decimales permanecen en su representación original.
*/


-- =========================================================
-- 1. INICIO DE TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 2. REINICIO CONTROLADO DE STAGING
-- =========================================================

TRUNCATE TABLE proyecto.rtp_desglosada_stage;


-- =========================================================
-- 3. INGESTA RTP DESGLOSADA
--
-- RAW:
-- fecha,mes,anio,servicio,tipo_pago,afluencia
-- =========================================================

\echo
\echo ==========================================
\echo Iniciando carga de RTP Desglosada...
\echo ==========================================

\copy proyecto.rtp_desglosada_stage (fecha, mes, anio, servicio, tipo_pago, afluencia) FROM 'proyecto/data/raw/rtp/afluenciartp_desglosado_09_2026.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8')

\echo Carga de RTP Desglosada terminada.


-- =========================================================
-- 4. CONTEO POST-INGESTA
-- =========================================================

\echo
\echo ==========================================
\echo Conteo STAGING RTP
\echo ==========================================

SELECT
    COUNT(*) AS registros_stage
FROM proyecto.rtp_desglosada_stage;


-- =========================================================
-- 5. CONCILIACIÓN CONTRA MANIFEST
-- =========================================================

\echo
\echo ==========================================
\echo Conciliacion contra manifest
\echo ==========================================

SELECT
    'RTP Desglosada' AS fuente,
    41676::bigint AS esperado,
    COUNT(*) AS obtenido,
    COUNT(*) - 41676::bigint AS diferencia
FROM proyecto.rtp_desglosada_stage;


-- =========================================================
-- 6. PRESERVACIÓN DEL LITERAL NaN
--
-- Perfilado RAW previo:
-- 187 literales NaN
-- =========================================================

\echo
\echo ==========================================
\echo Comprobacion de NaN preservados
\echo ==========================================

SELECT
    COUNT(*) AS registros_nan
FROM proyecto.rtp_desglosada_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan';


-- =========================================================
-- 7. DISTRIBUCIÓN ORIGINAL DE TIPO DE PAGO
-- =========================================================

\echo
\echo ==========================================
\echo Dominio original de tipo_pago
\echo ==========================================

SELECT
    tipo_pago,
    COUNT(*) AS registros
FROM proyecto.rtp_desglosada_stage
GROUP BY tipo_pago
ORDER BY tipo_pago;


-- =========================================================
-- 8. MUESTRA SIN TRANSFORMAR
-- =========================================================

SELECT
    fecha,
    mes,
    anio,
    servicio,
    tipo_pago,
    afluencia
FROM proyecto.rtp_desglosada_stage
ORDER BY fecha, servicio, tipo_pago
LIMIT 10;


-- =========================================================
-- 9. CONTROL AUTOMÁTICO DE INTEGRIDAD
-- =========================================================

DO $$
DECLARE
    total_stage BIGINT;
    total_nan   BIGINT;
BEGIN

    SELECT COUNT(*)
    INTO total_stage
    FROM proyecto.rtp_desglosada_stage;

    SELECT COUNT(*)
    INTO total_nan
    FROM proyecto.rtp_desglosada_stage
    WHERE LOWER(BTRIM(afluencia)) = 'nan';

    IF total_stage <> 41676 THEN
        RAISE EXCEPTION
            'Conteo RTP incorrecto. Esperado: 41676. Obtenido: %',
            total_stage;
    END IF;

    IF total_nan <> 187 THEN
        RAISE EXCEPTION
            'Conteo NaN RTP incorrecto. Esperado: 187. Obtenido: %',
            total_nan;
    END IF;

    RAISE NOTICE
        'Integridad STAGING RTP correcta. Registros: %, NaN: %',
        total_stage,
        total_nan;

END
$$;


-- =========================================================
-- 10. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;


\echo
\echo ==========================================
\echo INGESTA RTP COMPLETADA
\echo ==========================================