/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Tren Ligero

    PERFILADO PREVIO AL TIPADO

    Objetivo:
    caracterizar formalmente estructura, cobertura,
    convertibilidad, calidad, precisión numérica y
    granularidad de Tren Ligero antes de construir
    las capas TYPED y CLEAN.

    Evidencia RAW/STAGING previa:
    - 3,530 registros.
    - 5 columnas.
    - Cobertura:
      2022-01-01 -> 2026-10-31.
    - 1,765 fechas distintas.
    - 2 tipos de pago:
        Gratuidad
        Prepago
    - 1,765 registros por tipo_pago.
    - 0 vacíos.
    - 0 NaN.
    - 0 no numéricos.
    - 0 ceros.
    - 0 negativos.
    - 516 valores con componente decimal.
    - 0 duplicados exactos.
    - 0 colisiones en:
      fecha × tipo_pago.

    Granularidad nativa observada:

        fecha × tipo_pago

    IMPORTANTE:
    El recurso NO contiene columna linea.

    Por tanto este perfilado NO:
    - inventa linea;
    - inventa unidad_operativa;
    - fuerza compatibilidad multisistema;
    - redondea afluencia;
    - elimina valores;
    - elimina outliers;
    - modifica STAGING.

    Los outliers se consideran únicamente diagnóstico.
*/


-- =========================================================
-- 0. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario,
    version() AS version_postgresql;


-- =========================================================
-- 1. CONTEO BASE
-- =========================================================

SELECT
    COUNT(*) AS registros
FROM proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 2. NULL / VACÍOS
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
        WHERE NULLIF(BTRIM(tipo_pago), '') IS NULL
    ) AS vacios_tipo_pago,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NULL
    ) AS vacios_afluencia

FROM proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 3. CONVERTIBILIDAD
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
        WHERE LOWER(BTRIM(afluencia)) = 'nan'
    ) AS afluencia_nan,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NOT NULL
          AND LOWER(BTRIM(afluencia)) <> 'nan'
          AND NOT pg_input_is_valid(BTRIM(afluencia), 'numeric')
    ) AS afluencia_invalida,

    COUNT(*) FILTER (
        WHERE pg_input_is_valid(BTRIM(afluencia), 'numeric')
    ) AS afluencia_numerica,

    COUNT(*) FILTER (
        WHERE pg_input_is_valid(BTRIM(afluencia), 'bigint')
    ) AS afluencia_entera

FROM proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 4. COBERTURA TEMPORAL
-- =========================================================

SELECT
    MIN(BTRIM(fecha)::date) AS fecha_min,
    MAX(BTRIM(fecha)::date) AS fecha_max,

    COUNT(
        DISTINCT BTRIM(fecha)::date
    ) AS fechas_distintas,

    MIN(BTRIM(anio)::smallint) AS anio_min,
    MAX(BTRIM(anio)::smallint) AS anio_max

FROM proyecto.tren_ligero_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint');


-- =========================================================
-- 5. COHERENCIA FECHA <-> AÑO
-- =========================================================

SELECT
    COUNT(*) AS inconsistencias_fecha_anio

FROM proyecto.tren_ligero_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint')

  AND EXTRACT(
        YEAR FROM BTRIM(fecha)::date
      )::smallint
      <> BTRIM(anio)::smallint;


-- =========================================================
-- 6. DOMINIO DE MES
-- =========================================================

SELECT
    BTRIM(mes) AS mes,
    COUNT(*) AS registros

FROM proyecto.tren_ligero_desglosada_stage

GROUP BY BTRIM(mes)
ORDER BY mes;


-- =========================================================
-- 7. COHERENCIA FECHA <-> MES
-- =========================================================

WITH datos AS (

    SELECT
        BTRIM(fecha) AS fecha,
        LOWER(BTRIM(mes)) AS mes,

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
            WHEN 'setiembre' THEN 9
            WHEN 'octubre' THEN 10
            WHEN 'noviembre' THEN 11
            WHEN 'diciembre' THEN 12
            ELSE NULL
        END AS mes_num

    FROM proyecto.tren_ligero_desglosada_stage
)

SELECT
    COUNT(*) FILTER (
        WHERE mes_num IS NULL
    ) AS mes_no_reconocido,

    COUNT(*) FILTER (
        WHERE mes_num IS NOT NULL
          AND pg_input_is_valid(fecha, 'date')
          AND EXTRACT(
                MONTH FROM fecha::date
              )::integer <> mes_num
    ) AS inconsistencias_fecha_mes

FROM datos;


-- =========================================================
-- 8. DOMINIO DE TIPO_PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros

FROM proyecto.tren_ligero_desglosada_stage

GROUP BY BTRIM(tipo_pago)
ORDER BY tipo_pago;


-- =========================================================
-- 9. DUPLICADOS EXACTOS
-- =========================================================

WITH grupos AS (

    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(mes) AS mes,
        BTRIM(anio) AS anio,
        BTRIM(tipo_pago) AS tipo_pago,
        BTRIM(afluencia) AS afluencia,
        COUNT(*) AS veces

    FROM proyecto.tren_ligero_desglosada_stage

    GROUP BY
        BTRIM(fecha),
        BTRIM(mes),
        BTRIM(anio),
        BTRIM(tipo_pago),
        BTRIM(afluencia)

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
-- 10. GRANULARIDAD CANDIDATA
--
-- fecha × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(tipo_pago) AS tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.tren_ligero_desglosada_stage

    GROUP BY
        BTRIM(fecha),
        BTRIM(tipo_pago)
)

SELECT
    COUNT(*) AS claves_distintas,

    COUNT(*) FILTER (
        WHERE veces > 1
    ) AS grupos_con_colision,

    COALESCE(
        SUM(veces) FILTER (
            WHERE veces > 1
        ),
        0
    ) AS filas_involucradas,

    COALESCE(
        SUM(veces - 1) FILTER (
            WHERE veces > 1
        ),
        0
    ) AS registros_excedentes,

    MAX(veces) AS max_repeticiones

FROM grupos;


-- =========================================================
-- 11. ESTRUCTURA POR FECHA
--
-- Esperado:
-- 2 filas y 2 tipos_pago para cada fecha.
-- =========================================================

WITH grupos AS (

    SELECT
        BTRIM(fecha) AS fecha,

        COUNT(*) AS filas,

        COUNT(
            DISTINCT BTRIM(tipo_pago)
        ) AS tipos_pago

    FROM proyecto.tren_ligero_desglosada_stage

    GROUP BY BTRIM(fecha)
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
-- 12. CONJUNTOS DE TIPO_PAGO POR FECHA
-- =========================================================

WITH por_fecha AS (

    SELECT
        BTRIM(fecha) AS fecha,

        STRING_AGG(
            DISTINCT BTRIM(tipo_pago),
            ' | '
            ORDER BY BTRIM(tipo_pago)
        ) AS conjunto_pago

    FROM proyecto.tren_ligero_desglosada_stage

    GROUP BY BTRIM(fecha)
)

SELECT
    conjunto_pago,
    COUNT(*) AS numero_fechas

FROM por_fecha

GROUP BY conjunto_pago
ORDER BY conjunto_pago;


-- =========================================================
-- 13. ESTADÍSTICA DE AFLUENCIA
-- =========================================================

WITH valores AS (

    SELECT
        BTRIM(afluencia)::numeric AS afluencia

    FROM proyecto.tren_ligero_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
    )
)

SELECT
    COUNT(*) AS valores_numericos,

    MIN(afluencia) AS minimo,

    percentile_cont(0.25)
        WITHIN GROUP (
            ORDER BY afluencia
        ) AS q1,

    percentile_cont(0.50)
        WITHIN GROUP (
            ORDER BY afluencia
        ) AS mediana,

    AVG(afluencia)::numeric(30,6)
        AS media,

    percentile_cont(0.75)
        WITHIN GROUP (
            ORDER BY afluencia
        ) AS q3,

    MAX(afluencia) AS maximo,

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ) AS ceros,

    COUNT(*) FILTER (
        WHERE afluencia < 0
    ) AS negativos,

    COUNT(*) FILTER (
        WHERE afluencia <> TRUNC(afluencia)
    ) AS valores_decimales

FROM valores;


-- =========================================================
-- 14. PRECISIÓN Y ESCALA OBSERVADAS
-- =========================================================

WITH datos AS (

    SELECT
        BTRIM(afluencia) AS afluencia_txt

    FROM proyecto.tren_ligero_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
    )
),

perfil AS (

    SELECT
        LENGTH(
            REGEXP_REPLACE(
                SPLIT_PART(
                    afluencia_txt,
                    '.',
                    1
                ),
                '^[+-]',
                ''
            )
        ) AS digitos_enteros,

        CASE
            WHEN POSITION('.' IN afluencia_txt) > 0
            THEN LENGTH(
                SPLIT_PART(
                    afluencia_txt,
                    '.',
                    2
                )
            )
            ELSE 0
        END AS escala

    FROM datos
)

SELECT
    MAX(digitos_enteros)
        AS max_digitos_enteros,

    MAX(escala)
        AS max_escala,

    MAX(digitos_enteros + escala)
        AS max_precision_observada

FROM perfil;


-- =========================================================
-- 15. DISTRIBUCIÓN DE ESCALA DECIMAL
-- =========================================================

WITH datos AS (

    SELECT
        BTRIM(afluencia) AS afluencia_txt

    FROM proyecto.tren_ligero_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
    )

      AND BTRIM(afluencia)::numeric
          <> TRUNC(BTRIM(afluencia)::numeric)
)

SELECT
    LENGTH(
        SPLIT_PART(
            afluencia_txt,
            '.',
            2
        )
    ) AS escala,

    COUNT(*) AS registros

FROM datos

GROUP BY escala
ORDER BY escala;


-- =========================================================
-- 16. DECIMALES POR AÑO
-- =========================================================

SELECT
    BTRIM(anio) AS anio,
    COUNT(*) AS registros_decimales

FROM proyecto.tren_ligero_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND BTRIM(afluencia)::numeric
      <> TRUNC(BTRIM(afluencia)::numeric)

GROUP BY BTRIM(anio)

ORDER BY BTRIM(anio);


-- =========================================================
-- 17. DECIMALES POR TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros_decimales

FROM proyecto.tren_ligero_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND BTRIM(afluencia)::numeric
      <> TRUNC(BTRIM(afluencia)::numeric)

GROUP BY BTRIM(tipo_pago)

ORDER BY tipo_pago;


-- =========================================================
-- 18. VALORES MÁS ALTOS
--
-- Diagnóstico solamente.
-- Un valor alto NO implica error.
-- =========================================================

SELECT
    fecha,
    mes,
    anio,
    tipo_pago,
    afluencia

FROM proyecto.tren_ligero_desglosada_stage

WHERE pg_input_is_valid(
    BTRIM(afluencia),
    'numeric'
)

ORDER BY
    BTRIM(afluencia)::numeric DESC

LIMIT 20;


-- =========================================================
-- 19. OUTLIERS IQR GLOBAL
--
-- Diagnóstico únicamente.
-- No se elimina ningún registro.
-- =========================================================

WITH valores AS (

    SELECT
        BTRIM(afluencia)::numeric AS afluencia

    FROM proyecto.tren_ligero_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
    )
),

cuartiles AS (

    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (
                ORDER BY afluencia
            ) AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (
                ORDER BY afluencia
            ) AS q3

    FROM valores
),

resultado AS (

    SELECT
        v.afluencia,
        c.q1,
        c.q3,
        c.q3 - c.q1 AS iqr

    FROM valores AS v

    CROSS JOIN cuartiles AS c
)

SELECT
    q1,
    q3,

    q1 - 1.5 * iqr
        AS limite_inferior,

    q3 + 1.5 * iqr
        AS limite_superior,

    COUNT(*) FILTER (
        WHERE afluencia < q1 - 1.5 * iqr
           OR afluencia > q3 + 1.5 * iqr
    ) AS posibles_outliers,

    COUNT(*) AS valores_numericos

FROM resultado

GROUP BY
    q1,
    q3,
    iqr;


-- =========================================================
-- 20. POSIBLE MOJIBAKE
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE mes LIKE '%Ã%'
           OR tipo_pago LIKE '%Ã%'
    ) AS filas_patron_1,

    COUNT(*) FILTER (
        WHERE mes LIKE '%Â%'
           OR tipo_pago LIKE '%Â%'
    ) AS filas_patron_2,

    COUNT(*) FILTER (
        WHERE mes LIKE '%�%'
           OR tipo_pago LIKE '%�%'
    ) AS replacement_character

FROM proyecto.tren_ligero_desglosada_stage;


-- =========================================================
-- 21. CONTROL FINAL
-- =========================================================

SELECT
    'STAGE_COUNT' AS prueba,
    COUNT(*)::text AS resultado,
    '3530' AS referencia,

    CASE
        WHEN COUNT(*) = 3530
        THEN 'OK'
        ELSE 'REVISAR'
    END AS estado

FROM proyecto.tren_ligero_desglosada_stage


UNION ALL


SELECT
    'NAN_COUNT',
    COUNT(*)::text,
    '0',

    CASE
        WHEN COUNT(*) = 0
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.tren_ligero_desglosada_stage

WHERE LOWER(BTRIM(afluencia)) = 'nan'


UNION ALL


SELECT
    'ZERO_COUNT',
    COUNT(*)::text,
    '0',

    CASE
        WHEN COUNT(*) = 0
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.tren_ligero_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )
  AND BTRIM(afluencia)::numeric = 0


UNION ALL


SELECT
    'DECIMAL_COUNT',
    COUNT(*)::text,
    '516',

    CASE
        WHEN COUNT(*) = 516
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.tren_ligero_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND BTRIM(afluencia)::numeric
      <> TRUNC(BTRIM(afluencia)::numeric)


UNION ALL


SELECT
    'TYPE_PAYMENT_COUNT',
    COUNT(DISTINCT BTRIM(tipo_pago))::text,
    '2',

    CASE
        WHEN COUNT(DISTINCT BTRIM(tipo_pago)) = 2
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.tren_ligero_desglosada_stage


UNION ALL


SELECT
    'DATE_COUNT',
    COUNT(DISTINCT BTRIM(fecha))::text,
    '1765',

    CASE
        WHEN COUNT(DISTINCT BTRIM(fecha)) = 1765
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.tren_ligero_desglosada_stage


UNION ALL


SELECT
    'GRANULARITY_KEYS',
    COUNT(*)::text,
    '3530',

    CASE
        WHEN COUNT(*) = 3530
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM (
    SELECT
        BTRIM(fecha),
        BTRIM(tipo_pago)

    FROM proyecto.tren_ligero_desglosada_stage

    GROUP BY
        BTRIM(fecha),
        BTRIM(tipo_pago)
) AS claves;