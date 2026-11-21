/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Cablebús

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
    comprobar que el pipeline de Cablebús conserva
    registros, granularidad, dominios, semántica y los
    hallazgos de calidad demostrados durante el perfilado.

    RESULTADOS ESPERADOS:
    - STAGING: 7,972
    - TYPED:   7,972
    - CLEAN:   7,972
    - pérdida: 0

    - NULL afluencia: 0
    - ceros: 207
    - negativos: 0
    - decimales: 0

    - 3 líneas lógicas
    - 2 tipos de pago
    - 0 duplicados exactos
    - 0 colisiones
    - 0 outliers IQR globales
    - 4,864 filas homologadas

    Granularidad validada:
        fecha × linea × tipo_pago

    IMPORTANTE:
    - Este script NO modifica datos.
    - No elimina registros.
    - No corrige valores.
    - No altera STAGING, TYPED ni CLEAN.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual,
    version() AS version_postgresql;


-- =========================================================
-- 2. CONTEOS POR CAPA
-- =========================================================

SELECT
    'STAGING' AS capa,
    COUNT(*) AS registros
FROM proyecto.cablebus_desglosada_stage

UNION ALL

SELECT
    'TYPED',
    COUNT(*)
FROM proyecto.cablebus_desglosada_typed

UNION ALL

SELECT
    'CLEAN',
    COUNT(*)
FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 3. CONCILIACIÓN STAGING -> TYPED -> CLEAN
-- =========================================================

SELECT
    (SELECT COUNT(*)
     FROM proyecto.cablebus_desglosada_stage)
        AS staging,

    (SELECT COUNT(*)
     FROM proyecto.cablebus_desglosada_typed)
        AS typed,

    (SELECT COUNT(*)
     FROM proyecto.cablebus_desglosada_clean)
        AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.cablebus_desglosada_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.cablebus_desglosada_stage)
    ) AS diferencia_stage_clean;


-- =========================================================
-- 4. NULL EN CAMPOS CRÍTICOS CLEAN
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
        WHERE linea_original IS NULL
    ) AS linea_original_null,

    COUNT(*) FILTER (
        WHERE linea IS NULL
    ) AS linea_null,

    COUNT(*) FILTER (
        WHERE tipo_pago IS NULL
    ) AS tipo_pago_null,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 5. COHERENCIA TEMPORAL
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

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 6. COBERTURA TEMPORAL
-- =========================================================

SELECT
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,
    COUNT(DISTINCT fecha) AS fechas_distintas,
    MIN(anio) AS anio_min,
    MAX(anio) AS anio_max

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 7. DOMINIO DE LINEA CLEAN
-- =========================================================

SELECT
    linea,
    COUNT(*) AS registros,
    COUNT(DISTINCT fecha) AS dias_con_registro,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max

FROM proyecto.cablebus_desglosada_clean

GROUP BY linea
ORDER BY linea;


-- =========================================================
-- 8. VALIDACIÓN DEL DOMINIO CANÓNICO DE LINEA
-- =========================================================

SELECT
    COUNT(DISTINCT linea)
        AS lineas_distintas,

    COUNT(*) FILTER (
        WHERE linea NOT IN (
            'Linea 1',
            'Linea 2',
            'Linea 3'
        )
    ) AS lineas_fuera_dominio

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 9. TRAZABILIDAD DE HOMOLOGACIÓN
-- =========================================================

SELECT
    linea_original,
    linea,
    COUNT(*) AS registros

FROM proyecto.cablebus_desglosada_clean

GROUP BY
    linea_original,
    linea

ORDER BY
    linea,
    linea_original;


SELECT
    COUNT(*) FILTER (
        WHERE es_linea_homologada
    ) AS filas_homologadas,

    COUNT(*) FILTER (
        WHERE NOT es_linea_homologada
    ) AS filas_sin_homologar,

    COUNT(*) AS total

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 10. DOMINIO DE TIPO DE PAGO
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros

FROM proyecto.cablebus_desglosada_clean

GROUP BY tipo_pago
ORDER BY tipo_pago;


SELECT
    COUNT(DISTINCT tipo_pago)
        AS tipos_pago_distintos,

    COUNT(*) FILTER (
        WHERE tipo_pago NOT IN (
            'Gratuidad',
            'Prepago'
        )
    ) AS fuera_dominio

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 11. CEROS Y BANDERA
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
            (afluencia = 0)
            IS DISTINCT FROM
            es_afluencia_cero
    ) AS inconsistencias

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 12. NO DISPONIBILIDAD
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ) AS bandera_no_disponible,

    COUNT(*) FILTER (
        WHERE
            (afluencia IS NULL)
            IS DISTINCT FROM
            es_afluencia_no_disponible
    ) AS inconsistencias

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 13. DECIMALES Y NEGATIVOS
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE afluencia <> TRUNC(afluencia)
    ) AS valores_decimales,

    COUNT(*) FILTER (
        WHERE afluencia < 0
    ) AS valores_negativos

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 14. DUPLICADOS EXACTOS
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        anio,
        mes,
        linea_original,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.cablebus_desglosada_clean

    GROUP BY
        fecha,
        anio,
        mes,
        linea_original,
        tipo_pago,
        afluencia

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_duplicados_exactos,

    COALESCE(
        SUM(veces),
        0
    ) AS filas_involucradas,

    COALESCE(
        SUM(veces - 1),
        0
    ) AS registros_excedentes,

    COALESCE(
        MAX(veces),
        0
    ) AS max_repeticiones

FROM grupos;


-- =========================================================
-- 15. GRANULARIDAD CLEAN
--
-- fecha × linea × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.cablebus_desglosada_clean

    GROUP BY
        fecha,
        linea,
        tipo_pago

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,

    COALESCE(
        SUM(veces),
        0
    ) AS filas_involucradas,

    COALESCE(
        SUM(veces - 1),
        0
    ) AS registros_excedentes,

    COALESCE(
        MAX(veces),
        0
    ) AS max_repeticiones

FROM grupos;


-- =========================================================
-- 16. ESTRUCTURA fecha × linea
--
-- Deben existir exactamente:
-- 2 filas / 2 tipos_pago por cada clave fecha × linea.
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        COUNT(*) AS filas,
        COUNT(DISTINCT tipo_pago) AS tipos_pago

    FROM proyecto.cablebus_desglosada_clean

    GROUP BY
        fecha,
        linea
)

SELECT
    filas,
    tipos_pago,
    COUNT(*) AS claves_fecha_linea

FROM grupos

GROUP BY
    filas,
    tipos_pago

ORDER BY
    filas,
    tipos_pago;


-- =========================================================
-- 17. CONTEO DE CLAVES fecha × linea
-- =========================================================

SELECT
    COUNT(*) AS claves_fecha_linea

FROM (
    SELECT
        fecha,
        linea

    FROM proyecto.cablebus_desglosada_clean

    GROUP BY
        fecha,
        linea
) AS claves;


-- =========================================================
-- 18. OUTLIERS IQR
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 19. FLAGS DE CALIDAD
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ) AS no_disponibles,

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS ceros,

    COUNT(*) FILTER (
        WHERE es_colision_clave_origen
    ) AS filas_colision_origen,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS filas_colision_clean,

    COUNT(*) FILTER (
        WHERE es_duplicado_exacto
    ) AS filas_duplicado_exacto,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers,

    COUNT(*) FILTER (
        WHERE es_linea_homologada
    ) AS filas_linea_homologada

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 20. RANGO DE AFLUENCIA
-- =========================================================

SELECT
    MIN(afluencia) AS afluencia_min,
    MAX(afluencia) AS afluencia_max,
    AVG(afluencia)::numeric(20,2) AS afluencia_media

FROM proyecto.cablebus_desglosada_clean;


-- =========================================================
-- 21. COBERTURA POR LINEA LÓGICA
-- =========================================================

SELECT
    linea,
    COUNT(DISTINCT fecha) AS dias_con_registro,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max

FROM proyecto.cablebus_desglosada_clean

GROUP BY linea
ORDER BY linea;


-- =========================================================
-- 22. VALIDACIÓN AUTOMÁTICA FINAL
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

    lineas_count         BIGINT;
    payment_count        BIGINT;

    collision_rows       BIGINT;
    collision_groups     BIGINT;

    duplicate_rows       BIGINT;
    duplicate_groups     BIGINT;

    outlier_count        BIGINT;
    homologated_count    BIGINT;

    temporal_errors      BIGINT;

    fecha_count          BIGINT;
    fecha_linea_count    BIGINT;

BEGIN

    -- -----------------------------------------------------
    -- Conteos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO stage_count
    FROM proyecto.cablebus_desglosada_stage;

    SELECT COUNT(*)
    INTO typed_count
    FROM proyecto.cablebus_desglosada_typed;

    SELECT COUNT(*)
    INTO clean_count
    FROM proyecto.cablebus_desglosada_clean;


    IF stage_count <> 7972
       OR typed_count <> 7972
       OR clean_count <> 7972 THEN

        RAISE EXCEPTION
            'Conciliación Cablebus incorrecta. STAGE: %, TYPED: %, CLEAN: %',
            stage_count,
            typed_count,
            clean_count;

    END IF;


    -- -----------------------------------------------------
    -- NULL / ceros / decimales / negativos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO null_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE afluencia IS NULL;


    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE afluencia = 0;


    SELECT COUNT(*)
    INTO decimal_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE afluencia <> TRUNC(afluencia);


    SELECT COUNT(*)
    INTO negative_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE afluencia < 0;


    IF null_count <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados: %',
            null_count;
    END IF;


    IF zero_count <> 207 THEN
        RAISE EXCEPTION
            'Ceros incorrectos. Esperado: 207. Obtenido: %',
            zero_count;
    END IF;


    IF decimal_count <> 0 THEN
        RAISE EXCEPTION
            'Decimales inesperados: %',
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

    SELECT COUNT(DISTINCT linea)
    INTO lineas_count
    FROM proyecto.cablebus_desglosada_clean;


    SELECT COUNT(DISTINCT tipo_pago)
    INTO payment_count
    FROM proyecto.cablebus_desglosada_clean;


    IF lineas_count <> 3 THEN
        RAISE EXCEPTION
            'Dominio de linea incorrecto. Esperadas: 3. Obtenidas: %',
            lineas_count;
    END IF;


    IF payment_count <> 2 THEN
        RAISE EXCEPTION
            'Dominio de tipo_pago incorrecto. Esperados: 2. Obtenidos: %',
            payment_count;
    END IF;


    -- -----------------------------------------------------
    -- Colisiones
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO collision_rows
    FROM proyecto.cablebus_desglosada_clean
    WHERE es_colision_clave;


    WITH grupos AS (

        SELECT
            fecha,
            linea,
            tipo_pago

        FROM proyecto.cablebus_desglosada_clean

        GROUP BY
            fecha,
            linea,
            tipo_pago

        HAVING COUNT(*) > 1
    )

    SELECT COUNT(*)
    INTO collision_groups
    FROM grupos;


    IF collision_rows <> 0
       OR collision_groups <> 0 THEN

        RAISE EXCEPTION
            'Colisiones inesperadas. Grupos: %, filas: %',
            collision_groups,
            collision_rows;

    END IF;


    -- -----------------------------------------------------
    -- Duplicados
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO duplicate_rows
    FROM proyecto.cablebus_desglosada_clean
    WHERE es_duplicado_exacto;


    WITH grupos AS (

        SELECT
            fecha,
            anio,
            mes,
            linea_original,
            tipo_pago,
            afluencia

        FROM proyecto.cablebus_desglosada_clean

        GROUP BY
            fecha,
            anio,
            mes,
            linea_original,
            tipo_pago,
            afluencia

        HAVING COUNT(*) > 1
    )

    SELECT COUNT(*)
    INTO duplicate_groups
    FROM grupos;


    IF duplicate_rows <> 0
       OR duplicate_groups <> 0 THEN

        RAISE EXCEPTION
            'Duplicados inesperados. Grupos: %, filas: %',
            duplicate_groups,
            duplicate_rows;

    END IF;


    -- -----------------------------------------------------
    -- Outliers
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO outlier_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE es_outlier_iqr_global;


    IF outlier_count <> 0 THEN
        RAISE EXCEPTION
            'Outliers diferentes al perfilado. Esperado: 0. Obtenido: %',
            outlier_count;
    END IF;


    -- -----------------------------------------------------
    -- Homologación
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO homologated_count
    FROM proyecto.cablebus_desglosada_clean
    WHERE es_linea_homologada;


    IF homologated_count <> 4864 THEN
        RAISE EXCEPTION
            'Filas homologadas incorrectas. Esperado: 4864. Obtenido: %',
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

    FROM proyecto.cablebus_desglosada_clean;


    IF temporal_errors <> 0 THEN
        RAISE EXCEPTION
            'Errores temporales CLEAN: %',
            temporal_errors;
    END IF;


    -- -----------------------------------------------------
    -- Cobertura
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT fecha)
    INTO fecha_count
    FROM proyecto.cablebus_desglosada_clean;


    IF fecha_count <> 1734 THEN
        RAISE EXCEPTION
            'Fechas distintas incorrectas. Esperado: 1734. Obtenido: %',
            fecha_count;
    END IF;


    -- -----------------------------------------------------
    -- Claves fecha × linea
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO fecha_linea_count

    FROM (
        SELECT
            fecha,
            linea

        FROM proyecto.cablebus_desglosada_clean

        GROUP BY
            fecha,
            linea
    ) AS x;


    IF fecha_linea_count <> 3986 THEN
        RAISE EXCEPTION
            'Claves fecha x linea incorrectas. Esperado: 3986. Obtenido: %',
            fecha_linea_count;
    END IF;


    -- -----------------------------------------------------
    -- Resultado
    -- -----------------------------------------------------

    RAISE NOTICE
        'VALIDACIÓN CABLEBUS OK. Filas: %, NULL: %, ceros: %, lineas: %, pagos: %, colisiones: %, duplicados: %, outliers: %, homologadas: %, fechas: %, claves fecha-linea: %',
        clean_count,
        null_count,
        zero_count,
        lineas_count,
        payment_count,
        collision_groups,
        duplicate_groups,
        outlier_count,
        homologated_count,
        fecha_count,
        fecha_linea_count;

END
$$;