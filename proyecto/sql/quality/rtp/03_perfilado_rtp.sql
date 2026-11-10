/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: RTP

    PERFILADO PREVIO AL TIPADO

    Objetivo:
    comprender estructura, cobertura, convertibilidad,
    calidad y granularidad de RTP antes de construir
    TYPED y CLEAN.

    IMPORTANTE:
    - Este script NO modifica datos.
    - NaN NO se convierte a cero.
    - No se eliminan ceros.
    - No se eliminan outliers.
    - No se homologan valores de servicio.
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
FROM proyecto.rtp_desglosada_stage;


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
        WHERE NULLIF(BTRIM(servicio), '') IS NULL
    ) AS vacios_servicio,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(tipo_pago), '') IS NULL
    ) AS vacios_tipo_pago,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NULL
    ) AS vacios_afluencia

FROM proyecto.rtp_desglosada_stage;


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
    ) AS afluencia_invalida_distinta_nan,

    COUNT(*) FILTER (
        WHERE LOWER(BTRIM(afluencia)) <> 'nan'
          AND pg_input_is_valid(BTRIM(afluencia), 'numeric')
    ) AS afluencia_numerica_finita

FROM proyecto.rtp_desglosada_stage;


-- =========================================================
-- 4. COBERTURA TEMPORAL
-- =========================================================

SELECT
    MIN(BTRIM(fecha)::date) AS fecha_min,
    MAX(BTRIM(fecha)::date) AS fecha_max,
    COUNT(DISTINCT BTRIM(fecha)::date) AS fechas_distintas,
    MIN(BTRIM(anio)::smallint) AS anio_min,
    MAX(BTRIM(anio)::smallint) AS anio_max

FROM proyecto.rtp_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint');


-- =========================================================
-- 5. COHERENCIA FECHA <-> ANIO
-- =========================================================

SELECT
    COUNT(*) AS inconsistencias_fecha_anio

FROM proyecto.rtp_desglosada_stage

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

FROM proyecto.rtp_desglosada_stage

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

    FROM proyecto.rtp_desglosada_stage
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
-- 8. DOMINIO Y COBERTURA DE SERVICIO
-- =========================================================

SELECT
    BTRIM(servicio) AS servicio,
    COUNT(*) AS registros,
    MIN(BTRIM(fecha)::date) AS fecha_min,
    MAX(BTRIM(fecha)::date) AS fecha_max,
    COUNT(DISTINCT BTRIM(fecha)::date) AS dias_con_registro

FROM proyecto.rtp_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')

GROUP BY BTRIM(servicio)
ORDER BY fecha_min, servicio;


-- =========================================================
-- 9. DOMINIO DE TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros

FROM proyecto.rtp_desglosada_stage

GROUP BY BTRIM(tipo_pago)
ORDER BY tipo_pago;


-- =========================================================
-- 10. DUPLICADOS EXACTOS
-- =========================================================

WITH grupos AS (

    SELECT
        fecha,
        mes,
        anio,
        servicio,
        tipo_pago,
        afluencia,
        COUNT(*) AS veces

    FROM proyecto.rtp_desglosada_stage

    GROUP BY
        fecha,
        mes,
        anio,
        servicio,
        tipo_pago,
        afluencia

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_duplicados_exactos,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes,
    COALESCE(MAX(veces), 0) AS max_repeticiones

FROM grupos;


-- =========================================================
-- 11. GRANULARIDAD CANDIDATA
--
-- Hipótesis:
-- fecha × servicio × tipo_pago
-- =========================================================

WITH grupos AS (

    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(servicio) AS servicio,
        BTRIM(tipo_pago) AS tipo_pago,
        COUNT(*) AS veces

    FROM proyecto.rtp_desglosada_stage

    GROUP BY
        BTRIM(fecha),
        BTRIM(servicio),
        BTRIM(tipo_pago)

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes,
    COALESCE(MAX(veces), 0) AS max_repeticiones

FROM grupos;


-- =========================================================
-- 12. ESTRUCTURA POR FECHA × SERVICIO
--
-- Verifica cuántos tipos de pago existen por unidad candidata.
-- =========================================================

WITH grupos AS (

    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(servicio) AS servicio,
        COUNT(*) AS filas,
        COUNT(DISTINCT BTRIM(tipo_pago)) AS tipos_pago

    FROM proyecto.rtp_desglosada_stage

    GROUP BY
        BTRIM(fecha),
        BTRIM(servicio)
)

SELECT
    filas,
    tipos_pago,
    COUNT(*) AS claves_fecha_servicio

FROM grupos

GROUP BY
    filas,
    tipos_pago

ORDER BY
    filas,
    tipos_pago;


-- =========================================================
-- 13. NaN POR TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros_nan

FROM proyecto.rtp_desglosada_stage

WHERE LOWER(BTRIM(afluencia)) = 'nan'

GROUP BY BTRIM(tipo_pago)
ORDER BY tipo_pago;


-- =========================================================
-- 14. NaN POR SERVICIO
-- =========================================================

SELECT
    BTRIM(servicio) AS servicio,
    COUNT(*) AS registros_nan,
    MIN(BTRIM(fecha)::date) AS primer_nan,
    MAX(BTRIM(fecha)::date) AS ultimo_nan

FROM proyecto.rtp_desglosada_stage

WHERE LOWER(BTRIM(afluencia)) = 'nan'
  AND pg_input_is_valid(BTRIM(fecha), 'date')

GROUP BY BTRIM(servicio)
ORDER BY registros_nan DESC, servicio;


-- =========================================================
-- 15. ESTADÍSTICA DE AFLUENCIA
--
-- NaN queda fuera de los estadísticos.
-- Los decimales válidos se preservan mediante NUMERIC.
-- =========================================================

WITH valores AS (

    SELECT
        BTRIM(afluencia)::numeric AS afluencia

    FROM proyecto.rtp_desglosada_stage

    WHERE LOWER(BTRIM(afluencia)) <> 'nan'
      AND pg_input_is_valid(BTRIM(afluencia), 'numeric')
)

SELECT
    COUNT(*) AS valores_numericos,

    MIN(afluencia) AS minimo,

    percentile_cont(0.25)
        WITHIN GROUP (ORDER BY afluencia) AS q1,

    percentile_cont(0.50)
        WITHIN GROUP (ORDER BY afluencia) AS mediana,

    AVG(afluencia)::numeric(20,2) AS media,

    percentile_cont(0.75)
        WITHIN GROUP (ORDER BY afluencia) AS q3,

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
-- 16. VALORES MÁS ALTOS
-- =========================================================

SELECT
    fecha,
    mes,
    anio,
    servicio,
    tipo_pago,
    afluencia

FROM proyecto.rtp_desglosada_stage

WHERE LOWER(BTRIM(afluencia)) <> 'nan'
  AND pg_input_is_valid(BTRIM(afluencia), 'numeric')

ORDER BY BTRIM(afluencia)::numeric DESC
LIMIT 20;


-- =========================================================
-- 17. OUTLIERS IQR
--
-- Una observación atípica NO implica error.
-- =========================================================

WITH valores AS (

    SELECT
        BTRIM(afluencia)::numeric AS afluencia

    FROM proyecto.rtp_desglosada_stage

    WHERE LOWER(BTRIM(afluencia)) <> 'nan'
      AND pg_input_is_valid(BTRIM(afluencia), 'numeric')
),

cuartiles AS (

    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia) AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia) AS q3

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

    q1 - 1.5 * iqr AS limite_inferior,
    q3 + 1.5 * iqr AS limite_superior,

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
-- 18. CEROS POR TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros_cero

FROM proyecto.rtp_desglosada_stage

WHERE LOWER(BTRIM(afluencia)) <> 'nan'
  AND pg_input_is_valid(BTRIM(afluencia), 'numeric')
  AND BTRIM(afluencia)::numeric = 0

GROUP BY BTRIM(tipo_pago)
ORDER BY tipo_pago;


-- =========================================================
-- 19. CONTROL FINAL DE PERFILADO
-- =========================================================

SELECT
    'STAGE_COUNT' AS prueba,
    COUNT(*)::text AS resultado,
    '41676' AS referencia,

    CASE
        WHEN COUNT(*) = 41676
        THEN 'OK'
        ELSE 'REVISAR'
    END AS estado

FROM proyecto.rtp_desglosada_stage

UNION ALL

SELECT
    'NAN_COUNT',
    COUNT(*)::text,
    '187',
    CASE
        WHEN COUNT(*) = 187
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.rtp_desglosada_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan';