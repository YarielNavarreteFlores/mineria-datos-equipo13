/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: RTP

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
    comprobar que el pipeline RTP conserva registros,
    tipos, semántica y todos los hallazgos de calidad
    demostrados durante el perfilado.

    IMPORTANTE:
    - Este script NO modifica datos.
    - No elimina registros.
    - No corrige valores.
    - No modifica STAGING, TYPED ni CLEAN.
    - Las colisiones de ATENEA se preservan.
    - Los duplicados exactos se preservan.
    - Los outliers se preservan.
    - NULL != 0.
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
    'STAGING' AS capa,
    COUNT(*) AS registros
FROM proyecto.rtp_desglosada_stage

UNION ALL

SELECT
    'TYPED',
    COUNT(*)
FROM proyecto.rtp_desglosada_typed

UNION ALL

SELECT
    'CLEAN',
    COUNT(*)
FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 3. CONCILIACIÓN STAGING -> TYPED -> CLEAN
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.rtp_desglosada_stage)
        AS staging,

    (SELECT COUNT(*)
     FROM proyecto.rtp_desglosada_typed)
        AS typed,

    (SELECT COUNT(*)
     FROM proyecto.rtp_desglosada_clean)
        AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.rtp_desglosada_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.rtp_desglosada_stage)
    ) AS diferencia_stage_clean;


-- =========================================================
-- 4. TRAZABILIDAD NaN -> NULL
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.rtp_desglosada_stage
        WHERE LOWER(BTRIM(afluencia)) = 'nan'
    ) AS nan_stage,

    (
        SELECT COUNT(*)
        FROM proyecto.rtp_desglosada_typed
        WHERE afluencia IS NULL
    ) AS null_typed,

    (
        SELECT COUNT(*)
        FROM proyecto.rtp_desglosada_clean
        WHERE afluencia IS NULL
    ) AS null_clean,

    (
        SELECT COUNT(*)
        FROM proyecto.rtp_desglosada_clean
        WHERE es_afluencia_no_disponible
    ) AS bandera_no_disponible;


-- =========================================================
-- 5. NULL EN CAMPOS CRÍTICOS CLEAN
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
        WHERE servicio_original IS NULL
    ) AS servicio_original_null,

    COUNT(*) FILTER (
        WHERE servicio IS NULL
    ) AS servicio_null,

    COUNT(*) FILTER (
        WHERE tipo_pago IS NULL
    ) AS tipo_pago_null,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 6. COHERENCIA TEMPORAL
-- =========================================================

SELECT
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

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 7. COBERTURA TEMPORAL
-- =========================================================

SELECT
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,
    COUNT(DISTINCT fecha) AS fechas_distintas,
    MIN(anio) AS anio_min,
    MAX(anio) AS anio_max

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 8. DOMINIO DE TIPO DE PAGO
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros

FROM proyecto.rtp_desglosada_clean

GROUP BY tipo_pago
ORDER BY tipo_pago;


-- =========================================================
-- 9. VALIDACIÓN DEL DOMINIO DE TIPO DE PAGO
-- =========================================================

SELECT
    COUNT(DISTINCT tipo_pago) AS tipos_pago_distintos,

    COUNT(*) FILTER (
        WHERE tipo_pago NOT IN (
            'Boleto',
            'Gratuidad',
            'Prepago'
        )
    ) AS fuera_dominio

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 10. DOMINIO DE SERVICIO CLEAN
-- =========================================================

SELECT
    servicio,
    COUNT(*) AS registros,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max

FROM proyecto.rtp_desglosada_clean

GROUP BY servicio
ORDER BY servicio;


SELECT
    COUNT(DISTINCT servicio)
        AS servicios_distintos_clean

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 11. HOMOLOGACIÓN DE SERVICIO
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE es_servicio_homologado
    ) AS filas_homologadas,

    COUNT(*) FILTER (
        WHERE NOT es_servicio_homologado
    ) AS filas_sin_homologar,

    COUNT(*) AS total

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 12. CEROS
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE afluencia = 0
    ) AS ceros,

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS bandera_ceros,

    COUNT(*) FILTER (
        WHERE
            COALESCE(afluencia = 0, FALSE)
            IS DISTINCT FROM
            es_afluencia_cero
    ) AS inconsistencias

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 13. VALORES DECIMALES
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE afluencia IS NOT NULL
          AND afluencia <> TRUNC(afluencia)
    ) AS valores_decimales

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 14. VALORES NEGATIVOS
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE afluencia < 0
    ) AS valores_negativos

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 15. DUPLICADOS EXACTOS
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        anio,
        mes,
        servicio_original,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.rtp_desglosada_clean

    GROUP BY
        fecha,
        anio,
        mes,
        servicio_original,
        tipo_pago,
        afluencia

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_duplicados_exactos,

    COALESCE(SUM(veces), 0)
        AS filas_involucradas,

    COALESCE(SUM(veces - 1), 0)
        AS registros_excedentes,

    COALESCE(MAX(veces), 0)
        AS max_repeticiones

FROM grupos;


-- =========================================================
-- 16. COLISIONES EN GRANULARIDAD CANDIDATA
--
-- fecha × servicio × tipo_pago
--
-- Estas colisiones NO se eliminan.
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        servicio,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.rtp_desglosada_clean

    GROUP BY
        fecha,
        servicio,
        tipo_pago

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,

    COALESCE(SUM(veces), 0)
        AS filas_involucradas,

    COALESCE(SUM(veces - 1), 0)
        AS registros_excedentes,

    COALESCE(MAX(veces), 0)
        AS max_repeticiones

FROM grupos;


-- =========================================================
-- 17. COLISIONES: ORIGEN VS CLEAN
--
-- Deben permanecer iguales.
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE es_colision_clave_origen
    ) AS filas_colision_origen,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS filas_colision_clean,

    COUNT(*) FILTER (
        WHERE
            es_colision_clave_origen
            IS DISTINCT FROM
            es_colision_clave
    ) AS diferencias_bandera

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 18. COLISIONES POR SERVICIO
-- =========================================================

SELECT
    servicio,
    COUNT(*) AS filas_con_colision,
    MIN(fecha) AS primera_fecha,
    MAX(fecha) AS ultima_fecha

FROM proyecto.rtp_desglosada_clean

WHERE es_colision_clave

GROUP BY servicio
ORDER BY filas_con_colision DESC, servicio;


-- =========================================================
-- 19. COLISIONES DE ATENEA POR MES
-- =========================================================

SELECT
    EXTRACT(YEAR FROM fecha)::integer AS anio,
    EXTRACT(MONTH FROM fecha)::integer AS mes,
    COUNT(DISTINCT fecha) AS dias_afectados,
    COUNT(*) AS filas_afectadas

FROM proyecto.rtp_desglosada_clean

WHERE servicio = 'Atenea'
  AND es_colision_clave

GROUP BY
    EXTRACT(YEAR FROM fecha),
    EXTRACT(MONTH FROM fecha)

ORDER BY anio, mes;


-- =========================================================
-- 20. OUTLIERS
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 21. NULL ↔ BANDERA DE NO DISPONIBILIDAD
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE
            (afluencia IS NULL)
            IS DISTINCT FROM
            es_afluencia_no_disponible
    ) AS inconsistencias

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 22. FLAG DUPLICADO EXACTO
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE es_duplicado_exacto
    ) AS filas_marcadas_duplicado_exacto

FROM proyecto.rtp_desglosada_clean;


-- =========================================================
-- 23. CONTROL DEL SERVICIO ATENEA
-- =========================================================

SELECT
    COUNT(*) AS registros_atenea,
    COUNT(DISTINCT fecha) AS fechas_atenea,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS filas_con_colision,

    COUNT(*) FILTER (
        WHERE es_duplicado_exacto
    ) AS filas_duplicadas_exactas

FROM proyecto.rtp_desglosada_clean

WHERE servicio = 'Atenea';


-- =========================================================
-- 24. VALIDACIÓN AUTOMÁTICA FINAL
-- =========================================================

DO $$
DECLARE

    stage_count          BIGINT;
    typed_count          BIGINT;
    clean_count          BIGINT;

    null_count           BIGINT;
    zero_count           BIGINT;
    decimal_count        BIGINT;
    negative_count       BIGINT;

    services_count       BIGINT;
    payment_count        BIGINT;

    collision_rows       BIGINT;
    collision_groups     BIGINT;

    duplicate_rows       BIGINT;
    duplicate_groups     BIGINT;

    outlier_count        BIGINT;
    homologated_count    BIGINT;

    temporal_errors      BIGINT;

BEGIN

    -- -----------------------------------------------------
    -- Conteos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO stage_count
    FROM proyecto.rtp_desglosada_stage;

    SELECT COUNT(*)
    INTO typed_count
    FROM proyecto.rtp_desglosada_typed;

    SELECT COUNT(*)
    INTO clean_count
    FROM proyecto.rtp_desglosada_clean;


    IF stage_count <> 41676
       OR typed_count <> 41676
       OR clean_count <> 41676 THEN

        RAISE EXCEPTION
            'Conciliación RTP incorrecta. STAGE: %, TYPED: %, CLEAN: %',
            stage_count,
            typed_count,
            clean_count;

    END IF;


    -- -----------------------------------------------------
    -- NULL / ceros / decimales / negativos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO null_count
    FROM proyecto.rtp_desglosada_clean
    WHERE afluencia IS NULL;

    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.rtp_desglosada_clean
    WHERE afluencia = 0;

    SELECT COUNT(*)
    INTO decimal_count
    FROM proyecto.rtp_desglosada_clean
    WHERE afluencia IS NOT NULL
      AND afluencia <> TRUNC(afluencia);

    SELECT COUNT(*)
    INTO negative_count
    FROM proyecto.rtp_desglosada_clean
    WHERE afluencia < 0;


    IF null_count <> 187 THEN
        RAISE EXCEPTION
            'NULL incorrectos. Esperado: 187. Obtenido: %',
            null_count;
    END IF;

    IF zero_count <> 7450 THEN
        RAISE EXCEPTION
            'Ceros incorrectos. Esperado: 7450. Obtenido: %',
            zero_count;
    END IF;

    IF decimal_count <> 53 THEN
        RAISE EXCEPTION
            'Decimales incorrectos. Esperado: 53. Obtenido: %',
            decimal_count;
    END IF;

    IF negative_count <> 0 THEN
        RAISE EXCEPTION
            'Valores negativos inesperados: %',
            negative_count;
    END IF;


    -- -----------------------------------------------------
    -- Dominios
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT servicio)
    INTO services_count
    FROM proyecto.rtp_desglosada_clean;

    SELECT COUNT(DISTINCT tipo_pago)
    INTO payment_count
    FROM proyecto.rtp_desglosada_clean;


    IF services_count <> 21 THEN
        RAISE EXCEPTION
            'Servicios CLEAN incorrectos. Esperado: 21. Obtenido: %',
            services_count;
    END IF;

    IF payment_count <> 3 THEN
        RAISE EXCEPTION
            'Tipos de pago incorrectos. Esperado: 3. Obtenido: %',
            payment_count;
    END IF;


    -- -----------------------------------------------------
    -- Colisiones
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO collision_rows
    FROM proyecto.rtp_desglosada_clean
    WHERE es_colision_clave;


    WITH grupos AS (
        SELECT
            fecha,
            servicio,
            tipo_pago,
            COUNT(*) AS veces
        FROM proyecto.rtp_desglosada_clean
        GROUP BY
            fecha,
            servicio,
            tipo_pago
        HAVING COUNT(*) > 1
    )
    SELECT COUNT(*)
    INTO collision_groups
    FROM grupos;


    IF collision_rows <> 552
       OR collision_groups <> 276 THEN

        RAISE EXCEPTION
            'Colisiones inesperadas. Grupos: %, filas: %',
            collision_groups,
            collision_rows;

    END IF;


    -- -----------------------------------------------------
    -- Duplicados exactos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO duplicate_rows
    FROM proyecto.rtp_desglosada_clean
    WHERE es_duplicado_exacto;


    WITH grupos AS (
        SELECT
            fecha,
            anio,
            mes,
            servicio_original,
            tipo_pago,
            afluencia,
            COUNT(*) AS veces
        FROM proyecto.rtp_desglosada_clean
        GROUP BY
            fecha,
            anio,
            mes,
            servicio_original,
            tipo_pago,
            afluencia
        HAVING COUNT(*) > 1
    )
    SELECT COUNT(*)
    INTO duplicate_groups
    FROM grupos;


    IF duplicate_rows <> 162
       OR duplicate_groups <> 81 THEN

        RAISE EXCEPTION
            'Duplicados exactos inesperados. Grupos: %, filas: %',
            duplicate_groups,
            duplicate_rows;

    END IF;


    -- -----------------------------------------------------
    -- Outliers
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO outlier_count
    FROM proyecto.rtp_desglosada_clean
    WHERE es_outlier_iqr_global;


    IF outlier_count <> 4688 THEN
        RAISE EXCEPTION
            'Outliers distintos al perfilado. Esperado: 4688. Obtenido: %',
            outlier_count;
    END IF;


    -- -----------------------------------------------------
    -- Homologación
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO homologated_count
    FROM proyecto.rtp_desglosada_clean
    WHERE es_servicio_homologado;


    IF homologated_count <> 11640 THEN
        RAISE EXCEPTION
            'Filas homologadas inesperadas. Esperado: 11640. Obtenido: %',
            homologated_count;
    END IF;


    -- -----------------------------------------------------
    -- Coherencia temporal
    -- -----------------------------------------------------

    SELECT
        COUNT(*) FILTER (
            WHERE anio <>
                  EXTRACT(YEAR FROM fecha)::SMALLINT
        )
        +
        COUNT(*) FILTER (
            WHERE mes_num <>
                  EXTRACT(MONTH FROM fecha)::SMALLINT
        )
        +
        COUNT(*) FILTER (
            WHERE dia_semana_num <>
                  EXTRACT(ISODOW FROM fecha)::SMALLINT
        )

    INTO temporal_errors

    FROM proyecto.rtp_desglosada_clean;


    IF temporal_errors <> 0 THEN
        RAISE EXCEPTION
            'Errores temporales CLEAN: %',
            temporal_errors;
    END IF;


    -- -----------------------------------------------------
    -- Resultado
    -- -----------------------------------------------------

    RAISE NOTICE
        'VALIDACIÓN RTP OK. Filas: %, NULL: %, ceros: %, decimales: %, servicios: %, pagos: %, colisiones: % grupos/% filas, duplicados: % grupos/% filas, outliers: %, homologadas: %',
        clean_count,
        null_count,
        zero_count,
        decimal_count,
        services_count,
        payment_count,
        collision_groups,
        collision_rows,
        duplicate_groups,
        duplicate_rows,
        outlier_count,
        homologated_count;

END
$$;