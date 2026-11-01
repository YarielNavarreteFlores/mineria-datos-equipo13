/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metrobús

    VALIDACIÓN INTEGRAL DEL PIPELINE

    RAW / MANIFEST
          ↓
       STAGING
          ↓
       PERFILADO
          ↓
        TYPED
          ↓
        CLEAN

    Objetivo:
    comprobar que el pipeline conserva registros,
    tipos, semántica, granularidad y relaciones
    previamente demostradas durante el perfilado.

    IMPORTANTE:
    - Este script NO modifica datos.
    - No elimina registros.
    - No corrige valores.
    - No modifica RAW, STAGING, TYPED ni CLEAN.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual,
    version() AS version_postgresql;


-- =========================================================
-- 2. CONTEOS DE TODAS LAS CAPAS
-- =========================================================

SELECT
    'Simple STAGING' AS capa,
    COUNT(*) AS registros
FROM proyecto.metrobus_simple_stage

UNION ALL

SELECT
    'Simple TYPED',
    COUNT(*)
FROM proyecto.metrobus_simple_typed

UNION ALL

SELECT
    'Simple CLEAN',
    COUNT(*)
FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada STAGING',
    COUNT(*)
FROM proyecto.metrobus_desglosada_stage

UNION ALL

SELECT
    'Desglosada TYPED',
    COUNT(*)
FROM proyecto.metrobus_desglosada_typed

UNION ALL

SELECT
    'Desglosada CLEAN',
    COUNT(*)
FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 3. CONCILIACIÓN SIMPLE
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_stage)
        AS stage,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_typed)
        AS typed,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_clean)
        AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.metrobus_simple_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.metrobus_simple_stage)
    ) AS diferencia_stage_clean;


-- =========================================================
-- 4. CONCILIACIÓN DESGLOSADA
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.metrobus_desglosada_stage)
        AS stage,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_desglosada_typed)
        AS typed,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_desglosada_clean)
        AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.metrobus_desglosada_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.metrobus_desglosada_stage)
    ) AS diferencia_stage_clean;


-- =========================================================
-- 5. TRAZABILIDAD NaN -> NULL
--
-- STAGING conserva el literal original.
-- TYPED/CLEAN contienen su interpretación semántica.
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_stage
     WHERE LOWER(BTRIM(afluencia)) = 'nan')
        AS nan_stage,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_typed
     WHERE afluencia IS NULL)
        AS null_typed,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_clean
     WHERE afluencia IS NULL)
        AS null_clean,

    (SELECT COUNT(*)
     FROM proyecto.metrobus_simple_clean
     WHERE es_afluencia_no_disponible)
        AS bandera_no_disponible;


-- =========================================================
-- 6. NULL EN CAMPOS CRÍTICOS - SIMPLE
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE fecha IS NULL
    ) AS fecha_null,

    COUNT(*) FILTER (
        WHERE anio IS NULL
    ) AS anio_null,

    COUNT(*) FILTER (
        WHERE mes IS NULL
    ) AS mes_null,

    COUNT(*) FILTER (
        WHERE linea IS NULL
    ) AS linea_null,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null

FROM proyecto.metrobus_simple_clean;


-- =========================================================
-- 7. NULL EN CAMPOS CRÍTICOS - DESGLOSADA
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE fecha IS NULL
    ) AS fecha_null,

    COUNT(*) FILTER (
        WHERE anio IS NULL
    ) AS anio_null,

    COUNT(*) FILTER (
        WHERE mes IS NULL
    ) AS mes_null,

    COUNT(*) FILTER (
        WHERE linea IS NULL
    ) AS linea_null,

    COUNT(*) FILTER (
        WHERE tipo_pago IS NULL
    ) AS tipo_pago_null,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 8. COHERENCIA TEMPORAL
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE anio <>
              EXTRACT(YEAR FROM fecha)::SMALLINT
    ) AS error_anio,

    COUNT(*) FILTER (
        WHERE mes_num <>
              EXTRACT(MONTH FROM fecha)::SMALLINT
    ) AS error_mes,

    COUNT(*) FILTER (
        WHERE dia_semana_num <>
              EXTRACT(ISODOW FROM fecha)::SMALLINT
    ) AS error_dia_semana

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE anio <>
              EXTRACT(YEAR FROM fecha)::SMALLINT
    ),

    COUNT(*) FILTER (
        WHERE mes_num <>
              EXTRACT(MONTH FROM fecha)::SMALLINT
    ),

    COUNT(*) FILTER (
        WHERE dia_semana_num <>
              EXTRACT(ISODOW FROM fecha)::SMALLINT
    )

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 9. COBERTURA TEMPORAL
-- =========================================================

SELECT
    'Simple' AS fuente,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,
    COUNT(DISTINCT fecha) AS fechas_distintas
FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',
    MIN(fecha),
    MAX(fecha),
    COUNT(DISTINCT fecha)
FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 10. DOMINIO DE LÍNEAS
-- =========================================================

SELECT
    'Simple' AS fuente,
    linea,
    COUNT(*) AS registros
FROM proyecto.metrobus_simple_clean
GROUP BY linea

UNION ALL

SELECT
    'Desglosada',
    linea,
    COUNT(*)
FROM proyecto.metrobus_desglosada_clean
GROUP BY linea

ORDER BY
    fuente,
    linea;


-- =========================================================
-- 11. VALIDACIÓN DE DOMINIO CANÓNICO DE LÍNEAS
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(DISTINCT linea) AS lineas_distintas,

    COUNT(*) FILTER (
        WHERE linea NOT IN (
            'Línea 1',
            'Línea 2',
            'Línea 3',
            'Línea 4',
            'Línea 5',
            'Línea 6',
            'Línea 7'
        )
    ) AS lineas_fuera_dominio

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',

    COUNT(DISTINCT linea),

    COUNT(*) FILTER (
        WHERE linea NOT IN (
            'Línea 1',
            'Línea 2',
            'Línea 3',
            'Línea 4',
            'Línea 5',
            'Línea 6',
            'Línea 7'
        )
    )

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 12. DOMINIO DE TIPO DE PAGO
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros
FROM proyecto.metrobus_desglosada_clean
GROUP BY tipo_pago
ORDER BY tipo_pago;


-- =========================================================
-- 13. VALORES DECIMALES CONSERVADOS
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE afluencia IS NOT NULL
          AND afluencia <> TRUNC(afluencia)
    ) AS valores_decimales

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE afluencia IS NOT NULL
          AND afluencia <> TRUNC(afluencia)
    )

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 14. DUPLICADOS EXACTOS - CLEAN SIMPLE
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        anio,
        mes,
        linea,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.metrobus_simple_clean

    GROUP BY
        fecha,
        anio,
        mes,
        linea,
        afluencia

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_duplicados_exactos,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes

FROM grupos;


-- =========================================================
-- 15. DUPLICADOS EXACTOS - CLEAN DESGLOSADA
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        anio,
        mes,
        linea,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.metrobus_desglosada_clean

    GROUP BY
        fecha,
        anio,
        mes,
        linea,
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
-- 16. GRANULARIDAD CLEAN - SIMPLE
--
-- fecha × linea
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        COUNT(*) AS veces

    FROM proyecto.metrobus_simple_clean

    GROUP BY
        fecha,
        linea

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(MAX(veces), 0) AS max_repeticiones

FROM grupos;


-- =========================================================
-- 17. GRANULARIDAD CLEAN - DESGLOSADA
--
-- fecha × linea × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.metrobus_desglosada_clean

    GROUP BY
        fecha,
        linea,
        tipo_pago

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(MAX(veces), 0) AS max_repeticiones

FROM grupos;


-- =========================================================
-- 18. FLAGS DE CALIDAD
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ) AS no_disponibles,

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS ceros,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS colisiones,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS outliers,

    COUNT(*) FILTER (
        WHERE es_linea_homologada
    ) AS lineas_homologadas

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ),

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
        WHERE es_linea_homologada
    )

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 19. RELACIÓN NULL ↔ BANDERA NO DISPONIBLE
-- =========================================================

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE
            (afluencia IS NULL)
            IS DISTINCT FROM
            es_afluencia_no_disponible
    ) AS inconsistencias

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE
            (afluencia IS NULL)
            IS DISTINCT FROM
            es_afluencia_no_disponible
    )

FROM proyecto.metrobus_desglosada_clean;


-- =========================================================
-- 20. RECONCILIACIÓN SIMPLE VS DESGLOSADA
--
-- En el periodo común:
-- Simple.afluencia debe coincidir con
-- SUM(Desglosada.afluencia).
-- =========================================================

WITH simple AS (

    SELECT
        fecha,
        linea,
        afluencia AS afluencia_simple

    FROM proyecto.metrobus_simple_clean

    WHERE afluencia IS NOT NULL
),

desglosada AS (

    SELECT
        fecha,
        linea,
        SUM(afluencia) AS afluencia_desglosada

    FROM proyecto.metrobus_desglosada_clean

    GROUP BY
        fecha,
        linea
),

comparacion AS (

    SELECT
        s.fecha,
        s.linea,

        s.afluencia_simple,

        d.afluencia_desglosada,

        s.afluencia_simple
        - d.afluencia_desglosada
            AS diferencia

    FROM simple AS s

    INNER JOIN desglosada AS d
        ON s.fecha = d.fecha
       AND s.linea = d.linea
)

SELECT
    COUNT(*) AS claves_comparables,

    COUNT(*) FILTER (
        WHERE diferencia = 0
    ) AS coincidencias_exactas,

    COUNT(*) FILTER (
        WHERE diferencia <> 0
    ) AS diferencias,

    MIN(diferencia) AS diferencia_min,

    AVG(diferencia)::numeric(20,6)
        AS diferencia_media,

    MAX(diferencia) AS diferencia_max

FROM comparacion;


-- =========================================================
-- 21. VALIDACIÓN AUTOMÁTICA FINAL
-- =========================================================

DO $$
DECLARE
    simple_stage          BIGINT;
    simple_typed          BIGINT;
    simple_clean          BIGINT;

    desg_stage            BIGINT;
    desg_typed            BIGINT;
    desg_clean            BIGINT;

    simple_null           BIGINT;
    desg_null             BIGINT;

    simple_outliers       BIGINT;
    desg_outliers         BIGINT;

    simple_colisiones     BIGINT;
    desg_colisiones       BIGINT;

    simple_lineas         BIGINT;
    desg_lineas           BIGINT;

    tipos_pago            BIGINT;

    simple_decimales      BIGINT;
    desg_decimales        BIGINT;

    comparables           BIGINT;
    coincidencias         BIGINT;
    diferencias           BIGINT;

BEGIN

    -- -----------------------------------------------------
    -- Conteos
    -- -----------------------------------------------------

    SELECT COUNT(*) INTO simple_stage
    FROM proyecto.metrobus_simple_stage;

    SELECT COUNT(*) INTO simple_typed
    FROM proyecto.metrobus_simple_typed;

    SELECT COUNT(*) INTO simple_clean
    FROM proyecto.metrobus_simple_clean;


    SELECT COUNT(*) INTO desg_stage
    FROM proyecto.metrobus_desglosada_stage;

    SELECT COUNT(*) INTO desg_typed
    FROM proyecto.metrobus_desglosada_typed;

    SELECT COUNT(*) INTO desg_clean
    FROM proyecto.metrobus_desglosada_clean;


    IF simple_stage <> 54159
       OR simple_typed <> 54159
       OR simple_clean <> 54159 THEN

        RAISE EXCEPTION
            'Conciliación Simple incorrecta. STAGE: %, TYPED: %, CLEAN: %',
            simple_stage,
            simple_typed,
            simple_clean;

    END IF;


    IF desg_stage <> 29386
       OR desg_typed <> 29386
       OR desg_clean <> 29386 THEN

        RAISE EXCEPTION
            'Conciliación Desglosada incorrecta. STAGE: %, TYPED: %, CLEAN: %',
            desg_stage,
            desg_typed,
            desg_clean;

    END IF;


    -- -----------------------------------------------------
    -- NULL
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO simple_null
    FROM proyecto.metrobus_simple_clean
    WHERE afluencia IS NULL;


    SELECT COUNT(*)
    INTO desg_null
    FROM proyecto.metrobus_desglosada_clean
    WHERE afluencia IS NULL;


    IF simple_null <> 17227 THEN
        RAISE EXCEPTION
            'NULL Simple incorrectos: %',
            simple_null;
    END IF;


    IF desg_null <> 0 THEN
        RAISE EXCEPTION
            'NULL Desglosada inesperados: %',
            desg_null;
    END IF;


    -- -----------------------------------------------------
    -- Outliers
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO simple_outliers
    FROM proyecto.metrobus_simple_clean
    WHERE es_outlier_iqr_global;


    SELECT COUNT(*)
    INTO desg_outliers
    FROM proyecto.metrobus_desglosada_clean
    WHERE es_outlier_iqr_global;


    IF simple_outliers <> 3000
       OR desg_outliers <> 1090 THEN

        RAISE EXCEPTION
            'Outliers distintos al perfilado final. Simple: %, Desglosada: %',
            simple_outliers,
            desg_outliers;

    END IF;


    -- -----------------------------------------------------
    -- Colisiones
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO simple_colisiones
    FROM proyecto.metrobus_simple_clean
    WHERE es_colision_clave;


    SELECT COUNT(*)
    INTO desg_colisiones
    FROM proyecto.metrobus_desglosada_clean
    WHERE es_colision_clave;


    IF simple_colisiones <> 0
       OR desg_colisiones <> 0 THEN

        RAISE EXCEPTION
            'Colisiones CLEAN inesperadas. Simple: %, Desglosada: %',
            simple_colisiones,
            desg_colisiones;

    END IF;


    -- -----------------------------------------------------
    -- Líneas
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT linea)
    INTO simple_lineas
    FROM proyecto.metrobus_simple_clean;


    SELECT COUNT(DISTINCT linea)
    INTO desg_lineas
    FROM proyecto.metrobus_desglosada_clean;


    IF simple_lineas <> 7
       OR desg_lineas <> 7 THEN

        RAISE EXCEPTION
            'Dominio de líneas incorrecto. Simple: %, Desglosada: %',
            simple_lineas,
            desg_lineas;

    END IF;


    -- -----------------------------------------------------
    -- Tipo de pago
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT tipo_pago)
    INTO tipos_pago
    FROM proyecto.metrobus_desglosada_clean;


    IF tipos_pago <> 2 THEN
        RAISE EXCEPTION
            'Dominio tipo_pago incorrecto: %',
            tipos_pago;
    END IF;


    -- -----------------------------------------------------
    -- Decimales
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO simple_decimales
    FROM proyecto.metrobus_simple_clean
    WHERE afluencia IS NOT NULL
      AND afluencia <> TRUNC(afluencia);


    SELECT COUNT(*)
    INTO desg_decimales
    FROM proyecto.metrobus_desglosada_clean
    WHERE afluencia IS NOT NULL
      AND afluencia <> TRUNC(afluencia);


    IF simple_decimales <> 57
       OR desg_decimales <> 57 THEN

        RAISE EXCEPTION
            'Valores decimales inesperados. Simple: %, Desglosada: %',
            simple_decimales,
            desg_decimales;

    END IF;


    -- -----------------------------------------------------
    -- Compatibilidad Simple ↔ Desglosada
    -- -----------------------------------------------------

    WITH simple AS (

        SELECT
            fecha,
            linea,
            afluencia AS afluencia_simple

        FROM proyecto.metrobus_simple_clean

        WHERE afluencia IS NOT NULL
    ),

    desglosada AS (

        SELECT
            fecha,
            linea,
            SUM(afluencia) AS afluencia_desglosada

        FROM proyecto.metrobus_desglosada_clean

        GROUP BY
            fecha,
            linea
    ),

    comparacion AS (

        SELECT
            s.afluencia_simple
            - d.afluencia_desglosada
                AS diferencia

        FROM simple AS s

        INNER JOIN desglosada AS d
            ON s.fecha = d.fecha
           AND s.linea = d.linea
    )

    SELECT
        COUNT(*),
        COUNT(*) FILTER (
            WHERE diferencia = 0
        ),
        COUNT(*) FILTER (
            WHERE diferencia <> 0
        )

    INTO
        comparables,
        coincidencias,
        diferencias

    FROM comparacion;


    IF comparables <> 14693
       OR coincidencias <> 14693
       OR diferencias <> 0 THEN

        RAISE EXCEPTION
            'Reconciliación Simple-Desglosada incorrecta. Comparables: %, Coincidencias: %, Diferencias: %',
            comparables,
            coincidencias,
            diferencias;

    END IF;


    RAISE NOTICE
        'VALIDACIÓN METROBÚS OK. Simple: %, Desglosada: %, NULL Simple: %, Outliers: %/%, líneas: %/%, relación Simple-Desglosada: %/%',
        simple_clean,
        desg_clean,
        simple_null,
        simple_outliers,
        desg_outliers,
        simple_lineas,
        desg_lineas,
        coincidencias,
        comparables;

END
$$;