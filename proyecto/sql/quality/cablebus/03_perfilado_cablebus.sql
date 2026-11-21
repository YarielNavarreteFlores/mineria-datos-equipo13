/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Cablebús

    PERFILADO PREVIO AL TIPADO

    Objetivo:
    comprender estructura, cobertura, convertibilidad,
    calidad y granularidad de Cablebús antes de construir
    TYPED y CLEAN.

    IMPORTANTE:
    - Este script NO modifica datos.
    - No elimina ceros.
    - No elimina outliers.
    - No homologa valores de linea.
    - No impone restricciones UNIQUE.
    - La granularidad es candidata hasta comprobarla.
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
FROM proyecto.cablebus_desglosada_stage;


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
        WHERE NULLIF(BTRIM(linea), '') IS NULL
    ) AS vacios_linea,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(tipo_pago), '') IS NULL
    ) AS vacios_tipo_pago,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NULL
    ) AS vacios_afluencia

FROM proyecto.cablebus_desglosada_stage;


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

FROM proyecto.cablebus_desglosada_stage;


-- =========================================================
-- 4. COBERTURA TEMPORAL
-- =========================================================

SELECT
    MIN(BTRIM(fecha)::date) AS fecha_min,
    MAX(BTRIM(fecha)::date) AS fecha_max,
    COUNT(DISTINCT BTRIM(fecha)::date) AS fechas_distintas,
    MIN(BTRIM(anio)::smallint) AS anio_min,
    MAX(BTRIM(anio)::smallint) AS anio_max

FROM proyecto.cablebus_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint');


-- =========================================================
-- 5. COHERENCIA FECHA <-> ANIO
-- =========================================================

SELECT
    COUNT(*) AS inconsistencias_fecha_anio

FROM proyecto.cablebus_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint')
  AND EXTRACT(YEAR FROM BTRIM(fecha)::date)::smallint
      <> BTRIM(anio)::smallint;


-- =========================================================
-- 6. DOMINIO DE MES
-- =========================================================

SELECT
    BTRIM(mes) AS mes,
    COUNT(*) AS registros

FROM proyecto.cablebus_desglosada_stage

GROUP BY BTRIM(mes)
ORDER BY mes;


-- =========================================================
-- 7. COHERENCIA FECHA <-> MES
-- =========================================================

WITH datos AS (

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

    FROM proyecto.cablebus_desglosada_stage
)

SELECT
    COUNT(*) FILTER (
        WHERE mes_num IS NULL
    ) AS mes_no_reconocido,

    COUNT(*) FILTER (
        WHERE mes_num IS NOT NULL
          AND pg_input_is_valid(BTRIM(fecha), 'date')
          AND EXTRACT(MONTH FROM BTRIM(fecha)::date)::integer
              <> mes_num
    ) AS inconsistencias_fecha_mes

FROM datos;


-- =========================================================
-- 8. DOMINIO Y COBERTURA DE LINEA
--
-- Se conservan las representaciones originales.
-- =========================================================

SELECT
    BTRIM(linea) AS linea,
    COUNT(*) AS registros,
    COUNT(DISTINCT BTRIM(fecha)::date) AS dias_con_registro,
    MIN(BTRIM(fecha)::date) AS fecha_min,
    MAX(BTRIM(fecha)::date) AS fecha_max

FROM proyecto.cablebus_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')

GROUP BY BTRIM(linea)
ORDER BY fecha_min, linea;


-- =========================================================
-- 9. AUDITORÍA DE REPRESENTACIONES DE LINEA
--
-- Se inspeccionan también bytes para demostrar la diferencia
-- entre Linea y Línea.
-- =========================================================

SELECT
    '[' || BTRIM(linea) || ']' AS linea_visible,

    LENGTH(BTRIM(linea))
        AS longitud_caracteres,

    OCTET_LENGTH(BTRIM(linea))
        AS longitud_bytes,

    ENCODE(
        CONVERT_TO(BTRIM(linea), 'UTF8'),
        'hex'
    ) AS linea_hex,

    COUNT(*) AS registros,

    MIN(fecha) AS primera_fecha,
    MAX(fecha) AS ultima_fecha

FROM proyecto.cablebus_desglosada_stage

GROUP BY BTRIM(linea)
ORDER BY linea_hex;


-- =========================================================
-- 10. DOMINIO DE TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros

FROM proyecto.cablebus_desglosada_stage

GROUP BY BTRIM(tipo_pago)
ORDER BY tipo_pago;


-- =========================================================
-- 11. DUPLICADOS EXACTOS
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        mes,
        anio,
        linea,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.cablebus_desglosada_stage

    GROUP BY
        fecha,
        mes,
        anio,
        linea,
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
-- 12. GRANULARIDAD CANDIDATA
--
-- Hipótesis:
-- fecha × linea × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(linea) AS linea,
        BTRIM(tipo_pago) AS tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.cablebus_desglosada_stage

    GROUP BY
        BTRIM(fecha),
        BTRIM(linea),
        BTRIM(tipo_pago)

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
-- 13. ESTRUCTURA POR FECHA × LINEA
--
-- Esperado preliminar:
-- 2 filas y 2 tipos_pago por clave.
-- =========================================================

WITH grupos AS (

    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(linea) AS linea,

        COUNT(*) AS filas,

        COUNT(
            DISTINCT BTRIM(tipo_pago)
        ) AS tipos_pago

    FROM proyecto.cablebus_desglosada_stage

    GROUP BY
        BTRIM(fecha),
        BTRIM(linea)
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
-- 14. ESTADÍSTICA DE AFLUENCIA
-- =========================================================

WITH valores AS (

    SELECT
        BTRIM(afluencia)::numeric AS afluencia

    FROM proyecto.cablebus_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
    )
)

SELECT
    COUNT(*) AS valores_numericos,

    MIN(afluencia) AS minimo,

    percentile_cont(0.25)
        WITHIN GROUP (ORDER BY afluencia)
        AS q1,

    percentile_cont(0.50)
        WITHIN GROUP (ORDER BY afluencia)
        AS mediana,

    AVG(afluencia)::numeric(20,2)
        AS media,

    percentile_cont(0.75)
        WITHIN GROUP (ORDER BY afluencia)
        AS q3,

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
-- 15. VALORES MÁS ALTOS
-- =========================================================

SELECT
    fecha,
    mes,
    anio,
    linea,
    tipo_pago,
    afluencia

FROM proyecto.cablebus_desglosada_stage

WHERE pg_input_is_valid(
    BTRIM(afluencia),
    'numeric'
)

ORDER BY
    BTRIM(afluencia)::numeric DESC

LIMIT 20;


-- =========================================================
-- 16. OUTLIERS IQR
--
-- Una observación atípica NO implica error.
-- =========================================================

WITH valores AS (

    SELECT
        BTRIM(afluencia)::numeric AS afluencia

    FROM proyecto.cablebus_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
    )
),

cuartiles AS (

    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia)
            AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia)
            AS q3

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
-- 17. CEROS POR TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,

    COUNT(*) AS registros_cero

FROM proyecto.cablebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND BTRIM(afluencia)::numeric = 0

GROUP BY BTRIM(tipo_pago)
ORDER BY tipo_pago;


-- =========================================================
-- 18. CEROS POR LINEA
-- =========================================================

SELECT
    BTRIM(linea) AS linea,

    COUNT(*) AS registros_cero,

    MIN(BTRIM(fecha)::date)
        AS primera_fecha,

    MAX(BTRIM(fecha)::date)
        AS ultima_fecha

FROM proyecto.cablebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND pg_input_is_valid(
        BTRIM(fecha),
        'date'
      )

  AND BTRIM(afluencia)::numeric = 0

GROUP BY BTRIM(linea)
ORDER BY linea;


-- =========================================================
-- 19. POSIBLE MOJIBAKE
--
-- Busca patrones sospechosos sin corregirlos.
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE mes LIKE '%Ã%'
           OR linea LIKE '%Ã%'
           OR tipo_pago LIKE '%Ã%'
    ) AS filas_patron_1,

    COUNT(*) FILTER (
        WHERE mes LIKE '%Â%'
           OR linea LIKE '%Â%'
           OR tipo_pago LIKE '%Â%'
    ) AS filas_patron_2,

    COUNT(*) FILTER (
        WHERE mes LIKE '%�%'
           OR linea LIKE '%�%'
           OR tipo_pago LIKE '%�%'
    ) AS replacement_character

FROM proyecto.cablebus_desglosada_stage;


-- =========================================================
-- 20. TRANSICIÓN DE REPRESENTACIONES DE LINEA
--
-- Se extrae únicamente el número de línea para estudiar
-- si las variantes con/sin acento se solapan o se suceden.
--
-- Este bloque NO homologa la fuente.
-- =========================================================

WITH datos AS (

    SELECT
        regexp_replace(
            BTRIM(linea),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        BTRIM(linea) AS linea_original,

        BTRIM(fecha)::date AS fecha

    FROM proyecto.cablebus_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(fecha),
        'date'
    )
)

SELECT
    linea_num,
    linea_original,

    COUNT(DISTINCT fecha)
        AS dias,

    MIN(fecha)
        AS primera_fecha,

    MAX(fecha)
        AS ultima_fecha

FROM datos

GROUP BY
    linea_num,
    linea_original

ORDER BY
    linea_num::integer,
    primera_fecha;


-- =========================================================
-- 21. SEGURIDAD DE HOMOLOGACIÓN DE LINEA
--
-- Diagnóstico:
-- comprueba si llevar:
--
-- Línea 1 / Linea 1 -> Linea 1
-- Línea 2 / Linea 2 -> Linea 2
--
-- genera colisiones en:
-- fecha × linea_logica × tipo_pago
--
-- NO modifica datos.
-- =========================================================

WITH grupos AS (

    SELECT
        BTRIM(fecha) AS fecha,

        regexp_replace(
            BTRIM(linea),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        BTRIM(tipo_pago)
            AS tipo_pago,

        COUNT(*) AS veces

    FROM proyecto.cablebus_desglosada_stage

    GROUP BY
        BTRIM(fecha),

        regexp_replace(
            BTRIM(linea),
            '[^0-9]',
            '',
            'g'
        ),

        BTRIM(tipo_pago)
)

SELECT
    COUNT(*) FILTER (
        WHERE veces > 1
    ) AS claves_con_colision,

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

    COALESCE(
        MAX(veces) FILTER (
            WHERE veces > 1
        ),
        0
    ) AS max_repeticiones

FROM grupos;


-- =========================================================
-- 22. COBERTURA POR LÍNEA LÓGICA
--
-- Diagnóstico únicamente.
-- =========================================================

WITH datos AS (

    SELECT
        regexp_replace(
            BTRIM(linea),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        BTRIM(fecha)::date
            AS fecha

    FROM proyecto.cablebus_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(fecha),
        'date'
    )
)

SELECT
    linea_num,

    COUNT(DISTINCT fecha)
        AS dias_con_registro,

    MIN(fecha)
        AS fecha_min,

    MAX(fecha)
        AS fecha_max

FROM datos

GROUP BY linea_num

ORDER BY linea_num::integer;


-- =========================================================
-- 23. CONTROL FINAL
-- =========================================================

SELECT
    'STAGE_COUNT' AS prueba,

    COUNT(*)::text AS resultado,

    '7972' AS referencia,

    CASE
        WHEN COUNT(*) = 7972
        THEN 'OK'
        ELSE 'REVISAR'
    END AS estado

FROM proyecto.cablebus_desglosada_stage

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

FROM proyecto.cablebus_desglosada_stage

WHERE LOWER(BTRIM(afluencia)) = 'nan'

UNION ALL

SELECT
    'ZERO_COUNT',

    COUNT(*)::text,

    '207',

    CASE
        WHEN COUNT(*) = 207
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.cablebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )
  AND BTRIM(afluencia)::numeric = 0;