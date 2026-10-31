/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metro

    VALIDACIÓN INTEGRAL DEL PIPELINE

    RAW/MANIFEST -> STAGE -> TYPED -> CLEAN

    Este script no modifica información.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario,
    version() AS postgresql;


-- =========================================================
-- 2. CONTEOS POR CAPA
-- =========================================================

SELECT
    'Simple STAGE' AS capa,
    COUNT(*) AS registros
FROM proyecto.metro_simple_stage

UNION ALL

SELECT
    'Simple TYPED',
    COUNT(*)
FROM proyecto.metro_simple_typed

UNION ALL

SELECT
    'Simple CLEAN',
    COUNT(*)
FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Desglosada STAGE',
    COUNT(*)
FROM proyecto.metro_desglosada_stage

UNION ALL

SELECT
    'Desglosada TYPED',
    COUNT(*)
FROM proyecto.metro_desglosada_typed

UNION ALL

SELECT
    'Desglosada CLEAN',
    COUNT(*)
FROM proyecto.metro_desglosada_clean;


-- =========================================================
-- 3. CONCILIACIÓN SIMPLE
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM proyecto.metro_simple_stage)
        AS stage,

    (SELECT COUNT(*) FROM proyecto.metro_simple_typed)
        AS typed,

    (SELECT COUNT(*) FROM proyecto.metro_simple_clean)
        AS clean,

    (SELECT COUNT(*) FROM proyecto.metro_simple_clean)
      - (SELECT COUNT(*) FROM proyecto.metro_simple_stage)
        AS diferencia_stage_clean;


-- =========================================================
-- 4. CONCILIACIÓN DESGLOSADA
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM proyecto.metro_desglosada_stage)
        AS stage,

    (SELECT COUNT(*) FROM proyecto.metro_desglosada_typed)
        AS typed,

    (SELECT COUNT(*) FROM proyecto.metro_desglosada_clean)
        AS clean,

    (SELECT COUNT(*) FROM proyecto.metro_desglosada_clean)
      - (SELECT COUNT(*) FROM proyecto.metro_desglosada_stage)
        AS diferencia_stage_clean;


-- =========================================================
-- 5. MOJIBAKE RESIDUAL
-- =========================================================

SELECT
    'Metro Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE linea LIKE '%Ã%'
    ) AS linea_mojibake,

    COUNT(*) FILTER (
        WHERE estacion LIKE '%Ã%'
    ) AS estacion_mojibake

FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Metro Desglosada',

    COUNT(*) FILTER (
        WHERE linea LIKE '%Ã%'
    ),

    COUNT(*) FILTER (
        WHERE estacion LIKE '%Ã%'
    )

FROM proyecto.metro_desglosada_clean;


-- =========================================================
-- 6. NULL EN CAMPOS CRÍTICOS
-- =========================================================

SELECT
    'Metro Simple' AS fuente,

    COUNT(*) FILTER (WHERE fecha IS NULL) AS fecha_null,
    COUNT(*) FILTER (WHERE anio IS NULL) AS anio_null,
    COUNT(*) FILTER (WHERE linea IS NULL) AS linea_null,
    COUNT(*) FILTER (WHERE estacion IS NULL) AS estacion_null,
    COUNT(*) FILTER (WHERE afluencia IS NULL) AS afluencia_null

FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Metro Desglosada',

    COUNT(*) FILTER (WHERE fecha IS NULL),
    COUNT(*) FILTER (WHERE anio IS NULL),
    COUNT(*) FILTER (WHERE linea IS NULL),
    COUNT(*) FILTER (WHERE estacion IS NULL),
    COUNT(*) FILTER (WHERE afluencia IS NULL)

FROM proyecto.metro_desglosada_clean;


-- =========================================================
-- 7. COHERENCIA TEMPORAL CLEAN
-- =========================================================

SELECT
    'Metro Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE anio <> EXTRACT(YEAR FROM fecha)::SMALLINT
    ) AS error_anio,

    COUNT(*) FILTER (
        WHERE mes_num <> EXTRACT(MONTH FROM fecha)::SMALLINT
    ) AS error_mes,

    COUNT(*) FILTER (
        WHERE dia_semana_num <> EXTRACT(ISODOW FROM fecha)::SMALLINT
    ) AS error_dia_semana

FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Metro Desglosada',

    COUNT(*) FILTER (
        WHERE anio <> EXTRACT(YEAR FROM fecha)::SMALLINT
    ),

    COUNT(*) FILTER (
        WHERE mes_num <> EXTRACT(MONTH FROM fecha)::SMALLINT
    ),

    COUNT(*) FILTER (
        WHERE dia_semana_num <> EXTRACT(ISODOW FROM fecha)::SMALLINT
    )

FROM proyecto.metro_desglosada_clean;


-- =========================================================
-- 8. DOMINIOS PRINCIPALES
-- =========================================================

SELECT
    'Simple' AS fuente,
    COUNT(DISTINCT linea) AS lineas_distintas,
    NULL::bigint AS tipos_pago_distintos
FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Desglosada',
    COUNT(DISTINCT linea),
    COUNT(DISTINCT tipo_pago)
FROM proyecto.metro_desglosada_clean;


-- =========================================================
-- 9. FLAGS DE CALIDAD
-- =========================================================

SELECT
    'Metro Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS afluencia_cero,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS filas_con_colision,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers,

    COUNT(*) FILTER (
        WHERE es_texto_corregido
    ) AS texto_corregido

FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Metro Desglosada',

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ),

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ),

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ),

    COUNT(*) FILTER (
        WHERE es_texto_corregido
    )

FROM proyecto.metro_desglosada_clean;


-- =========================================================
-- 10. RESUMEN AUTOMÁTICO
-- =========================================================

SELECT
    'SIMPLE_STAGE' AS prueba,
    (SELECT COUNT(*) FROM proyecto.metro_simple_stage)::text
        AS resultado,
    '1180920' AS esperado,
    CASE
        WHEN (SELECT COUNT(*) FROM proyecto.metro_simple_stage)
             = 1180920
        THEN 'OK'
        ELSE 'REVISAR'
    END AS estado

UNION ALL

SELECT
    'SIMPLE_TYPED',
    (SELECT COUNT(*) FROM proyecto.metro_simple_typed)::text,
    '1180920',
    CASE
        WHEN (SELECT COUNT(*) FROM proyecto.metro_simple_typed)
             = 1180920
        THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'SIMPLE_CLEAN',
    (SELECT COUNT(*) FROM proyecto.metro_simple_clean)::text,
    '1180920',
    CASE
        WHEN (SELECT COUNT(*) FROM proyecto.metro_simple_clean)
             = 1180920
        THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'DESGLOSADA_STAGE',
    (SELECT COUNT(*) FROM proyecto.metro_desglosada_stage)::text,
    '1192230',
    CASE
        WHEN (SELECT COUNT(*) FROM proyecto.metro_desglosada_stage)
             = 1192230
        THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'DESGLOSADA_TYPED',
    (SELECT COUNT(*) FROM proyecto.metro_desglosada_typed)::text,
    '1192230',
    CASE
        WHEN (SELECT COUNT(*) FROM proyecto.metro_desglosada_typed)
             = 1192230
        THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'DESGLOSADA_CLEAN',
    (SELECT COUNT(*) FROM proyecto.metro_desglosada_clean)::text,
    '1192230',
    CASE
        WHEN (SELECT COUNT(*) FROM proyecto.metro_desglosada_clean)
             = 1192230
        THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'MOJIBAKE_SIMPLE',
    (
        SELECT (
            COUNT(*) FILTER (WHERE linea LIKE '%Ã%')
            +
            COUNT(*) FILTER (WHERE estacion LIKE '%Ã%')
        )::text
        FROM proyecto.metro_simple_clean
    ),
    '0',
    CASE
        WHEN (
            SELECT
                COUNT(*) FILTER (WHERE linea LIKE '%Ã%')
                +
                COUNT(*) FILTER (WHERE estacion LIKE '%Ã%')
            FROM proyecto.metro_simple_clean
        ) = 0
        THEN 'OK'
        ELSE 'REVISAR'
    END

UNION ALL

SELECT
    'MOJIBAKE_DESGLOSADA',
    (
        SELECT (
            COUNT(*) FILTER (WHERE linea LIKE '%Ã%')
            +
            COUNT(*) FILTER (WHERE estacion LIKE '%Ã%')
        )::text
        FROM proyecto.metro_desglosada_clean
    ),
    '0',
    CASE
        WHEN (
            SELECT
                COUNT(*) FILTER (WHERE linea LIKE '%Ã%')
                +
                COUNT(*) FILTER (WHERE estacion LIKE '%Ã%')
            FROM proyecto.metro_desglosada_clean
        ) = 0
        THEN 'OK'
        ELSE 'REVISAR'
    END;