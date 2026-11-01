/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metrobús

    PERFILADO PREVIO AL TIPADO

    Objetivo:
    comprender la calidad, estructura, cobertura,
    convertibilidad y granularidad de las tablas STAGING
    antes de construir TYPED y CLEAN.

    IMPORTANTE:
    - Este script NO modifica datos.
    - No convierte NaN a cero.
    - No elimina valores extremos.
    - No elimina duplicados ni colisiones.
    - No impone restricciones UNIQUE.
    - Las granularidades son hipótesis hasta comprobarlas.
*/


-- =========================================================
-- 0. ENTORNO
-- =========================================================

SELECT
    current_database() AS base_actual,
    current_user AS usuario,
    version() AS version_postgresql;


-- =========================================================
-- 1. CONTEOS BASE
-- =========================================================

SELECT
    'Simple' AS fuente,
    COUNT(*) AS registros
FROM proyecto.metrobus_simple_stage

UNION ALL

SELECT
    'Desglosada',
    COUNT(*)
FROM proyecto.metrobus_desglosada_stage;


-- =========================================================
-- 2. VALORES NULL / VACÍOS - SIMPLE
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(fecha), '') IS NULL
    ) AS vacios_fecha,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(anio), '') IS NULL
    ) AS vacios_anio,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(mes), '') IS NULL
    ) AS vacios_mes,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(linea), '') IS NULL
    ) AS vacios_linea,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(afluencia), '') IS NULL
    ) AS vacios_afluencia

FROM proyecto.metrobus_simple_stage;


-- =========================================================
-- 3. VALORES NULL / VACÍOS - DESGLOSADA
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

FROM proyecto.metrobus_desglosada_stage;


-- =========================================================
-- 4. CONVERTIBILIDAD - SIMPLE
--
-- NaN se cuantifica de forma independiente.
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
          AND NOT pg_input_is_valid(BTRIM(afluencia), 'integer')
    ) AS afluencia_invalida_distinta_nan,

    COUNT(*) FILTER (
        WHERE pg_input_is_valid(BTRIM(afluencia), 'integer')
    ) AS afluencia_entera_valida

FROM proyecto.metrobus_simple_stage;


-- =========================================================
-- 5. CONVERTIBILIDAD - DESGLOSADA
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
          AND NOT pg_input_is_valid(BTRIM(afluencia), 'integer')
    ) AS afluencia_invalida_distinta_nan,

    COUNT(*) FILTER (
        WHERE pg_input_is_valid(BTRIM(afluencia), 'integer')
    ) AS afluencia_entera_valida

FROM proyecto.metrobus_desglosada_stage;


-- =========================================================
-- 6. COBERTURA TEMPORAL REAL
-- =========================================================

SELECT
    'Simple' AS fuente,

    MIN(BTRIM(fecha)::date) AS fecha_min,
    MAX(BTRIM(fecha)::date) AS fecha_max,

    MIN(BTRIM(anio)::smallint) AS anio_min,
    MAX(BTRIM(anio)::smallint) AS anio_max,

    COUNT(DISTINCT BTRIM(fecha)::date) AS fechas_distintas

FROM proyecto.metrobus_simple_stage
WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint')

UNION ALL

SELECT
    'Desglosada',

    MIN(BTRIM(fecha)::date),
    MAX(BTRIM(fecha)::date),

    MIN(BTRIM(anio)::smallint),
    MAX(BTRIM(anio)::smallint),

    COUNT(DISTINCT BTRIM(fecha)::date)

FROM proyecto.metrobus_desglosada_stage
WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint');


-- =========================================================
-- 7. COBERTURA POR LÍNEA
--
-- No interpreta huecos como errores.
-- Solo describe la cobertura observada.
-- =========================================================

SELECT
    'Simple' AS fuente,
    BTRIM(linea) AS linea,
    MIN(BTRIM(fecha)::date) AS fecha_min,
    MAX(BTRIM(fecha)::date) AS fecha_max,
    COUNT(*) AS registros,
    COUNT(DISTINCT BTRIM(fecha)::date) AS dias_con_registro
FROM proyecto.metrobus_simple_stage
WHERE pg_input_is_valid(BTRIM(fecha), 'date')
GROUP BY BTRIM(linea)

UNION ALL

SELECT
    'Desglosada',
    BTRIM(linea),
    MIN(BTRIM(fecha)::date),
    MAX(BTRIM(fecha)::date),
    COUNT(*),
    COUNT(DISTINCT BTRIM(fecha)::date)
FROM proyecto.metrobus_desglosada_stage
WHERE pg_input_is_valid(BTRIM(fecha), 'date')
GROUP BY BTRIM(linea)

ORDER BY fuente, linea;


-- =========================================================
-- 8. COHERENCIA FECHA <-> ANIO
-- =========================================================

SELECT
    'Simple' AS fuente,
    COUNT(*) AS inconsistencias_anio
FROM proyecto.metrobus_simple_stage
WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint')
  AND EXTRACT(YEAR FROM BTRIM(fecha)::date)::smallint
      <> BTRIM(anio)::smallint

UNION ALL

SELECT
    'Desglosada',
    COUNT(*)
FROM proyecto.metrobus_desglosada_stage
WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint')
  AND EXTRACT(YEAR FROM BTRIM(fecha)::date)::smallint
      <> BTRIM(anio)::smallint;


-- =========================================================
-- 9. DOMINIO DE MES
-- =========================================================

SELECT
    'Simple' AS fuente,
    BTRIM(mes) AS mes,
    COUNT(*) AS registros
FROM proyecto.metrobus_simple_stage
GROUP BY BTRIM(mes)

UNION ALL

SELECT
    'Desglosada',
    BTRIM(mes),
    COUNT(*)
FROM proyecto.metrobus_desglosada_stage
GROUP BY BTRIM(mes)

ORDER BY fuente, mes;


-- =========================================================
-- 10. COHERENCIA FECHA <-> MES
-- =========================================================

WITH simple AS (
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

    FROM proyecto.metrobus_simple_stage
),

desglosada AS (
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

    FROM proyecto.metrobus_desglosada_stage
)

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE mes_num IS NULL
    ) AS mes_no_reconocido,

    COUNT(*) FILTER (
        WHERE mes_num IS NOT NULL
          AND pg_input_is_valid(BTRIM(fecha), 'date')
          AND EXTRACT(MONTH FROM BTRIM(fecha)::date)::integer
              <> mes_num
    ) AS inconsistencias_fecha_mes

FROM simple

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE mes_num IS NULL
    ),

    COUNT(*) FILTER (
        WHERE mes_num IS NOT NULL
          AND pg_input_is_valid(BTRIM(fecha), 'date')
          AND EXTRACT(MONTH FROM BTRIM(fecha)::date)::integer
              <> mes_num
    )

FROM desglosada;


-- =========================================================
-- 11. DOMINIO DE LÍNEAS
-- =========================================================

SELECT
    'Simple' AS fuente,
    BTRIM(linea) AS linea,
    COUNT(*) AS registros
FROM proyecto.metrobus_simple_stage
GROUP BY BTRIM(linea)

UNION ALL

SELECT
    'Desglosada',
    BTRIM(linea),
    COUNT(*)
FROM proyecto.metrobus_desglosada_stage
GROUP BY BTRIM(linea)

ORDER BY fuente, linea;


-- =========================================================
-- 12. DOMINIO DE TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros
FROM proyecto.metrobus_desglosada_stage
GROUP BY BTRIM(tipo_pago)
ORDER BY tipo_pago;


-- =========================================================
-- 13. ESTADÍSTICA DE AFLUENCIA NUMÉRICA
--
-- NaN y cualquier valor no convertible quedan fuera
-- de los estadísticos, pero NO se eliminan de STAGING.
-- =========================================================

WITH simple AS (
    SELECT
        BTRIM(afluencia)::bigint AS afluencia
    FROM proyecto.metrobus_simple_stage
    WHERE pg_input_is_valid(BTRIM(afluencia), 'bigint')
),

desglosada AS (
    SELECT
        BTRIM(afluencia)::bigint AS afluencia
    FROM proyecto.metrobus_desglosada_stage
    WHERE pg_input_is_valid(BTRIM(afluencia), 'bigint')
)

SELECT
    'Simple' AS fuente,

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
    ) AS negativos

FROM simple

UNION ALL

SELECT
    'Desglosada',

    COUNT(*),
    MIN(afluencia),

    percentile_cont(0.25)
        WITHIN GROUP (ORDER BY afluencia),

    percentile_cont(0.50)
        WITHIN GROUP (ORDER BY afluencia),

    AVG(afluencia)::numeric(20,2),

    percentile_cont(0.75)
        WITHIN GROUP (ORDER BY afluencia),

    MAX(afluencia),

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ),

    COUNT(*) FILTER (
        WHERE afluencia < 0
    )

FROM desglosada;


-- =========================================================
-- 14. VALORES MÁS ALTOS - SIMPLE
-- =========================================================

SELECT
    fecha,
    anio,
    mes,
    linea,
    afluencia
FROM proyecto.metrobus_simple_stage
WHERE pg_input_is_valid(BTRIM(afluencia), 'bigint')
ORDER BY BTRIM(afluencia)::bigint DESC
LIMIT 20;


-- =========================================================
-- 15. VALORES MÁS ALTOS - DESGLOSADA
-- =========================================================

SELECT
    fecha,
    mes,
    anio,
    linea,
    tipo_pago,
    afluencia
FROM proyecto.metrobus_desglosada_stage
WHERE pg_input_is_valid(BTRIM(afluencia), 'bigint')
ORDER BY BTRIM(afluencia)::bigint DESC
LIMIT 20;


-- =========================================================
-- 16. DISTRIBUCIÓN DE NaN EN SIMPLE - POR AÑO
-- =========================================================

SELECT
    BTRIM(anio) AS anio,
    COUNT(*) AS registros_nan
FROM proyecto.metrobus_simple_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan'
GROUP BY BTRIM(anio)
ORDER BY BTRIM(anio);


-- =========================================================
-- 17. DISTRIBUCIÓN DE NaN EN SIMPLE - POR LÍNEA
-- =========================================================

SELECT
    BTRIM(linea) AS linea,
    COUNT(*) AS registros_nan
FROM proyecto.metrobus_simple_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan'
GROUP BY BTRIM(linea)
ORDER BY linea;


-- =========================================================
-- 18. COBERTURA TEMPORAL DE NaN
-- =========================================================

SELECT
    MIN(BTRIM(fecha)::date) AS primer_nan,
    MAX(BTRIM(fecha)::date) AS ultimo_nan,
    COUNT(*) AS total_nan,
    COUNT(DISTINCT BTRIM(fecha)::date) AS dias_con_nan
FROM proyecto.metrobus_simple_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan'
  AND pg_input_is_valid(BTRIM(fecha), 'date');


-- =========================================================
-- 19. DUPLICADOS EXACTOS - SIMPLE
-- =========================================================

WITH grupos AS (
    SELECT
        fecha,
        anio,
        mes,
        linea,
        afluencia,
        COUNT(*) AS veces
    FROM proyecto.metrobus_simple_stage
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
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes,
    COALESCE(MAX(veces), 0) AS max_repeticiones
FROM grupos;


-- =========================================================
-- 20. DUPLICADOS EXACTOS - DESGLOSADA
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
    FROM proyecto.metrobus_desglosada_stage
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
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes,
    COALESCE(MAX(veces), 0) AS max_repeticiones
FROM grupos;


-- =========================================================
-- 21. COLISIONES DE GRANULARIDAD - SIMPLE
--
-- Hipótesis:
-- fecha × linea
-- =========================================================

WITH grupos AS (
    SELECT
        fecha,
        linea,
        COUNT(*) AS veces
    FROM proyecto.metrobus_simple_stage
    GROUP BY
        fecha,
        linea
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes,
    COALESCE(MAX(veces), 0) AS max_repeticiones
FROM grupos;


-- =========================================================
-- 22. EJEMPLOS DE COLISIONES - SIMPLE
-- =========================================================

SELECT
    fecha,
    linea,
    COUNT(*) AS veces
FROM proyecto.metrobus_simple_stage
GROUP BY
    fecha,
    linea
HAVING COUNT(*) > 1
ORDER BY veces DESC, fecha, linea
LIMIT 30;


-- =========================================================
-- 23. COLISIONES DE GRANULARIDAD - DESGLOSADA
--
-- Hipótesis:
-- fecha × linea × tipo_pago
-- =========================================================

WITH grupos AS (
    SELECT
        fecha,
        linea,
        tipo_pago,
        COUNT(*) AS veces
    FROM proyecto.metrobus_desglosada_stage
    GROUP BY
        fecha,
        linea,
        tipo_pago
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_con_colision,
    COALESCE(SUM(veces), 0) AS filas_involucradas,
    COALESCE(SUM(veces - 1), 0) AS registros_excedentes,
    COALESCE(MAX(veces), 0) AS max_repeticiones
FROM grupos;


-- =========================================================
-- 24. EJEMPLOS DE COLISIONES - DESGLOSADA
-- =========================================================

SELECT
    fecha,
    linea,
    tipo_pago,
    COUNT(*) AS veces
FROM proyecto.metrobus_desglosada_stage
GROUP BY
    fecha,
    linea,
    tipo_pago
HAVING COUNT(*) > 1
ORDER BY veces DESC, fecha, linea, tipo_pago
LIMIT 30;


-- =========================================================
-- 25. INDICADORES DE POSIBLE MOJIBAKE - SIMPLE
--
-- Buscar marcadores frecuentes no significa que
-- automáticamente se corregirán.
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE mes LIKE '%Ã%'
           OR linea LIKE '%Ã%'
    ) AS filas_con_patron_1,

    COUNT(*) FILTER (
        WHERE mes LIKE '%Â%'
           OR linea LIKE '%Â%'
    ) AS filas_con_patron_2,

    COUNT(*) FILTER (
        WHERE mes LIKE '%�%'
           OR linea LIKE '%�%'
    ) AS filas_con_replacement_character

FROM proyecto.metrobus_simple_stage;


-- =========================================================
-- 26. INDICADORES DE POSIBLE MOJIBAKE - DESGLOSADA
-- =========================================================

SELECT
    COUNT(*) FILTER (
        WHERE mes LIKE '%Ã%'
           OR linea LIKE '%Ã%'
           OR tipo_pago LIKE '%Ã%'
    ) AS filas_con_patron_1,

    COUNT(*) FILTER (
        WHERE mes LIKE '%Â%'
           OR linea LIKE '%Â%'
           OR tipo_pago LIKE '%Â%'
    ) AS filas_con_patron_2,

    COUNT(*) FILTER (
        WHERE mes LIKE '%�%'
           OR linea LIKE '%�%'
           OR tipo_pago LIKE '%�%'
    ) AS filas_con_replacement_character

FROM proyecto.metrobus_desglosada_stage;


-- =========================================================
-- 27. EJEMPLOS DE TEXTO SOSPECHOSO
-- =========================================================

SELECT DISTINCT
    'Simple' AS fuente,
    mes,
    linea,
    NULL::text AS tipo_pago
FROM proyecto.metrobus_simple_stage
WHERE mes LIKE '%Ã%'
   OR linea LIKE '%Ã%'
   OR mes LIKE '%Â%'
   OR linea LIKE '%Â%'
   OR mes LIKE '%�%'
   OR linea LIKE '%�%'

UNION

SELECT DISTINCT
    'Desglosada',
    mes,
    linea,
    tipo_pago
FROM proyecto.metrobus_desglosada_stage
WHERE mes LIKE '%Ã%'
   OR linea LIKE '%Ã%'
   OR tipo_pago LIKE '%Ã%'
   OR mes LIKE '%Â%'
   OR linea LIKE '%Â%'
   OR tipo_pago LIKE '%Â%'
   OR mes LIKE '%�%'
   OR linea LIKE '%�%'
   OR tipo_pago LIKE '%�%'

ORDER BY fuente, linea
LIMIT 50;


-- =========================================================
-- 28. SOLAPAMIENTO TEMPORAL SIMPLE VS DESGLOSADA
-- =========================================================

WITH simple AS (
    SELECT DISTINCT
        BTRIM(fecha)::date AS fecha
    FROM proyecto.metrobus_simple_stage
    WHERE pg_input_is_valid(BTRIM(fecha), 'date')
),

desglosada AS (
    SELECT DISTINCT
        BTRIM(fecha)::date AS fecha
    FROM proyecto.metrobus_desglosada_stage
    WHERE pg_input_is_valid(BTRIM(fecha), 'date')
)

SELECT
    MIN(s.fecha) AS primera_fecha_comun,
    MAX(s.fecha) AS ultima_fecha_comun,
    COUNT(*) AS fechas_comunes
FROM simple AS s
INNER JOIN desglosada AS d
    ON s.fecha = d.fecha;


-- =========================================================
-- 29. COMPARACIÓN DE MEDIDAS EN CLAVES COMUNES
--
-- Solo compara:
-- - afluencia numérica;
-- - fechas válidas;
-- - claves Simple que tengan exactamente una fila.
--
-- Desglosada se agrega por fecha × linea.
--
-- Esto NO declara todavía que las dos fuentes sean
-- semánticamente equivalentes.
-- =========================================================

WITH simple AS (
    SELECT
        BTRIM(fecha)::date AS fecha,
        BTRIM(linea) AS linea,

        COUNT(*) AS filas_simple,

        SUM(
            CASE
                WHEN pg_input_is_valid(BTRIM(afluencia), 'bigint')
                THEN BTRIM(afluencia)::bigint
            END
        ) AS afluencia_simple

    FROM proyecto.metrobus_simple_stage

    WHERE pg_input_is_valid(BTRIM(fecha), 'date')

    GROUP BY
        BTRIM(fecha)::date,
        BTRIM(linea)
),

desglosada AS (
    SELECT
        BTRIM(fecha)::date AS fecha,
        BTRIM(linea) AS linea,

        SUM(
            CASE
                WHEN pg_input_is_valid(BTRIM(afluencia), 'bigint')
                THEN BTRIM(afluencia)::bigint
            END
        ) AS afluencia_desglosada

    FROM proyecto.metrobus_desglosada_stage

    WHERE pg_input_is_valid(BTRIM(fecha), 'date')

    GROUP BY
        BTRIM(fecha)::date,
        BTRIM(linea)
),

comparacion AS (
    SELECT
        s.fecha,
        s.linea,
        s.afluencia_simple,
        d.afluencia_desglosada,
        s.afluencia_simple - d.afluencia_desglosada
            AS diferencia

    FROM simple AS s

    INNER JOIN desglosada AS d
        ON s.fecha = d.fecha
       AND s.linea = d.linea

    WHERE s.filas_simple = 1
      AND s.afluencia_simple IS NOT NULL
      AND d.afluencia_desglosada IS NOT NULL
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

    AVG(diferencia)::numeric(20,2) AS diferencia_media,

    MAX(diferencia) AS diferencia_max

FROM comparacion;


-- =========================================================
-- 30. EJEMPLOS DE DIFERENCIAS ENTRE SIMPLE Y DESGLOSADA
-- =========================================================

WITH simple AS (
    SELECT
        BTRIM(fecha)::date AS fecha,
        BTRIM(linea) AS linea,

        COUNT(*) AS filas_simple,

        SUM(
            CASE
                WHEN pg_input_is_valid(BTRIM(afluencia), 'bigint')
                THEN BTRIM(afluencia)::bigint
            END
        ) AS afluencia_simple

    FROM proyecto.metrobus_simple_stage

    WHERE pg_input_is_valid(BTRIM(fecha), 'date')

    GROUP BY
        BTRIM(fecha)::date,
        BTRIM(linea)
),

desglosada AS (
    SELECT
        BTRIM(fecha)::date AS fecha,
        BTRIM(linea) AS linea,

        SUM(
            CASE
                WHEN pg_input_is_valid(BTRIM(afluencia), 'bigint')
                THEN BTRIM(afluencia)::bigint
            END
        ) AS afluencia_desglosada

    FROM proyecto.metrobus_desglosada_stage

    WHERE pg_input_is_valid(BTRIM(fecha), 'date')

    GROUP BY
        BTRIM(fecha)::date,
        BTRIM(linea)
)

SELECT
    s.fecha,
    s.linea,
    s.afluencia_simple,
    d.afluencia_desglosada,
    s.afluencia_simple - d.afluencia_desglosada
        AS diferencia

FROM simple AS s

INNER JOIN desglosada AS d
    ON s.fecha = d.fecha
   AND s.linea = d.linea

WHERE s.filas_simple = 1
  AND s.afluencia_simple IS NOT NULL
  AND d.afluencia_desglosada IS NOT NULL
  AND s.afluencia_simple <> d.afluencia_desglosada

ORDER BY
    ABS(s.afluencia_simple - d.afluencia_desglosada) DESC

LIMIT 30;


-- =========================================================
-- 31. RESUMEN DE CONTROL DEL PERFILADO
--
-- Estos controles NO equivalen a validación final.
-- =========================================================

SELECT
    'SIMPLE_STAGE_COUNT' AS prueba,
    COUNT(*)::text AS resultado,
    '54159' AS referencia,
    CASE
        WHEN COUNT(*) = 54159
        THEN 'OK'
        ELSE 'REVISAR'
    END AS estado
FROM proyecto.metrobus_simple_stage

UNION ALL

SELECT
    'DESGLOSADA_STAGE_COUNT',
    COUNT(*)::text,
    '29386',
    CASE
        WHEN COUNT(*) = 29386
        THEN 'OK'
        ELSE 'REVISAR'
    END
FROM proyecto.metrobus_desglosada_stage

UNION ALL

SELECT
    'SIMPLE_NAN',
    COUNT(*)::text,
    'OBSERVACIÓN',
    'PERFILAR'
FROM proyecto.metrobus_simple_stage
WHERE LOWER(BTRIM(afluencia)) = 'nan';


-- =========================================================
-- 32. CIERRE DE COHERENCIA TEMPORAL
-- fecha <-> anio y fecha <-> mes
-- =========================================================

WITH datos AS (

    SELECT
        'Simple'::text AS fuente,
        fecha,
        anio,
        mes
    FROM proyecto.metrobus_simple_stage

    UNION ALL

    SELECT
        'Desglosada',
        fecha,
        anio,
        mes
    FROM proyecto.metrobus_desglosada_stage

),

preparado AS (

    SELECT
        fuente,
        fecha,
        anio,
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

    FROM datos
)

SELECT
    fuente,

    COUNT(*) FILTER (
        WHERE mes_num IS NULL
    ) AS mes_no_reconocido,

    COUNT(*) FILTER (
        WHERE pg_input_is_valid(BTRIM(fecha), 'date')
          AND pg_input_is_valid(BTRIM(anio), 'smallint')
          AND EXTRACT(YEAR FROM BTRIM(fecha)::date)::smallint
              <> BTRIM(anio)::smallint
    ) AS inconsistencias_fecha_anio,

    COUNT(*) FILTER (
        WHERE pg_input_is_valid(BTRIM(fecha), 'date')
          AND mes_num IS NOT NULL
          AND EXTRACT(MONTH FROM BTRIM(fecha)::date)::integer
              <> mes_num
    ) AS inconsistencias_fecha_mes

FROM preparado
GROUP BY fuente
ORDER BY fuente;


-- =========================================================
-- 33. IDENTIFICAR LOS 57 VALORES NO CONVERTIBLES
-- DISTINTOS DE NaN
--
-- Los corchetes y el hexadecimal permiten detectar
-- espacios o caracteres invisibles.
-- =========================================================

WITH invalidos AS (

    SELECT
        'Simple'::text AS fuente,
        fecha,
        linea,
        NULL::text AS tipo_pago,
        afluencia
    FROM proyecto.metrobus_simple_stage
    WHERE NULLIF(BTRIM(afluencia), '') IS NOT NULL
      AND LOWER(BTRIM(afluencia)) <> 'nan'
      AND NOT pg_input_is_valid(BTRIM(afluencia), 'integer')

    UNION ALL

    SELECT
        'Desglosada',
        fecha,
        linea,
        tipo_pago,
        afluencia
    FROM proyecto.metrobus_desglosada_stage
    WHERE NULLIF(BTRIM(afluencia), '') IS NOT NULL
      AND LOWER(BTRIM(afluencia)) <> 'nan'
      AND NOT pg_input_is_valid(BTRIM(afluencia), 'integer')
)

SELECT
    fuente,

    '[' || afluencia || ']' AS valor_visible,

    LENGTH(afluencia) AS longitud_caracteres,

    OCTET_LENGTH(afluencia) AS longitud_bytes,

    ENCODE(
        CONVERT_TO(afluencia, 'UTF8'),
        'hex'
    ) AS valor_hex,

    COUNT(*) AS registros,

    MIN(fecha) AS primera_fecha,
    MAX(fecha) AS ultima_fecha

FROM invalidos

GROUP BY
    fuente,
    afluencia

ORDER BY
    fuente,
    registros DESC;


-- =========================================================
-- 34. AUDITORÍA DE LAS VARIANTES TEXTUALES DE LINEA
--
-- GROUP BY ya mostró varias categorías visualmente
-- similares. Se inspeccionan bytes y cobertura.
-- =========================================================

WITH lineas AS (

    SELECT
        'Simple'::text AS fuente,
        fecha,
        linea
    FROM proyecto.metrobus_simple_stage

    UNION ALL

    SELECT
        'Desglosada',
        fecha,
        linea
    FROM proyecto.metrobus_desglosada_stage
)

SELECT
    fuente,

    '[' || BTRIM(linea) || ']' AS linea_visible,

    LENGTH(BTRIM(linea)) AS longitud_caracteres,

    OCTET_LENGTH(BTRIM(linea)) AS longitud_bytes,

    ENCODE(
        CONVERT_TO(BTRIM(linea), 'UTF8'),
        'hex'
    ) AS linea_hex,

    COUNT(*) AS registros,

    MIN(fecha) AS primera_fecha,
    MAX(fecha) AS ultima_fecha

FROM lineas

GROUP BY
    fuente,
    BTRIM(linea)

ORDER BY
    fuente,
    linea_hex;


-- =========================================================
-- 35. TRANSICIÓN NaN -> VALOR NUMÉRICO POR LÍNEA
--
-- Se utiliza únicamente el número de línea como agrupador
-- analítico para evitar que variantes Unicode dividan
-- artificialmente el resultado.
-- =========================================================

WITH datos AS (

    SELECT
        regexp_replace(
            BTRIM(linea),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        BTRIM(fecha)::date AS fecha,

        BTRIM(afluencia) AS afluencia

    FROM proyecto.metrobus_simple_stage

    WHERE pg_input_is_valid(BTRIM(fecha), 'date')
)

SELECT
    linea_num,

    COUNT(*) FILTER (
        WHERE LOWER(afluencia) = 'nan'
    ) AS cantidad_nan,

    MIN(fecha) FILTER (
        WHERE LOWER(afluencia) = 'nan'
    ) AS primer_nan,

    MAX(fecha) FILTER (
        WHERE LOWER(afluencia) = 'nan'
    ) AS ultimo_nan,

    MIN(fecha) FILTER (
        WHERE pg_input_is_valid(afluencia, 'integer')
    ) AS primer_valor_numerico,

    MAX(fecha) FILTER (
        WHERE pg_input_is_valid(afluencia, 'integer')
    ) AS ultimo_valor_numerico

FROM datos

GROUP BY linea_num
ORDER BY linea_num::integer;


-- =========================================================
-- 36. OUTLIERS IQR GLOBALES - TODOS LOS NUMÉRICOS
--
-- Incluye enteros y decimales válidos.
-- NaN queda fuera porque en TYPED representa NULL.
-- Una observación atípica NO se considera error.
-- =========================================================

WITH valores AS (

    SELECT
        'Simple'::text AS fuente,
        BTRIM(afluencia)::numeric AS afluencia
    FROM proyecto.metrobus_simple_stage
    WHERE LOWER(BTRIM(afluencia)) <> 'nan'
      AND pg_input_is_valid(BTRIM(afluencia), 'numeric')

    UNION ALL

    SELECT
        'Desglosada',
        BTRIM(afluencia)::numeric
    FROM proyecto.metrobus_desglosada_stage
    WHERE pg_input_is_valid(BTRIM(afluencia), 'numeric')
),

cuartiles AS (

    SELECT
        fuente,

        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia) AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia) AS q3

    FROM valores

    GROUP BY fuente
),

resultado AS (

    SELECT
        v.fuente,
        v.afluencia,
        c.q1,
        c.q3,
        c.q3 - c.q1 AS iqr

    FROM valores AS v

    INNER JOIN cuartiles AS c
        ON v.fuente = c.fuente
)

SELECT
    fuente,

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
    fuente,
    q1,
    q3,
    iqr

ORDER BY fuente;


-- =========================================================
-- 37. RELACIÓN DE LOS 57 CASOS NO NUMÉRICOS
-- SIMPLE VS DESGLOSADA
--
-- Se compara la clave fecha × número de línea.
-- No transforma las fuentes.
-- =========================================================

WITH simple AS (

    SELECT DISTINCT
        BTRIM(fecha)::date AS fecha,

        regexp_replace(
            BTRIM(linea),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num

    FROM proyecto.metrobus_simple_stage

    WHERE pg_input_is_valid(BTRIM(fecha), 'date')
      AND NULLIF(BTRIM(afluencia), '') IS NOT NULL
      AND LOWER(BTRIM(afluencia)) <> 'nan'
      AND NOT pg_input_is_valid(BTRIM(afluencia), 'integer')
),

desglosada AS (

    SELECT DISTINCT
        BTRIM(fecha)::date AS fecha,

        regexp_replace(
            BTRIM(linea),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num

    FROM proyecto.metrobus_desglosada_stage

    WHERE pg_input_is_valid(BTRIM(fecha), 'date')
      AND NULLIF(BTRIM(afluencia), '') IS NOT NULL
      AND LOWER(BTRIM(afluencia)) <> 'nan'
      AND NOT pg_input_is_valid(BTRIM(afluencia), 'integer')
)

SELECT
    (SELECT COUNT(*) FROM simple)
        AS claves_invalidas_simple,

    (SELECT COUNT(*) FROM desglosada)
        AS claves_invalidas_desglosada,

    (
        SELECT COUNT(*)
        FROM simple AS s
        INNER JOIN desglosada AS d
            ON s.fecha = d.fecha
           AND s.linea_num = d.linea_num
    ) AS claves_invalidas_comunes;


-- =========================================================
-- 38. GRANULARIDAD DESPUÉS DE HOMOLOGAR LINEA
--
-- Comprueba que las variantes:
-- Linea 1 / Línea 1 / linea 1
-- no produzcan colisiones al llevarlas a una línea lógica.
-- =========================================================

WITH simple AS (
    SELECT
        BTRIM(fecha) AS fecha,

        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        COUNT(*) AS veces

    FROM proyecto.metrobus_simple_stage

    GROUP BY
        BTRIM(fecha),
        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        )
),

desglosada AS (
    SELECT
        BTRIM(fecha) AS fecha,

        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        BTRIM(tipo_pago) AS tipo_pago,

        COUNT(*) AS veces

    FROM proyecto.metrobus_desglosada_stage

    GROUP BY
        BTRIM(fecha),

        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        ),

        BTRIM(tipo_pago)
)

SELECT
    'Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE veces > 1
    ) AS claves_con_colision,

    COALESCE(
        SUM(veces) FILTER (
            WHERE veces > 1
        ),
        0
    ) AS filas_involucradas

FROM simple

UNION ALL

SELECT
    'Desglosada',

    COUNT(*) FILTER (
        WHERE veces > 1
    ),

    COALESCE(
        SUM(veces) FILTER (
            WHERE veces > 1
        ),
        0
    )

FROM desglosada;


-- =========================================================
-- 39. CONCILIACIÓN NUMÉRICA COMPLETA
--
-- A diferencia de la comparación anterior,
-- NUMERIC permite incluir los 57 valores decimales.
--
-- NaN de Simple se excluye explícitamente porque representa
-- ausencia de medida, no un valor de afluencia.
-- =========================================================

WITH simple AS (

    SELECT
        BTRIM(fecha)::date AS fecha,

        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        BTRIM(afluencia)::numeric AS afluencia_simple

    FROM proyecto.metrobus_simple_stage

    WHERE pg_input_is_valid(BTRIM(fecha), 'date')

      AND LOWER(BTRIM(afluencia)) <> 'nan'

      AND pg_input_is_valid(
          BTRIM(afluencia),
          'numeric'
      )
),

desglosada AS (

    SELECT
        BTRIM(fecha)::date AS fecha,

        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        ) AS linea_num,

        SUM(
            BTRIM(afluencia)::numeric
        ) AS afluencia_desglosada

    FROM proyecto.metrobus_desglosada_stage

    WHERE pg_input_is_valid(BTRIM(fecha), 'date')

      AND LOWER(BTRIM(afluencia)) <> 'nan'

      AND pg_input_is_valid(
          BTRIM(afluencia),
          'numeric'
      )

    GROUP BY
        BTRIM(fecha)::date,

        regexp_replace(
            LOWER(BTRIM(linea)),
            '[^0-9]',
            '',
            'g'
        )
),

comparacion AS (

    SELECT
        s.fecha,
        s.linea_num,
        s.afluencia_simple,
        d.afluencia_desglosada,

        s.afluencia_simple
        - d.afluencia_desglosada
            AS diferencia

    FROM simple AS s

    INNER JOIN desglosada AS d
        ON s.fecha = d.fecha
       AND s.linea_num = d.linea_num
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