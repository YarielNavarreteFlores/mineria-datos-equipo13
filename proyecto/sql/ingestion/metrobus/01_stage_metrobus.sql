/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metrobús

    Capa: STAGING

    Objetivo:
    Recibir la representación original de los CSV RAW
    utilizando columnas TEXT antes de aplicar tipado,
    normalización o limpieza.

    PRINCIPIOS:
    - RAW permanece intacto.
    - No se corrigen valores en STAGING.
    - No se eliminan registros.
    - El literal NaN de afluencia permanece como texto.
    - No se imponen restricciones UNIQUE.
    - Las granularidades siguen siendo candidatas.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. REINICIO CONTROLADO DE STAGING
-- =========================================================

DROP TABLE IF EXISTS proyecto.metrobus_simple_stage;

DROP TABLE IF EXISTS proyecto.metrobus_desglosada_stage;


-- =========================================================
-- 3. STAGING - METROBÚS SIMPLE
--
-- Estructura RAW observada:
-- fecha,anio,mes,linea,afluencia
-- =========================================================

CREATE TABLE proyecto.metrobus_simple_stage (
    fecha       TEXT,
    anio        TEXT,
    mes         TEXT,
    linea       TEXT,
    afluencia   TEXT
);


-- =========================================================
-- 4. STAGING - METROBÚS DESGLOSADA
--
-- Estructura RAW observada:
-- fecha,mes,anio,linea,tipo_pago,afluencia
--
-- IMPORTANTE:
-- El orden de mes y anio es distinto al recurso Simple.
-- =========================================================

CREATE TABLE proyecto.metrobus_desglosada_stage (
    fecha       TEXT,
    mes         TEXT,
    anio        TEXT,
    linea       TEXT,
    tipo_pago   TEXT,
    afluencia   TEXT
);


-- =========================================================
-- 5. VALIDACIÓN DE EXISTENCIA Y NÚMERO DE COLUMNAS
-- =========================================================

SELECT
    table_name,
    COUNT(*) AS numero_columnas
FROM information_schema.columns
WHERE table_schema = 'proyecto'
  AND table_name IN (
      'metrobus_simple_stage',
      'metrobus_desglosada_stage'
  )
GROUP BY table_name
ORDER BY table_name;


-- =========================================================
-- 6. VALIDACIÓN DEL ORDEN Y NOMBRE DE COLUMNAS
-- =========================================================

SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'proyecto'
  AND table_name IN (
      'metrobus_simple_stage',
      'metrobus_desglosada_stage'
  )
ORDER BY
    table_name,
    ordinal_position;


-- =========================================================
-- 7. CONTEOS INICIALES
-- =========================================================

SELECT
    'metrobus_simple_stage' AS tabla,
    COUNT(*) AS registros
FROM proyecto.metrobus_simple_stage

UNION ALL

SELECT
    'metrobus_desglosada_stage',
    COUNT(*)
FROM proyecto.metrobus_desglosada_stage;