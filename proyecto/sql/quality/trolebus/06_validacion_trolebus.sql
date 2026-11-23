/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Trolebús

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
    comprobar que el pipeline de Trolebús conserva
    registros, granularidad, dominios, precisión numérica,
    semántica y hallazgos de calidad demostrados durante
    el perfilado.

    RESULTADOS ESPERADOS:

    Conteos:
    - STAGING: 65,013
    - TYPED:   65,013
    - CLEAN:   65,013
    - pérdida: 0

    Calidad:
    - NULL afluencia: 0
    - ceros: 20,246
    - decimales: 1,419
    - negativos: 0
    - duplicados exactos: 0
    - colisiones: 0
    - posibles outliers IQR globales: 6,345

    Dominios:
    - 17 líneas CLEAN
    - 3 tipos de pago

    Homologación:
    - 62,268 filas homologadas
    - 2,745 filas ya estaban en representación canónica

    Cobertura:
    - 2022-01-01 -> 2026-10-31
    - 1,765 fechas distintas

    Estructura:
    - 21,671 claves fecha × linea
    - 3 filas por fecha × linea
    - 3 tipos de pago por fecha × linea

    Granularidad validada:

        fecha × linea × tipo_pago

    IMPORTANTE:
    - este script NO modifica datos;
    - no elimina registros;
    - no corrige valores;
    - no redondea afluencia;
    - no elimina ceros;
    - no elimina outliers;
    - no altera STAGING, TYPED ni CLEAN.
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
FROM proyecto.trolebus_desglosada_stage

UNION ALL

SELECT
    'TYPED',
    COUNT(*)
FROM proyecto.trolebus_desglosada_typed

UNION ALL

SELECT
    'CLEAN',
    COUNT(*)
FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 3. CONCILIACIÓN STAGING -> TYPED -> CLEAN
-- =========================================================

SELECT
    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_stage
    ) AS staging,

    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_typed
    ) AS typed,

    (
        SELECT COUNT(*)
        FROM proyecto.trolebus_desglosada_clean
    ) AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.trolebus_desglosada_clean)

        -

        (SELECT COUNT(*)
         FROM proyecto.trolebus_desglosada_stage)

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

FROM proyecto.trolebus_desglosada_clean;


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

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 6. COBERTURA TEMPORAL
-- =========================================================

SELECT
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,
    COUNT(DISTINCT fecha) AS fechas_distintas,
    MIN(anio) AS anio_min,
    MAX(anio) AS anio_max

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 7. DOMINIO CLEAN DE LINEA
-- =========================================================

SELECT
    linea,
    COUNT(*) AS registros,
    COUNT(DISTINCT fecha) AS dias_con_registro,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max

FROM proyecto.trolebus_desglosada_clean

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

            'Linea 0',

            'Linea 1',
            'Linea 1 Nochebus',

            'Linea 2',
            'Linea 3',
            'Linea 4',
            'Linea 5',
            'Linea 6',
            'Linea 7',
            'Linea 8',
            'Linea 9',

            'Linea 10',
            'Linea 10 (Trolebus elevado)',

            'Linea 11',
            'Linea 12',
            'Linea 13',
            'Linea 14'
        )
    ) AS lineas_fuera_dominio

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 9. TRAZABILIDAD DE HOMOLOGACIÓN
-- =========================================================

SELECT
    linea_original,
    linea,
    COUNT(*) AS registros

FROM proyecto.trolebus_desglosada_clean

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

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 10. DOMINIO DE TIPO DE PAGO
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros

FROM proyecto.trolebus_desglosada_clean

GROUP BY tipo_pago

ORDER BY tipo_pago;


SELECT
    COUNT(DISTINCT tipo_pago)
        AS tipos_pago_distintos,

    COUNT(*) FILTER (
        WHERE tipo_pago NOT IN (
            'Boleto',
            'Gratuidad',
            'Prepago'
        )
    ) AS fuera_dominio

FROM proyecto.trolebus_desglosada_clean;


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

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 12. DECIMALES Y BANDERA
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE afluencia <> TRUNC(afluencia)
    ) AS decimales,

    COUNT(*) FILTER (
        WHERE es_afluencia_decimal
    ) AS bandera_decimales,

    COUNT(*) FILTER (
        WHERE
            (
                afluencia <> TRUNC(afluencia)
            )
            IS DISTINCT FROM
            es_afluencia_decimal
    ) AS inconsistencias

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 13. NO DISPONIBILIDAD
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

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 14. NEGATIVOS
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE afluencia < 0
    ) AS valores_negativos

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 15. DUPLICADOS EXACTOS
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

    FROM proyecto.trolebus_desglosada_clean

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
-- 16. GRANULARIDAD CLEAN
--
-- fecha × linea × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.trolebus_desglosada_clean

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
-- 17. ESTRUCTURA fecha × linea
--
-- Deben existir:
-- 3 filas y 3 tipos_pago por cada clave fecha × linea.
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        linea,
        COUNT(*) AS filas,
        COUNT(DISTINCT tipo_pago) AS tipos_pago

    FROM proyecto.trolebus_desglosada_clean

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
-- 18. CONTEO DE CLAVES fecha × linea
-- =========================================================

SELECT
    COUNT(*) AS claves_fecha_linea

FROM (

    SELECT
        fecha,
        linea

    FROM proyecto.trolebus_desglosada_clean

    GROUP BY
        fecha,
        linea

) AS claves;


-- =========================================================
-- 19. OUTLIERS IQR
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 20. FLAGS DE CALIDAD
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE es_afluencia_no_disponible
    ) AS no_disponibles,

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS ceros,

    COUNT(*) FILTER (
        WHERE es_afluencia_decimal
    ) AS decimales,

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

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 21. RANGO DE AFLUENCIA
-- =========================================================

SELECT
    MIN(afluencia) AS afluencia_min,
    MAX(afluencia) AS afluencia_max,
    AVG(afluencia)::NUMERIC(30,6)
        AS afluencia_media

FROM proyecto.trolebus_desglosada_clean;


-- =========================================================
-- 22. PRESERVACIÓN TYPED -> CLEAN DE AFLUENCIA
--
-- Debido a que la granularidad original es única,
-- linea_original permite reconciliar CLEAN contra TYPED.
-- =========================================================

SELECT
    COUNT(*) AS diferencias_afluencia

FROM proyecto.trolebus_desglosada_typed AS t

JOIN proyecto.trolebus_desglosada_clean AS c

  ON c.fecha = t.fecha
 AND c.linea_original = t.linea
 AND c.tipo_pago = t.tipo_pago

WHERE c.afluencia IS DISTINCT FROM t.afluencia;


-- =========================================================
-- 23. PRECISIÓN FÍSICA DE AFLUENCIA CLEAN
-- =========================================================

SELECT
    column_name,
    data_type,
    numeric_precision,
    numeric_scale

FROM information_schema.columns

WHERE table_schema = 'proyecto'
  AND table_name = 'trolebus_desglosada_clean'
  AND column_name = 'afluencia';


-- =========================================================
-- 24. VALIDACIÓN AUTOMÁTICA FINAL
-- =========================================================

DO $$
DECLARE

    stage_count             BIGINT;
    typed_count             BIGINT;
    clean_count             BIGINT;

    null_count              BIGINT;
    zero_count              BIGINT;
    decimal_count           BIGINT;
    negative_count          BIGINT;

    lineas_count            BIGINT;
    payment_count           BIGINT;
    fuera_lineas            BIGINT;
    fuera_pagos             BIGINT;

    collision_rows          BIGINT;
    collision_groups        BIGINT;

    duplicate_rows          BIGINT;
    duplicate_groups        BIGINT;

    outlier_count           BIGINT;
    homologated_count       BIGINT;

    temporal_errors         BIGINT;

    fecha_count             BIGINT;
    fecha_linea_count       BIGINT;

    mismatch_afluencia      BIGINT;

BEGIN

    -- -----------------------------------------------------
    -- Conteos por capa
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO stage_count
    FROM proyecto.trolebus_desglosada_stage;


    SELECT COUNT(*)
    INTO typed_count
    FROM proyecto.trolebus_desglosada_typed;


    SELECT COUNT(*)
    INTO clean_count
    FROM proyecto.trolebus_desglosada_clean;


    IF stage_count <> 65013
       OR typed_count <> 65013
       OR clean_count <> 65013 THEN

        RAISE EXCEPTION
            'Conciliación Trolebus incorrecta. STAGE: %, TYPED: %, CLEAN: %',
            stage_count,
            typed_count,
            clean_count;

    END IF;


    -- -----------------------------------------------------
    -- NULL / ceros / decimales / negativos
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO null_count

    FROM proyecto.trolebus_desglosada_clean

    WHERE fecha IS NULL
       OR anio IS NULL
       OR mes IS NULL
       OR linea_original IS NULL
       OR linea IS NULL
       OR tipo_pago IS NULL
       OR afluencia IS NULL;


    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE afluencia = 0;


    SELECT COUNT(*)
    INTO decimal_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE afluencia <> TRUNC(afluencia);


    SELECT COUNT(*)
    INTO negative_count
    FROM proyecto.trolebus_desglosada_clean
    WHERE afluencia < 0;


    IF null_count <> 0 THEN
        RAISE EXCEPTION
            'NULL inesperados en CLEAN: %',
            null_count;
    END IF;


    IF zero_count <> 20246 THEN
        RAISE EXCEPTION
            'Ceros incorrectos. Esperado: 20246. Obtenido: %',
            zero_count;
    END IF;


    IF decimal_count <> 1419 THEN
        RAISE EXCEPTION
            'Decimales incorrectos. Esperado: 1419. Obtenido: %',
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
    FROM proyecto.trolebus_desglosada_clean;


    SELECT COUNT(DISTINCT tipo_pago)
    INTO payment_count
    FROM proyecto.trolebus_desglosada_clean;


    SELECT COUNT(*)
    INTO fuera_lineas

    FROM proyecto.trolebus_desglosada_clean

    WHERE linea NOT IN (

        'Linea 0',

        'Linea 1',
        'Linea 1 Nochebus',

        'Linea 2',
        'Linea 3',
        'Linea 4',
        'Linea 5',
        'Linea 6',
        'Linea 7',
        'Linea 8',
        'Linea 9',

        'Linea 10',
        'Linea 10 (Trolebus elevado)',

        'Linea 11',
        'Linea 12',
        'Linea 13',
        'Linea 14'
    );


    SELECT COUNT(*)
    INTO fuera_pagos

    FROM proyecto.trolebus_desglosada_clean

    WHERE tipo_pago NOT IN (
        'Boleto',
        'Gratuidad',
        'Prepago'
    );


    IF lineas_count <> 17
       OR fuera_lineas <> 0 THEN

        RAISE EXCEPTION
            'Dominio de linea incorrecto. Distintas: %, fuera dominio: %',
            lineas_count,
            fuera_lineas;

    END IF;


    IF payment_count <> 3
       OR fuera_pagos <> 0 THEN

        RAISE EXCEPTION
            'Dominio tipo_pago incorrecto. Distintos: %, fuera dominio: %',
            payment_count,
            fuera_pagos;

    END IF;


    -- -----------------------------------------------------
    -- Colisiones
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO collision_rows

    FROM proyecto.trolebus_desglosada_clean

    WHERE es_colision_clave;


    WITH grupos AS (

        SELECT
            fecha,
            linea,
            tipo_pago

        FROM proyecto.trolebus_desglosada_clean

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

    FROM proyecto.trolebus_desglosada_clean

    WHERE es_duplicado_exacto;


    WITH grupos AS (

        SELECT
            fecha,
            anio,
            mes,
            linea_original,
            tipo_pago,
            afluencia

        FROM proyecto.trolebus_desglosada_clean

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

    FROM proyecto.trolebus_desglosada_clean

    WHERE es_outlier_iqr_global;


    IF outlier_count <> 6345 THEN
        RAISE EXCEPTION
            'Outliers diferentes al perfilado. Esperado: 6345. Obtenido: %',
            outlier_count;
    END IF;


    -- -----------------------------------------------------
    -- Homologación
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO homologated_count

    FROM proyecto.trolebus_desglosada_clean

    WHERE es_linea_homologada;


    IF homologated_count <> 62268 THEN
        RAISE EXCEPTION
            'Filas homologadas incorrectas. Esperado: 62268. Obtenido: %',
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

    FROM proyecto.trolebus_desglosada_clean;


    IF temporal_errors <> 0 THEN
        RAISE EXCEPTION
            'Errores temporales CLEAN: %',
            temporal_errors;
    END IF;


    -- -----------------------------------------------------
    -- Cobertura temporal
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT fecha)
    INTO fecha_count

    FROM proyecto.trolebus_desglosada_clean;


    IF fecha_count <> 1765 THEN
        RAISE EXCEPTION
            'Fechas distintas incorrectas. Esperado: 1765. Obtenido: %',
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

        FROM proyecto.trolebus_desglosada_clean

        GROUP BY
            fecha,
            linea

    ) AS x;


    IF fecha_linea_count <> 21671 THEN
        RAISE EXCEPTION
            'Claves fecha x linea incorrectas. Esperado: 21671. Obtenido: %',
            fecha_linea_count;
    END IF;


    -- -----------------------------------------------------
    -- Preservación de afluencia TYPED -> CLEAN
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO mismatch_afluencia

    FROM proyecto.trolebus_desglosada_typed AS t

    JOIN proyecto.trolebus_desglosada_clean AS c

      ON c.fecha = t.fecha
     AND c.linea_original = t.linea
     AND c.tipo_pago = t.tipo_pago

    WHERE c.afluencia IS DISTINCT FROM t.afluencia;


    IF mismatch_afluencia <> 0 THEN
        RAISE EXCEPTION
            'CLEAN modificó % valores de afluencia.',
            mismatch_afluencia;
    END IF;


    -- -----------------------------------------------------
    -- RESULTADO FINAL
    -- -----------------------------------------------------

    RAISE NOTICE
        'VALIDACION TROLEBUS OK. Filas: %, NULL: %, ceros: %, decimales: %, negativos: %, lineas: %, pagos: %, colisiones: %, duplicados: %, outliers: %, homologadas: %, fechas: %, claves fecha-linea: %, diferencias afluencia: %',
        clean_count,
        null_count,
        zero_count,
        decimal_count,
        negative_count,
        lineas_count,
        payment_count,
        collision_groups,
        duplicate_groups,
        outlier_count,
        homologated_count,
        fecha_count,
        fecha_linea_count,
        mismatch_afluencia;

END
$$;