/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metro

    PERFILADO PREVIO AL TIPADO

    Objetivo:
    comprobar la calidad y convertibilidad de STAGING
    antes de construir las tablas TYPED/CLEAN.

    Este script NO modifica datos.
*/


-- =========================================================
-- 0. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario,
    version() AS version_postgresql;


-- =========================================================
-- 1. CONTEOS BASE
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
-- 2. VALORES VACÍOS / NULL - SIMPLE
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha), '') IS NULL
    ) AS vacios_fecha,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(anio), '') IS NULL
    ) AS vacios_anio,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(mes), '') IS NULL
    ) AS vacios_mes,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(linea), '') IS NULL
    ) AS vacios_linea,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(estacion), '') IS NULL
    ) AS vacios_estacion,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NULL
    ) AS vacios_afluencia

FROM proyecto.metro_simple_stage;


-- =========================================================
-- 3. VALORES VACÍOS / NULL - DESGLOSADA
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha), '') IS NULL
    ) AS vacios_fecha,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(mes), '') IS NULL
    ) AS vacios_mes,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(anio), '') IS NULL
    ) AS vacios_anio,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(linea), '') IS NULL
    ) AS vacios_linea,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(estacion), '') IS NULL
    ) AS vacios_estacion,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(tipo_pago), '') IS NULL
    ) AS vacios_tipo_pago,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NULL
    ) AS vacios_afluencia

FROM proyecto.metro_desglosada_stage;


-- =========================================================
-- 4. CONVERTIBILIDAD - SIMPLE
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(fecha), 'date')
    ) AS fecha_invalida,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(anio), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(anio), 'smallint')
    ) AS anio_invalido,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(afluencia), 'integer')
    ) AS afluencia_invalida

FROM proyecto.metro_simple_stage;


-- =========================================================
-- 5. CONVERTIBILIDAD - DESGLOSADA
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(fecha), 'date')
    ) AS fecha_invalida,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(anio), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(anio), 'smallint')
    ) AS anio_invalido,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NOT NULL
          AND NOT pg_input_is_valid(BTRIM(afluencia), 'integer')
    ) AS afluencia_invalida

FROM proyecto.metro_desglosada_stage;


-- =========================================================
-- 6. RANGOS TEMPORALES
-- Solo se convierten valores previamente válidos.
-- =========================================================

SELECT
    'Simple' AS fuente,

    MIN(BTRIM(fecha)::date) AS fecha_min,
    MAX(BTRIM(fecha)::date) AS fecha_max,

    MIN(BTRIM(anio)::smallint) AS anio_min,
    MAX(BTRIM(anio)::smallint) AS anio_max

FROM proyecto.metro_simple_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint')

UNION ALL

SELECT
    'Desglosada',

    MIN(BTRIM(fecha)::date),
    MAX(BTRIM(fecha)::date),

    MIN(BTRIM(anio)::smallint),
    MAX(BTRIM(anio)::smallint)

FROM proyecto.metro_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint');


-- =========================================================
-- 7. COHERENCIA FECHA ↔ ANIO
-- =========================================================

SELECT
    'Simple' AS fuente,
    COUNT(*) AS inconsistencias_anio
FROM proyecto.metro_simple_stage
WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint')
  AND EXTRACT(YEAR FROM BTRIM(fecha)::date)::smallint
      <> BTRIM(anio)::smallint

UNION ALL

SELECT
    'Desglosada',
    COUNT(*)
FROM proyecto.metro_desglosada_stage
WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint')
  AND EXTRACT(YEAR FROM BTRIM(fecha)::date)::smallint
      <> BTRIM(anio)::smallint;


-- =========================================================
-- 8. DOMINIO DE MES
-- =========================================================

SELECT
    'Simple' AS fuente,
    BTRIM(mes) AS mes,
    COUNT(*) AS frecuencia
FROM proyecto.metro_simple_stage
GROUP BY BTRIM(mes)

UNION ALL

SELECT
    'Desglosada',
    BTRIM(mes),
    COUNT(*)
FROM proyecto.metro_desglosada_stage
GROUP BY BTRIM(mes)

ORDER BY fuente, mes;


-- =========================================================
-- 9. COHERENCIA FECHA ↔ MES
-- =========================================================

WITH simple AS (
    SELECT
        fecha,
        mes,
        CASE LOWER(BTRIM(mes))
            WHEN 'enero' THEN 1
            WHEN 'febrero' THEN 2
            WHEN 'marzo' THEN 3
            WHEN 'abril' THEN 4
            WHEN 'mayo' THEN 5
            WHEN 'junio' THEN 6
            WHEN 'julio' THEN 7
            WHEN 'agosto' THEN 8
            WHEN 'septiembre' THEN 9
            WHEN 'octubre' THEN 10
            WHEN 'noviembre' THEN 11
            WHEN 'diciembre' THEN 12
            ELSE NULL
        END AS mes_num
    FROM proyecto.metro_simple_stage
),

desglosada AS (
    SELECT
        fecha,
        mes,
        CASE LOWER(BTRIM(mes))
            WHEN 'enero' THEN 1
            WHEN 'febrero' THEN 2
            WHEN 'marzo' THEN 3
            WHEN 'abril' THEN 4
            WHEN 'mayo' THEN 5
            WHEN 'junio' THEN 6
            WHEN 'julio' THEN 7
            WHEN 'agosto' THEN 8
            WHEN 'septiembre' THEN 9
            WHEN 'octubre' THEN 10
            WHEN 'noviembre' THEN 11
            WHEN 'diciembre' THEN 12
            ELSE NULL
        END AS mes_num
    FROM proyecto.metro_desglosada_stage
)

SELECT
    'Simple' AS fuente,
    COUNT(*) FILTER (
        WHERE mes_num IS NULL
    ) AS mes_no_reconocido,

    COUNT(*) FILTER (
        WHERE mes_num IS NOT NULL
          AND pg_input_is_valid(BTRIM(fecha), 'date')
          AND EXTRACT(MONTH FROM BTRIM(fecha)::date)::integer
              <> mes_num
    ) AS inconsistencias_fecha_mes

FROM simple

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE mes_num IS NULL
    ),

    COUNT(*) FILTER (
        WHERE mes_num IS NOT NULL
          AND pg_input_is_valid(BTRIM(fecha), 'date')
          AND EXTRACT(MONTH FROM BTRIM(fecha)::date)::integer
              <> mes_num
    )

FROM desglosada;


-- =========================================================
-- 10. RANGO DE AFLUENCIA
-- =========================================================

SELECT
    'Simple' AS fuente,

    MIN(BTRIM(afluencia)::integer) AS minimo,
    MAX(BTRIM(afluencia)::integer) AS maximo,

    COUNT(*) FILTER (
        WHERE BTRIM(afluencia)::integer = 0
    ) AS ceros,

    COUNT(*) FILTER (
        WHERE BTRIM(afluencia)::integer < 0
    ) AS negativos

FROM proyecto.metro_simple_stage
WHERE pg_input_is_valid(BTRIM(afluencia), 'integer')

UNION ALL

SELECT
    'Desglosada',

    MIN(BTRIM(afluencia)::integer),
    MAX(BTRIM(afluencia)::integer),

    COUNT(*) FILTER (
        WHERE BTRIM(afluencia)::integer = 0
    ),

    COUNT(*) FILTER (
        WHERE BTRIM(afluencia)::integer < 0
    )

FROM proyecto.metro_desglosada_stage
WHERE pg_input_is_valid(BTRIM(afluencia), 'integer');


-- =========================================================
-- 11. LONGITUDES MÁXIMAS
-- =========================================================

SELECT
    'Simple' AS fuente,
    MAX(LENGTH(BTRIM(linea))) AS max_linea,
    MAX(LENGTH(BTRIM(estacion))) AS max_estacion,
    NULL::integer AS max_tipo_pago
FROM proyecto.metro_simple_stage

UNION ALL

SELECT
    'Desglosada',
    MAX(LENGTH(BTRIM(linea))),
    MAX(LENGTH(BTRIM(estacion))),
    MAX(LENGTH(BTRIM(tipo_pago)))
FROM proyecto.metro_desglosada_stage;


-- =========================================================
-- 12. CATEGORÍAS DE LÍNEA
-- =========================================================

SELECT
    'Simple' AS fuente,
    BTRIM(linea) AS linea,
    COUNT(*) AS registros
FROM proyecto.metro_simple_stage
GROUP BY BTRIM(linea)

UNION ALL

SELECT
    'Desglosada',
    BTRIM(linea),
    COUNT(*)
FROM proyecto.metro_desglosada_stage
GROUP BY BTRIM(linea)

ORDER BY fuente, linea;


-- =========================================================
-- 13. TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros
FROM proyecto.metro_desglosada_stage
GROUP BY BTRIM(tipo_pago)
ORDER BY tipo_pago;


-- =========================================================
-- 14. MOJIBAKE - CUANTIFICACIÓN
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE linea LIKE '%Ã%'
    ) AS filas_linea_mojibake,

    COUNT(*) FILTER (
        WHERE estacion LIKE '%Ã%'
    ) AS filas_estacion_mojibake,

    COUNT(DISTINCT linea) FILTER (
        WHERE linea LIKE '%Ã%'
    ) AS lineas_mojibake_distintas,

    COUNT(DISTINCT estacion) FILTER (
        WHERE estacion LIKE '%Ã%'
    ) AS estaciones_mojibake_distintas

FROM proyecto.metro_simple_stage

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE linea LIKE '%Ã%'
    ),

    COUNT(*) FILTER (
        WHERE estacion LIKE '%Ã%'
    ),

    COUNT(DISTINCT linea) FILTER (
        WHERE linea LIKE '%Ã%'
    ),

    COUNT(DISTINCT estacion) FILTER (
        WHERE estacion LIKE '%Ã%'
    )

FROM proyecto.metro_desglosada_stage;


-- =========================================================
-- 15. EJEMPLOS DE MOJIBAKE
-- =========================================================

SELECT DISTINCT
    linea,
    estacion
FROM proyecto.metro_simple_stage
WHERE linea LIKE '%Ã%'
   OR estacion LIKE '%Ã%'
ORDER BY linea, estacion
LIMIT 30;


SELECT DISTINCT
    linea,
    estacion
FROM proyecto.metro_desglosada_stage
WHERE linea LIKE '%Ã%'
   OR estacion LIKE '%Ã%'
ORDER BY linea, estacion
LIMIT 30;


-- =========================================================
-- 16. DUPLICADOS EXACTOS - SIMPLE
-- =========================================================

WITH grupos AS (
    SELECT
        fecha,
        anio,
        mes,
        linea,
        estacion,
        afluencia,
        COUNT(*) AS veces
    FROM proyecto.metro_simple_stage
    GROUP BY
        fecha,
        anio,
        mes,
        linea,
        estacion,
        afluencia
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_duplicados_exactos,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes
FROM grupos;


-- =========================================================
-- 17. DUPLICADOS EXACTOS - DESGLOSADA
-- =========================================================

WITH grupos AS (
    SELECT
        fecha,
        mes,
        anio,
        linea,
        estacion,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces
    FROM proyecto.metro_desglosada_stage
    GROUP BY
        fecha,
        mes,
        anio,
        linea,
        estacion,
        tipo_pago,
        afluencia
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_duplicados_exactos,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes
FROM grupos;


-- =========================================================
-- 18. COLISIONES DE GRANULARIDAD - SIMPLE
-- fecha + linea + estacion
-- =========================================================

WITH grupos AS (
    SELECT
        fecha,
        linea,
        estacion,
        COUNT(*) AS veces
    FROM proyecto.metro_simple_stage
    GROUP BY
        fecha,
        linea,
        estacion
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes,
    COALESCE(MAX(veces), 0) AS max_repeticiones
FROM grupos;


-- =========================================================
-- 19. COLISIONES DE GRANULARIDAD - DESGLOSADA
-- fecha + linea + estacion + tipo_pago
-- =========================================================

WITH grupos AS (
    SELECT
        fecha,
        linea,
        estacion,
        tipo_pago,
        COUNT(*) AS veces
    FROM proyecto.metro_desglosada_stage
    GROUP BY
        fecha,
        linea,
        estacion,
        tipo_pago
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes,
    COALESCE(MAX(veces), 0) AS max_repeticiones
FROM grupos;