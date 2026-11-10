/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: RTP

    Capa: STAGING

    Objetivo:
    Recibir la representación original del CSV RAW
    utilizando columnas TEXT antes de aplicar tipado,
    homologación, normalización o limpieza.

    Fuente física observada:
    fecha,mes,anio,servicio,tipo_pago,afluencia

    PRINCIPIOS:
    - RAW permanece intacto.
    - No se corrigen valores en STAGING.
    - No se eliminan registros.
    - El literal NaN de afluencia permanece como texto.
    - Los ceros permanecen como texto "0".
    - Los valores decimales permanecen en su representación original.
    - No se homologan variantes de servicio.
    - No se imponen restricciones UNIQUE.
    - La granularidad todavía no se considera validada.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. REINICIO CONTROLADO DE STAGING RTP
-- =========================================================

DROP TABLE IF EXISTS proyecto.rtp_desglosada_stage;


-- =========================================================
-- 3. STAGING - RTP DESGLOSADA
--
-- Estructura RAW observada:
-- fecha,mes,anio,servicio,tipo_pago,afluencia
--
-- Todas las columnas se reciben como TEXT.
-- =========================================================

CREATE TABLE proyecto.rtp_desglosada_stage (
    fecha       TEXT,
    mes         TEXT,
    anio        TEXT,
    servicio    TEXT,
    tipo_pago   TEXT,
    afluencia   TEXT
);


-- =========================================================
-- 4. VALIDACIÓN DE EXISTENCIA Y NÚMERO DE COLUMNAS
-- =========================================================

SELECT
    table_name,
    COUNT(*) AS numero_columnas
FROM information_schema.columns
WHERE table_schema = 'proyecto'
  AND table_name = 'rtp_desglosada_stage'
GROUP BY table_name;


-- =========================================================
-- 5. VALIDACIÓN DE ORDEN, NOMBRE Y TIPO
-- =========================================================

SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'proyecto'
  AND table_name = 'rtp_desglosada_stage'
ORDER BY ordinal_position;


-- =========================================================
-- 6. CONTEO INICIAL
--
-- Antes de la ingesta debe ser 0.
-- =========================================================

SELECT
    COUNT(*) AS registros_iniciales
FROM proyecto.rtp_desglosada_stage;