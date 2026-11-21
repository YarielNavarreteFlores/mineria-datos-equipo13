/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Cablebús

    Capa: STAGING

    Objetivo:
    Recibir la representación original del CSV RAW
    utilizando columnas TEXT antes de aplicar tipado,
    homologación, normalización o limpieza.

    Fuente física observada:
    fecha,mes,anio,linea,tipo_pago,afluencia

    Evidencia previa:
    - 7,972 filas.
    - 6 columnas.
    - 0 filas malformadas.
    - Cobertura observada:
      2022-01-01 → 2026-09-30.
    - 0 duplicados exactos.
    - 0 colisiones en:
      fecha × linea × tipo_pago.
    - 207 ceros.
    - 0 NaN.
    - 0 valores negativos.
    - 0 valores decimales.

    IMPORTANTE:
    Se observaron variantes históricas de linea:

        'Línea 1'
        'Línea 2'

    y posteriormente:

        'Linea 1'
        'Linea 2'
        'Linea 3'

    STAGING debe preservar dichas representaciones
    exactamente como aparecen en RAW.

    PRINCIPIOS:
    - RAW permanece intacto.
    - No se corrigen valores en STAGING.
    - No se eliminan registros.
    - Los ceros permanecen como texto "0".
    - No se homologan variantes de linea.
    - No se imponen restricciones UNIQUE.
    - La granularidad observada sigue siendo candidata
      hasta completar el perfilado SQL.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. REINICIO CONTROLADO DE STAGING CABLEBÚS
-- =========================================================

DROP TABLE IF EXISTS proyecto.cablebus_desglosada_stage;


-- =========================================================
-- 3. STAGING - CABLEBÚS DESGLOSADA
--
-- Estructura RAW observada:
-- fecha,mes,anio,linea,tipo_pago,afluencia
--
-- Todas las columnas se reciben como TEXT.
-- =========================================================

CREATE TABLE proyecto.cablebus_desglosada_stage (
    fecha       TEXT,
    mes         TEXT,
    anio        TEXT,
    linea       TEXT,
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
  AND table_name = 'cablebus_desglosada_stage'
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
  AND table_name = 'cablebus_desglosada_stage'
ORDER BY ordinal_position;


-- =========================================================
-- 6. CONTEO INICIAL
--
-- Antes de la ingesta debe ser 0.
-- =========================================================

SELECT
    COUNT(*) AS registros_iniciales
FROM proyecto.cablebus_desglosada_stage;