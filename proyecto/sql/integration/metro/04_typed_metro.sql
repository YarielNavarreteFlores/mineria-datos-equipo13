/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metro

    Capa TYPED

    Objetivo:
    convertir de forma controlada las variables cuyo tipo
    fue previamente validado en STAGING.

    IMPORTANTE:
    - No se corrige mojibake en esta capa.
    - No se eliminan registros.
    - No se alteran categorías.
*/


-- =========================================================
-- 1. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.metro_simple_typed;
DROP TABLE IF EXISTS proyecto.metro_desglosada_typed;


-- =========================================================
-- 2. TABLA TYPED - METRO SIMPLE
-- =========================================================

CREATE TABLE proyecto.metro_simple_typed (
    fecha       DATE,
    anio        SMALLINT,
    mes         TEXT,
    linea       TEXT,
    estacion    TEXT,
    afluencia   INTEGER
);


-- =========================================================
-- 3. TABLA TYPED - METRO DESGLOSADA
-- =========================================================

CREATE TABLE proyecto.metro_desglosada_typed (
    fecha       DATE,
    mes         TEXT,
    anio        SMALLINT,
    linea       TEXT,
    estacion    TEXT,
    tipo_pago   TEXT,
    afluencia   INTEGER
);


-- =========================================================
-- 4. TRANSFORMACIÓN STAGE -> TYPED - SIMPLE
-- =========================================================

INSERT INTO proyecto.metro_simple_typed (
    fecha,
    anio,
    mes,
    linea,
    estacion,
    afluencia
)
SELECT
    BTRIM(fecha)::DATE,
    BTRIM(anio)::SMALLINT,
    BTRIM(mes),
    BTRIM(linea),
    BTRIM(estacion),
    BTRIM(afluencia)::INTEGER
FROM proyecto.metro_simple_stage;


-- =========================================================
-- 5. TRANSFORMACIÓN STAGE -> TYPED - DESGLOSADA
-- =========================================================

INSERT INTO proyecto.metro_desglosada_typed (
    fecha,
    mes,
    anio,
    linea,
    estacion,
    tipo_pago,
    afluencia
)
SELECT
    BTRIM(fecha)::DATE,
    BTRIM(mes),
    BTRIM(anio)::SMALLINT,
    BTRIM(linea),
    BTRIM(estacion),
    BTRIM(tipo_pago),
    BTRIM(afluencia)::INTEGER
FROM proyecto.metro_desglosada_stage;


-- =========================================================
-- 6. CONCILIACIÓN STAGE VS TYPED
-- =========================================================

SELECT
    'Metro Simple' AS fuente,

    (SELECT COUNT(*)
     FROM proyecto.metro_simple_stage) AS stage,

    (SELECT COUNT(*)
     FROM proyecto.metro_simple_typed) AS typed,

    (
        (SELECT COUNT(*)
         FROM proyecto.metro_simple_typed)
        -
        (SELECT COUNT(*)
         FROM proyecto.metro_simple_stage)
    ) AS diferencia

UNION ALL

SELECT
    'Metro Desglosada',

    (SELECT COUNT(*)
     FROM proyecto.metro_desglosada_stage),

    (SELECT COUNT(*)
     FROM proyecto.metro_desglosada_typed),

    (
        (SELECT COUNT(*)
         FROM proyecto.metro_desglosada_typed)
        -
        (SELECT COUNT(*)
         FROM proyecto.metro_desglosada_stage)
    );


-- =========================================================
-- 7. VERIFICACIÓN DE TIPOS
-- =========================================================

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'proyecto'
  AND table_name IN (
      'metro_simple_typed',
      'metro_desglosada_typed'
  )
ORDER BY
    table_name,
    ordinal_position;


-- =========================================================
-- 8. RANGOS POST-TIPADO
-- =========================================================

SELECT
    'Metro Simple' AS fuente,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,
    MIN(anio) AS anio_min,
    MAX(anio) AS anio_max,
    MIN(afluencia) AS afluencia_min,
    MAX(afluencia) AS afluencia_max
FROM proyecto.metro_simple_typed

UNION ALL

SELECT
    'Metro Desglosada',
    MIN(fecha),
    MAX(fecha),
    MIN(anio),
    MAX(anio),
    MIN(afluencia),
    MAX(afluencia)
FROM proyecto.metro_desglosada_typed;