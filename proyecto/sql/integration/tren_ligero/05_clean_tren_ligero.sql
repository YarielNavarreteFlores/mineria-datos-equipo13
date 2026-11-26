/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Tren Ligero

    CAPA: CLEAN

    Objetivos:
    - conservar el 100 % de los registros;
    - preservar exactamente la afluencia de TYPED;
    - conservar la granularidad nativa:
          fecha × tipo_pago;
    - derivar variables temporales;
    - conservar valores decimales;
    - conservar posibles outliers;
    - incorporar indicadores de calidad;
    - no inventar linea;
    - no inventar unidad_operativa.

    Evidencia previa TYPED:

    - 3,530 registros.
    - 0 NULL.
    - 0 ceros.
    - 516 valores decimales.
    - 0 negativos.
    - 0 duplicados exactos.
    - 0 colisiones en:
          fecha × tipo_pago.
    - 2 tipos de pago:
          Gratuidad
          Prepago.
    - 1,765 fechas distintas.
    - cobertura:
          2022-01-01 -> 2026-10-31.
    - afluencia:
          NUMERIC(18,12).
    - posibles outliers IQR globales:
          0.

    Granularidad validada:

        fecha × tipo_pago

    IMPORTANTE:

    El recurso Tren Ligero NO contiene columna linea.

    Por tanto CLEAN:
    - no crea linea;
    - no crea unidad_operativa;
    - no agrega filas;
    - no elimina filas;
    - no fuerza todavía el contrato multisistema.

    PRINCIPIOS:
    - RAW permanece intacto.
    - STAGING permanece intacto.
    - TYPED permanece intacto.
    - no se redondea afluencia.
    - no se eliminan valores decimales.
    - no se eliminan outliers.
    - no se imponen restricciones UNIQUE todavía.
*/


-- =========================================================
-- 1. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario_actual;


-- =========================================================
-- 2. PRECONDICIONES TYPED
-- =========================================================

DO $$
DECLARE

    typed_count      BIGINT;
    null_count       BIGINT;
    zero_count       BIGINT;
    decimal_count    BIGINT;
    negative_count   BIGINT;
    payment_count    BIGINT;
    date_count       BIGINT;
    collision_count  BIGINT;

BEGIN

    SELECT COUNT(*)
    INTO typed_count
    FROM proyecto.tren_ligero_desglosada_typed;


    SELECT COUNT(*)
    INTO null_count
    FROM proyecto.tren_ligero_desglosada_typed
    WHERE fecha IS NULL
       OR mes IS NULL
       OR anio IS NULL
       OR tipo_pago IS NULL
       OR afluencia IS NULL;


    SELECT COUNT(*)
    INTO zero_count
    FROM proyecto.tren_ligero_desglosada_typed
    WHERE afluencia = 0;


    SELECT COUNT(*)
    INTO decimal_count
    FROM proyecto.tren_ligero_desglosada_typed
    WHERE afluencia <> TRUNC(afluencia);


    SELECT COUNT(*)
    INTO negative_count
    FROM proyecto.tren_ligero_desglosada_typed
    WHERE afluencia < 0;


    SELECT COUNT(DISTINCT tipo_pago)
    INTO payment_count
    FROM proyecto.tren_ligero_desglosada_typed;


    SELECT COUNT(DISTINCT fecha)
    INTO date_count
    FROM proyecto.tren_ligero_desglosada_typed;


    SELECT COUNT(*)
    INTO collision_count

    FROM (

        SELECT
            fecha,
            tipo_pago

        FROM proyecto.tren_ligero_desglosada_typed

        GROUP BY
            fecha,
            tipo_pago

        HAVING COUNT(*) > 1

    ) AS x;


    IF typed_count <> 3530 THEN

        RAISE EXCEPTION
            'TYPED Tren Ligero cambió. Esperado: 3530. Obtenido: %',
            typed_count;

    END IF;


    IF null_count <> 0 THEN

        RAISE EXCEPTION
            'NULL inesperados en TYPED: %',
            null_count;

    END IF;


    IF zero_count <> 0 THEN

        RAISE EXCEPTION
            'Ceros TYPED cambiaron. Esperado: 0. Obtenido: %',
            zero_count;

    END IF;


    IF decimal_count <> 516 THEN

        RAISE EXCEPTION
            'Decimales TYPED cambiaron. Esperado: 516. Obtenido: %',
            decimal_count;

    END IF;


    IF negative_count <> 0 THEN

        RAISE EXCEPTION
            'Negativos inesperados en TYPED: %',
            negative_count;

    END IF;


    IF payment_count <> 2 THEN

        RAISE EXCEPTION
            'Tipos de pago cambiaron. Esperados: 2. Obtenidos: %',
            payment_count;

    END IF;


    IF date_count <> 1765 THEN

        RAISE EXCEPTION
            'Fechas cambiaron. Esperadas: 1765. Obtenidas: %',
            date_count;

    END IF;


    IF collision_count <> 0 THEN

        RAISE EXCEPTION
            'TYPED contiene colisiones inesperadas: %',
            collision_count;

    END IF;


    RAISE NOTICE
        'Precondiciones CLEAN Tren Ligero correctas. Filas: %, NULL: %, ceros: %, decimales: %, negativos: %, pagos: %, fechas: %, colisiones: %',
        typed_count,
        null_count,
        zero_count,
        decimal_count,
        negative_count,
        payment_count,
        date_count,
        collision_count;

END
$$;


-- =========================================================
-- 3. TRANSACCIÓN
-- =========================================================

BEGIN;


-- =========================================================
-- 4. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 5. ESTRUCTURA CLEAN
-- =========================================================

CREATE TABLE proyecto.tren_ligero_desglosada_clean (

    fecha                       DATE,
    anio                        SMALLINT,
    mes                         TEXT,

    mes_num                     SMALLINT,
    dia_semana_num              SMALLINT,
    dia_semana                  TEXT,
    es_fin_semana               BOOLEAN,

    tipo_pago                   TEXT,

    afluencia                   NUMERIC(18,12),

    es_afluencia_no_disponible  BOOLEAN,
    es_afluencia_cero           BOOLEAN,
    es_afluencia_decimal        BOOLEAN,

    es_colision_clave           BOOLEAN,
    es_duplicado_exacto         BOOLEAN,
    es_outlier_iqr_global       BOOLEAN
);


-- =========================================================
-- 6. CUARTILES IQR
--
-- Diagnóstico únicamente.
-- No se eliminan outliers.
-- =========================================================

WITH cuartiles AS (

    SELECT

        percentile_cont(0.25)
            WITHIN GROUP (
                ORDER BY afluencia
            ) AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (
                ORDER BY afluencia
            ) AS q3

    FROM proyecto.tren_ligero_desglosada_typed
),


-- =========================================================
-- 7. PREPARACIÓN DE INDICADORES
-- =========================================================

preparado AS (

    SELECT

        t.*,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                tipo_pago
        ) AS cantidad_clave,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                anio,
                mes,
                tipo_pago,
                afluencia
        ) AS cantidad_duplicado_exacto,

        c.q1,
        c.q3,
        c.q3 - c.q1 AS iqr

    FROM proyecto.tren_ligero_desglosada_typed AS t

    CROSS JOIN cuartiles AS c
)


-- =========================================================
-- 8. TYPED -> CLEAN
-- =========================================================

INSERT INTO proyecto.tren_ligero_desglosada_clean (

    fecha,
    anio,
    mes,

    mes_num,
    dia_semana_num,
    dia_semana,
    es_fin_semana,

    tipo_pago,
    afluencia,

    es_afluencia_no_disponible,
    es_afluencia_cero,
    es_afluencia_decimal,

    es_colision_clave,
    es_duplicado_exacto,
    es_outlier_iqr_global
)

SELECT

    fecha,
    anio,
    mes,

    EXTRACT(MONTH FROM fecha)::SMALLINT,

    EXTRACT(ISODOW FROM fecha)::SMALLINT,

    CASE EXTRACT(ISODOW FROM fecha)

        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'

    END,

    EXTRACT(ISODOW FROM fecha) IN (6, 7),

    tipo_pago,
    afluencia,

    afluencia IS NULL,

    COALESCE(
        afluencia = 0,
        FALSE
    ),

    COALESCE(
        afluencia <> TRUNC(afluencia),
        FALSE
    ),

    cantidad_clave > 1,

    cantidad_duplicado_exacto > 1,

    (
        afluencia < q1 - 1.5 * iqr

        OR

        afluencia > q3 + 1.5 * iqr
    )

FROM preparado;


-- =========================================================
-- 9. CONCILIACIÓN TYPED -> CLEAN
-- =========================================================

SELECT

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
         FROM proyecto.tren_ligero_desglosada_typed)

    ) AS diferencia;


-- =========================================================
-- 10. DOMINIO TIPO_PAGO
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
-- 11. FLAGS DE CALIDAD
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
-- 12. COHERENCIA TEMPORAL
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
-- 13. COBERTURA TEMPORAL
-- =========================================================

SELECT

    COUNT(*) AS registros,

    COUNT(DISTINCT fecha)
        AS fechas_distintas,

    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,

    MIN(anio) AS anio_min,
    MAX(anio) AS anio_max

FROM proyecto.tren_ligero_desglosada_clean;


-- =========================================================
-- 14. COLISIONES CLEAN
--
-- Granularidad:
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

    COUNT(*) AS grupos_colision,

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
-- 15. DUPLICADOS EXACTOS CLEAN
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
-- 16. CEROS Y DECIMALES PRESERVADOS
-- =========================================================

SELECT

    (
        SELECT COUNT(*)

        FROM proyecto.tren_ligero_desglosada_typed

        WHERE afluencia = 0
    ) AS ceros_typed,

    (
        SELECT COUNT(*)

        FROM proyecto.tren_ligero_desglosada_clean

        WHERE afluencia = 0
    ) AS ceros_clean,


    (
        SELECT COUNT(*)

        FROM proyecto.tren_ligero_desglosada_typed

        WHERE afluencia <> TRUNC(afluencia)
    ) AS decimales_typed,

    (
        SELECT COUNT(*)

        FROM proyecto.tren_ligero_desglosada_clean

        WHERE afluencia <> TRUNC(afluencia)
    ) AS decimales_clean;


-- =========================================================
-- 17. ESTRUCTURA POR FECHA
--
-- Debe existir:
--
-- 2 filas
-- 2 tipos_pago
--
-- para cada fecha.
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
-- 18. CLAVES fecha × tipo_pago
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
-- 19. PRESERVACIÓN TYPED -> CLEAN
--
-- La clave fecha × tipo_pago es única.
-- =========================================================

SELECT
    COUNT(*) AS diferencias_core

FROM proyecto.tren_ligero_desglosada_typed AS t

JOIN proyecto.tren_ligero_desglosada_clean AS c

  ON c.fecha = t.fecha
 AND c.tipo_pago = t.tipo_pago

WHERE c.anio IS DISTINCT FROM t.anio

   OR c.mes IS DISTINCT FROM t.mes

   OR c.afluencia IS DISTINCT FROM t.afluencia;


-- =========================================================
-- 20. PRECISIÓN FÍSICA DE AFLUENCIA CLEAN
-- =========================================================

SELECT

    column_name,
    data_type,
    numeric_precision,
    numeric_scale

FROM information_schema.columns

WHERE table_schema = 'proyecto'

  AND table_name =
      'tren_ligero_desglosada_clean'

  AND column_name = 'afluencia';


-- =========================================================
-- 21. VALIDACIÓN AUTOMÁTICA CLEAN
-- =========================================================

DO $$
DECLARE

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

    core_mismatch        BIGINT;

BEGIN

    -- -----------------------------------------------------
    -- CONTEO
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO clean_count

    FROM proyecto.tren_ligero_desglosada_clean;


    IF clean_count <> 3530 THEN

        RAISE EXCEPTION
            'Conteo CLEAN incorrecto. Esperado: 3530. Obtenido: %',
            clean_count;

    END IF;


    -- -----------------------------------------------------
    -- NULL
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
            'NULL inesperados en CLEAN: %',
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
            'Ceros CLEAN incorrectos. Esperado: 0. Obtenido: %',
            zero_count;

    END IF;


    IF decimal_count <> 516 THEN

        RAISE EXCEPTION
            'Decimales CLEAN incorrectos. Esperado: 516. Obtenido: %',
            decimal_count;

    END IF;


    IF negative_count <> 0 THEN

        RAISE EXCEPTION
            'Negativos inesperados en CLEAN: %',
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
    -- CLAVES
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

    ) AS x;


    IF key_count <> 3530 THEN

        RAISE EXCEPTION
            'Claves fecha x tipo_pago incorrectas. Esperado: 3530. Obtenido: %',
            key_count;

    END IF;


    -- -----------------------------------------------------
    -- PRESERVACIÓN TYPED -> CLEAN
    -- -----------------------------------------------------

    SELECT COUNT(*)
    INTO core_mismatch

    FROM proyecto.tren_ligero_desglosada_typed AS t

    JOIN proyecto.tren_ligero_desglosada_clean AS c

      ON c.fecha = t.fecha
     AND c.tipo_pago = t.tipo_pago

    WHERE c.anio IS DISTINCT FROM t.anio

       OR c.mes IS DISTINCT FROM t.mes

       OR c.afluencia IS DISTINCT FROM t.afluencia;


    IF core_mismatch <> 0 THEN

        RAISE EXCEPTION
            'CLEAN modificó % registros núcleo de TYPED.',
            core_mismatch;

    END IF;


    -- -----------------------------------------------------
    -- RESULTADO FINAL
    -- -----------------------------------------------------

    RAISE NOTICE
        'CLEAN Tren Ligero validado. Filas: %, NULL: %, ceros: %, decimales: %, negativos: %, pagos: %, colisiones: %, duplicados: %, outliers: %, fechas: %, claves fecha-tipo_pago: %, diferencias TYPED-CLEAN: %',
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
        core_mismatch;

END
$$;


-- =========================================================
-- 22. CONFIRMAR TRANSACCIÓN
-- =========================================================

COMMIT;