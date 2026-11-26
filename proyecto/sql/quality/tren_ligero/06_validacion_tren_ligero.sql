/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Tren Ligero

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
    comprobar que el pipeline individual de Tren Ligero
    conserva registros, granularidad, dominios, precisión
    numérica y hallazgos de calidad demostrados durante
    la inspección y el perfilado.

    RESULTADOS ESPERADOS:

    Conteos:
    - STAGING: 3,530
    - TYPED:   3,530
    - CLEAN:   3,530
    - pérdida: 0

    Calidad:
    - NULL críticos: 0
    - ceros: 0
    - decimales: 516
    - negativos: 0
    - duplicados exactos: 0
    - colisiones: 0
    - posibles outliers IQR globales: 0

    Dominios:
    - 2 tipos de pago:
        Gratuidad
        Prepago

    Cobertura:
    - 2022-01-01 -> 2026-10-31
    - 1,765 fechas distintas

    Estructura:
    - 3,530 claves fecha × tipo_pago
    - 2 filas por fecha
    - 2 tipos de pago por fecha

    Granularidad validada:

        fecha × tipo_pago

    Precisión física de afluencia:

        NUMERIC(18,12)

    IMPORTANTE:
    El recurso Tren Ligero NO contiene linea.

    Por tanto este pipeline individual:
    - NO inventa linea;
    - NO inventa unidad_operativa;
    - NO fuerza todavía el contrato multisistema.

    La compatibilidad con:

        fecha × sistema × unidad_operativa

    deberá evaluarse posteriormente mediante un
    checkpoint específico.

    Este script:
    - NO modifica datos;
    - NO elimina registros;
    - NO corrige valores;
    - NO redondea afluencia;
    - NO altera STAGING, TYPED ni CLEAN.
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
FROM proyecto.tren_ligero_desglosada_stage

UNION ALL

SELECT
    'TYPED',
    COUNT(*)
FROM proyecto.tren_ligero_desglosada_typed

UNION ALL

SELECT
    'CLEAN',
    COUNT(*)
FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 3. CONCILIACIÓN ENTRE CAPAS
-- =========================================================

SELECT

    (
        SELECT COUNT(*)
        FROM proyecto.tren_ligero_desglosada_stage
    ) AS staging,

    (
        SELECT COUNT(*)
        FROM proyecto.tren_ligero_desglosada_typed
    ) AS typed,

    (
        SELECT COUNT(*)
        FROM proyecto.tren_ligero_desglosada_clean
    ) AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.tren_ligero_desglosada_clean)

        -

        (SELECT COUNT(*)
         FROM proyecto.tren_ligero_desglosada_stage)

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
        WHERE mes_num IS NULL
    ) AS mes_num_null,

    COUNT(*) FILTER (
        WHERE dia_semana_num IS NULL
    ) AS dia_semana_num_null,

    COUNT(*) FILTER (
        WHERE dia_semana IS NULL
    ) AS dia_semana_null,

    COUNT(*) FILTER (
        WHERE es_fin_semana IS NULL
    ) AS es_fin_semana_null,

    COUNT(*) FILTER (
        WHERE tipo_pago IS NULL
    ) AS tipo_pago_null,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null

FROM proyecto.tren_ligero_desglosada_clean;


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

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 6. COBERTURA TEMPORAL
-- =========================================================

SELECT

    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,

    COUNT(DISTINCT fecha)
        AS fechas_distintas,

    MIN(anio) AS anio_min,
    MAX(anio) AS anio_max

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 7. DOMINIO DE TIPO_PAGO
-- =========================================================

SELECT

    tipo_pago,
    COUNT(*) AS registros,
    COUNT(DISTINCT fecha) AS fechas,

    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max

FROM proyecto.tren_ligero_desglosada_clean

GROUP BY tipo_pago

ORDER BY tipo_pago;


-- =========================================================
-- 8. VALIDACIÓN DEL DOMINIO TIPO_PAGO
-- =========================================================

SELECT

    COUNT(DISTINCT tipo_pago)
        AS tipos_pago_distintos,

    COUNT(*) FILTER (

        WHERE tipo_pago NOT IN (
            'Gratuidad',
            'Prepago'
        )

    ) AS fuera_dominio

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 9. CEROS Y BANDERA
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

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 10. DECIMALES Y BANDERA
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

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 11. NO DISPONIBILIDAD
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

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 12. NEGATIVOS
-- =========================================================

SELECT

    COUNT(*) FILTER (
        WHERE afluencia < 0
    ) AS valores_negativos

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 13. DUPLICADOS EXACTOS
-- =========================================================

WITH grupos AS (

    SELECT

        fecha,
        anio,
        mes,
        tipo_pago,
        afluencia,

        COUNT(*) AS veces

    FROM proyecto.tren_ligero_desglosada_clean

    GROUP BY

        fecha,
        anio,
        mes,
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
-- 14. GRANULARIDAD CLEAN
--
-- fecha × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT

        fecha,
        tipo_pago,

        COUNT(*) AS veces

    FROM proyecto.tren_ligero_desglosada_clean

    GROUP BY
        fecha,
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
-- 15. ESTRUCTURA POR FECHA
--
-- Esperado:
--
-- 2 filas
-- 2 tipos_pago
--
-- para cada una de las 1,765 fechas.
-- =========================================================

WITH grupos AS (

    SELECT

        fecha,

        COUNT(*) AS filas,

        COUNT(
            DISTINCT tipo_pago
        ) AS tipos_pago

    FROM proyecto.tren_ligero_desglosada_clean

    GROUP BY fecha
)

SELECT

    filas,
    tipos_pago,

    COUNT(*) AS numero_fechas

FROM grupos

GROUP BY
    filas,
    tipos_pago

ORDER BY
    filas,
    tipos_pago;


-- =========================================================
-- 16. CONTEO DE CLAVES fecha × tipo_pago
-- =========================================================

SELECT

    COUNT(*) AS claves_fecha_tipo_pago

FROM (

    SELECT
        fecha,
        tipo_pago

    FROM proyecto.tren_ligero_desglosada_clean

    GROUP BY
        fecha,
        tipo_pago

) AS claves;


-- =========================================================
-- 17. OUTLIERS IQR
-- =========================================================

SELECT

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 18. FLAGS DE CALIDAD
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
        WHERE es_colision_clave
    ) AS filas_colision,

    COUNT(*) FILTER (
        WHERE es_duplicado_exacto
    ) AS filas_duplicado_exacto,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 19. RANGO DE AFLUENCIA
-- =========================================================

SELECT

    MIN(afluencia) AS afluencia_min,

    MAX(afluencia) AS afluencia_max,

    AVG(afluencia)::NUMERIC(30,6)
        AS afluencia_media

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 20. PRESERVACIÓN STAGING -> TYPED
-- =========================================================

SELECT

    COUNT(*) AS diferencias_afluencia_stage_typed

FROM proyecto.tren_ligero_desglosada_stage AS s

JOIN proyecto.tren_ligero_desglosada_typed AS t

  ON t.fecha = BTRIM(s.fecha)::DATE

 AND t.tipo_pago =
     BTRIM(s.tipo_pago)

WHERE t.afluencia
      IS DISTINCT FROM
      BTRIM(s.afluencia)::NUMERIC;


-- =========================================================
-- 21. PRESERVACIÓN TYPED -> CLEAN
-- =========================================================

SELECT

    COUNT(*) AS diferencias_typed_clean

FROM proyecto.tren_ligero_desglosada_typed AS t

JOIN proyecto.tren_ligero_desglosada_clean AS c

  ON c.fecha = t.fecha

 AND c.tipo_pago = t.tipo_pago

WHERE c.anio IS DISTINCT FROM t.anio

   OR c.mes IS DISTINCT FROM t.mes

   OR c.afluencia IS DISTINCT FROM t.afluencia;


-- =========================================================
-- 22. PRECISIÓN FÍSICA DE AFLUENCIA
-- =========================================================

SELECT

    table_name,
    column_name,
    data_type,
    numeric_precision,
    numeric_scale

FROM information_schema.columns

WHERE table_schema = 'proyecto'

  AND table_name IN (
      'tren_ligero_desglosada_typed',
      'tren_ligero_desglosada_clean'
  )

  AND column_name = 'afluencia'

ORDER BY table_name;


-- =========================================================
-- 23. AUSENCIA DE COLUMNA LINEA
--
-- Debe devolver 0.
--
-- Esto demuestra que el pipeline individual no inventó
-- una dimensión que no existe en la fuente.
-- =========================================================

SELECT

    COUNT(*) AS columnas_linea_pipeline

FROM information_schema.columns

WHERE table_schema = 'proyecto'

  AND table_name IN (
      'tren_ligero_desglosada_stage',
      'tren_ligero_desglosada_typed',
      'tren_ligero_desglosada_clean'
  )

  AND column_name IN (
      'linea',
      'linea_original',
      'unidad_operativa'
  );


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

    payment_count        BIGINT;
    fuera_pagos          BIGINT;

    collision_rows       BIGINT;
    collision_groups     BIGINT;

    duplicate_rows       BIGINT;
    duplicate_groups     BIGINT;

    outlier_count        BIGINT;

    temporal_errors      BIGINT;

    fecha_count          BIGINT;
    key_count            BIGINT;

    mismatch_stage_typed BIGINT;
    mismatch_typed_clean BIGINT;

    linea_columns        BIGINT;

    precision_typed      INTEGER;
    scale_typed          INTEGER;

    precision_clean      INTEGER;
    scale_clean          INTEGER;

BEGIN

    -- -----------------------------------------------------
    -- CONTEOS POR CAPA
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO stage_count

    FROM proyecto.tren_ligero_desglosada_stage;


    SELECT COUNT(*)
    INTO typed_count

    FROM proyecto.tren_ligero_desglosada_typed;


    SELECT COUNT(*)
    INTO clean_count

    FROM proyecto.tren_ligero_desglosada_clean;


    IF stage_count <> 3530
       OR typed_count <> 3530
       OR clean_count <> 3530 THEN

        RAISE EXCEPTION
            'Conciliación Tren Ligero incorrecta. STAGE: %, TYPED: %, CLEAN: %',
            stage_count,
            typed_count,
            clean_count;

    END IF;


    -- -----------------------------------------------------
    -- NULL CRÍTICOS
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO null_count

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha IS NULL
       OR anio IS NULL
       OR mes IS NULL
       OR mes_num IS NULL
       OR dia_semana_num IS NULL
       OR dia_semana IS NULL
       OR es_fin_semana IS NULL
       OR tipo_pago IS NULL
       OR afluencia IS NULL;


    IF null_count <> 0 THEN

        RAISE EXCEPTION
            'NULL inesperados en CLEAN Tren Ligero: %',
            null_count;

    END IF;


    -- -----------------------------------------------------
    -- AFLUENCIA
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO zero_count

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE afluencia = 0;


    SELECT COUNT(*)
    INTO decimal_count

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE afluencia <> TRUNC(afluencia);


    SELECT COUNT(*)
    INTO negative_count

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE afluencia < 0;


    IF zero_count <> 0 THEN

        RAISE EXCEPTION
            'Ceros incorrectos. Esperado: 0. Obtenido: %',
            zero_count;

    END IF;


    IF decimal_count <> 516 THEN

        RAISE EXCEPTION
            'Decimales incorrectos. Esperado: 516. Obtenido: %',
            decimal_count;

    END IF;


    IF negative_count <> 0 THEN

        RAISE EXCEPTION
            'Negativos inesperados: %',
            negative_count;

    END IF;


    -- -----------------------------------------------------
    -- DOMINIO TIPO_PAGO
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT tipo_pago)
    INTO payment_count

    FROM proyecto.tren_ligero_desglosada_clean;


    SELECT COUNT(*)
    INTO fuera_pagos

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE tipo_pago NOT IN (
        'Gratuidad',
        'Prepago'
    );


    IF payment_count <> 2
       OR fuera_pagos <> 0 THEN

        RAISE EXCEPTION
            'Dominio tipo_pago incorrecto. Distintos: %, fuera dominio: %',
            payment_count,
            fuera_pagos;

    END IF;


    -- -----------------------------------------------------
    -- COLISIONES
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO collision_rows

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE es_colision_clave;


    WITH grupos AS (

        SELECT
            fecha,
            tipo_pago

        FROM proyecto.tren_ligero_desglosada_clean

        GROUP BY
            fecha,
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
    -- DUPLICADOS
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO duplicate_rows

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE es_duplicado_exacto;


    WITH grupos AS (

        SELECT
            fecha,
            anio,
            mes,
            tipo_pago,
            afluencia

        FROM proyecto.tren_ligero_desglosada_clean

        GROUP BY
            fecha,
            anio,
            mes,
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
    -- OUTLIERS
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO outlier_count

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE es_outlier_iqr_global;


    IF outlier_count <> 0 THEN

        RAISE EXCEPTION
            'Outliers diferentes al perfilado. Esperado: 0. Obtenido: %',
            outlier_count;

    END IF;


    -- -----------------------------------------------------
    -- COHERENCIA TEMPORAL
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

    FROM proyecto.tren_ligero_desglosada_clean;


    IF temporal_errors <> 0 THEN

        RAISE EXCEPTION
            'Errores temporales CLEAN: %',
            temporal_errors;

    END IF;


    -- -----------------------------------------------------
    -- FECHAS
    -- -----------------------------------------------------

    SELECT COUNT(DISTINCT fecha)
    INTO fecha_count

    FROM proyecto.tren_ligero_desglosada_clean;


    IF fecha_count <> 1765 THEN

        RAISE EXCEPTION
            'Fechas distintas incorrectas. Esperado: 1765. Obtenido: %',
            fecha_count;

    END IF;


    -- -----------------------------------------------------
    -- CLAVES fecha × tipo_pago
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO key_count

    FROM (

        SELECT
            fecha,
            tipo_pago

        FROM proyecto.tren_ligero_desglosada_clean

        GROUP BY
            fecha,
            tipo_pago

    ) AS claves;


    IF key_count <> 3530 THEN

        RAISE EXCEPTION
            'Claves fecha x tipo_pago incorrectas. Esperado: 3530. Obtenido: %',
            key_count;

    END IF;


    -- -----------------------------------------------------
    -- STAGING -> TYPED
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO mismatch_stage_typed

    FROM proyecto.tren_ligero_desglosada_stage AS s

    JOIN proyecto.tren_ligero_desglosada_typed AS t

      ON t.fecha = BTRIM(s.fecha)::DATE

     AND t.tipo_pago =
         BTRIM(s.tipo_pago)

    WHERE t.afluencia
          IS DISTINCT FROM
          BTRIM(s.afluencia)::NUMERIC;


    IF mismatch_stage_typed <> 0 THEN

        RAISE EXCEPTION
            'TYPED modificó % valores de afluencia respecto a STAGING.',
            mismatch_stage_typed;

    END IF;


    -- -----------------------------------------------------
    -- TYPED -> CLEAN
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO mismatch_typed_clean

    FROM proyecto.tren_ligero_desglosada_typed AS t

    JOIN proyecto.tren_ligero_desglosada_clean AS c

      ON c.fecha = t.fecha

     AND c.tipo_pago = t.tipo_pago

    WHERE c.anio IS DISTINCT FROM t.anio

       OR c.mes IS DISTINCT FROM t.mes

       OR c.afluencia IS DISTINCT FROM t.afluencia;


    IF mismatch_typed_clean <> 0 THEN

        RAISE EXCEPTION
            'CLEAN modificó % registros núcleo de TYPED.',
            mismatch_typed_clean;

    END IF;


    -- -----------------------------------------------------
    -- AUSENCIA DE LINEA / UNIDAD_OPERATIVA
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO linea_columns

    FROM information_schema.columns

    WHERE table_schema = 'proyecto'

      AND table_name IN (
          'tren_ligero_desglosada_stage',
          'tren_ligero_desglosada_typed',
          'tren_ligero_desglosada_clean'
      )

      AND column_name IN (
          'linea',
          'linea_original',
          'unidad_operativa'
      );


    IF linea_columns <> 0 THEN

        RAISE EXCEPTION
            'El pipeline individual creó % columnas linea/unidad_operativa no respaldadas por la fuente.',
            linea_columns;

    END IF;


    -- -----------------------------------------------------
    -- PRECISIÓN TYPED
    -- -----------------------------------------------------

    SELECT
        numeric_precision,
        numeric_scale

    INTO
        precision_typed,
        scale_typed

    FROM information_schema.columns

    WHERE table_schema = 'proyecto'
      AND table_name =
          'tren_ligero_desglosada_typed'
      AND column_name = 'afluencia';


    IF precision_typed <> 18
       OR scale_typed <> 12 THEN

        RAISE EXCEPTION
            'Precisión TYPED incorrecta. Esperado NUMERIC(18,12). Obtenido NUMERIC(%,%).',
            precision_typed,
            scale_typed;

    END IF;


    -- -----------------------------------------------------
    -- PRECISIÓN CLEAN
    -- -----------------------------------------------------

    SELECT
        numeric_precision,
        numeric_scale

    INTO
        precision_clean,
        scale_clean

    FROM information_schema.columns

    WHERE table_schema = 'proyecto'
      AND table_name =
          'tren_ligero_desglosada_clean'
      AND column_name = 'afluencia';


    IF precision_clean <> 18
       OR scale_clean <> 12 THEN

        RAISE EXCEPTION
            'Precisión CLEAN incorrecta. Esperado NUMERIC(18,12). Obtenido NUMERIC(%,%).',
            precision_clean,
            scale_clean;

    END IF;


    -- -----------------------------------------------------
    -- RESULTADO FINAL
    -- -----------------------------------------------------

    RAISE NOTICE
        'VALIDACION TREN LIGERO OK. Filas: %, NULL: %, ceros: %, decimales: %, negativos: %, pagos: %, colisiones: %, duplicados: %, outliers: %, fechas: %, claves fecha-tipo_pago: %, diferencias STAGE-TYPED: %, diferencias TYPED-CLEAN: %, linea/unidad_operativa artificiales: %',
        clean_count,
        null_count,
        zero_count,
        decimal_count,
        negative_count,
        payment_count,
        collision_groups,
        duplicate_groups,
        outlier_count,
        fecha_count,
        key_count,
        mismatch_stage_typed,
        mismatch_typed_clean,
        linea_columns;

END
$$;