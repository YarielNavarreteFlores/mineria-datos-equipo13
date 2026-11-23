/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Trolebús

    PERFILADO PREVIO AL TIPADO

    Objetivo:
    comprender estructura, cobertura, convertibilidad,
    calidad, precisión numérica y granularidad de Trolebús
    antes de construir las capas TYPED y CLEAN.

    Evidencia RAW/STAGING previa:
    - 65,013 registros.
    - 6 columnas.
    - 0 filas malformadas.
    - Cobertura:
      2022-01-01 -> 2026-10-31.
    - 1,765 fechas distintas.
    - 3 tipos de pago.
    - 43 representaciones originales de linea.
    - 17 representaciones tras normalización gráfica
      exploratoria.
    - 0 duplicados exactos.
    - 0 colisiones en:
      fecha × linea × tipo_pago.
    - 20,246 ceros.
    - 0 NaN / no numéricos.
    - 0 negativos.
    - 1,419 valores con componente decimal.

    IMPORTANTE:
    - Este script NO modifica datos.
    - No elimina ceros.
    - No elimina outliers.
    - No redondea afluencia.
    - No homologa linea.
    - No impone restricciones UNIQUE.
    - Las normalizaciones realizadas son únicamente
      diagnósticas.
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
FROM proyecto.trolebus_desglosada_stage;


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

FROM proyecto.trolebus_desglosada_stage;


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

FROM proyecto.trolebus_desglosada_stage;


-- =========================================================
-- 4. COBERTURA TEMPORAL
-- =========================================================

SELECT
    MIN(BTRIM(fecha)::date) AS fecha_min,
    MAX(BTRIM(fecha)::date) AS fecha_max,
    COUNT(DISTINCT BTRIM(fecha)::date) AS fechas_distintas,

    MIN(BTRIM(anio)::smallint) AS anio_min,
    MAX(BTRIM(anio)::smallint) AS anio_max

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')
  AND pg_input_is_valid(BTRIM(anio), 'smallint');


-- =========================================================
-- 5. COHERENCIA FECHA <-> ANIO
-- =========================================================

SELECT
    COUNT(*) AS inconsistencias_fecha_anio

FROM proyecto.trolebus_desglosada_stage

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

FROM proyecto.trolebus_desglosada_stage

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

    FROM proyecto.trolebus_desglosada_stage
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
-- 8. DOMINIO DE TIPO_PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,
    COUNT(*) AS registros

FROM proyecto.trolebus_desglosada_stage

GROUP BY BTRIM(tipo_pago)
ORDER BY tipo_pago;


-- =========================================================
-- 9. DOMINIO ORIGINAL Y COBERTURA DE LINEA
--
-- Todavía NO se homologa.
-- =========================================================

SELECT
    BTRIM(linea) AS linea,

    COUNT(*) AS registros,

    COUNT(DISTINCT BTRIM(fecha)::date)
        AS dias_con_registro,

    MIN(BTRIM(fecha)::date)
        AS fecha_min,

    MAX(BTRIM(fecha)::date)
        AS fecha_max

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')

GROUP BY BTRIM(linea)

ORDER BY
    fecha_min,
    linea;


-- =========================================================
-- 10. AUDITORÍA DE REPRESENTACIONES DE LINEA
--
-- Permite observar diferencias de bytes, acentos,
-- mayúsculas, minúsculas y guiones bajos.
-- =========================================================

SELECT
    '[' || BTRIM(linea) || ']'
        AS linea_visible,

    LENGTH(BTRIM(linea))
        AS longitud_caracteres,

    OCTET_LENGTH(BTRIM(linea))
        AS longitud_bytes,

    ENCODE(
        CONVERT_TO(BTRIM(linea), 'UTF8'),
        'hex'
    ) AS linea_hex,

    COUNT(*) AS registros,

    MIN(BTRIM(fecha)::date)
        AS primera_fecha,

    MAX(BTRIM(fecha)::date)
        AS ultima_fecha

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(BTRIM(fecha), 'date')

GROUP BY BTRIM(linea)

ORDER BY linea_hex;


-- =========================================================
-- 11. NORMALIZACIÓN GRÁFICA EXPLORATORIA DE LINEA
--
-- Solo diagnóstico.
--
-- Cambios considerados:
-- - minúsculas
-- - acentos -> caracteres base
-- - "_" -> espacio
-- - espacios repetidos -> espacio único
--
-- NO elimina:
-- - "nochebus"
-- - "(trolebus elevado)"
--
-- Por lo tanto esas entidades permanecen distintas.
-- =========================================================

WITH datos AS (

    SELECT
        BTRIM(linea) AS linea_original,

        BTRIM(
            REGEXP_REPLACE(
                TRANSLATE(
                    REPLACE(
                        LOWER(BTRIM(linea)),
                        '_',
                        ' '
                    ),
                    'áéíóúüñ',
                    'aeiouun'
                ),
                '[[:space:]]+',
                ' ',
                'g'
            )
        ) AS linea_grafica

    FROM proyecto.trolebus_desglosada_stage
)

SELECT
    linea_grafica,

    COUNT(DISTINCT linea_original)
        AS representaciones_originales,

    STRING_AGG(
        DISTINCT linea_original,
        ' | '
        ORDER BY linea_original
    ) AS variantes,

    COUNT(*) AS registros

FROM datos

GROUP BY linea_grafica

ORDER BY linea_grafica;


-- =========================================================
-- 12. NÚMERO DE REPRESENTACIONES
-- =========================================================

WITH datos AS (

    SELECT
        BTRIM(linea) AS linea_original,

        BTRIM(
            REGEXP_REPLACE(
                TRANSLATE(
                    REPLACE(
                        LOWER(BTRIM(linea)),
                        '_',
                        ' '
                    ),
                    'áéíóúüñ',
                    'aeiouun'
                ),
                '[[:space:]]+',
                ' ',
                'g'
            )
        ) AS linea_grafica

    FROM proyecto.trolebus_desglosada_stage
)

SELECT
    COUNT(DISTINCT linea_original)
        AS representaciones_originales,

    COUNT(DISTINCT linea_grafica)
        AS representaciones_graficas

FROM datos;


-- =========================================================
-- 13. SEGURIDAD DE NORMALIZACIÓN GRÁFICA
--
-- Comprueba si la normalización propuesta únicamente
-- para diferencias gráficas provocaría colisiones en:
--
-- fecha × linea_grafica × tipo_pago
--
-- NO modifica la fuente.
-- =========================================================

WITH datos AS (

    SELECT
        BTRIM(fecha) AS fecha,

        BTRIM(
            REGEXP_REPLACE(
                TRANSLATE(
                    REPLACE(
                        LOWER(BTRIM(linea)),
                        '_',
                        ' '
                    ),
                    'áéíóúüñ',
                    'aeiouun'
                ),
                '[[:space:]]+',
                ' ',
                'g'
            )
        ) AS linea_grafica,

        BTRIM(tipo_pago) AS tipo_pago

    FROM proyecto.trolebus_desglosada_stage
),

grupos AS (

    SELECT
        fecha,
        linea_grafica,
        tipo_pago,
        COUNT(*) AS veces

    FROM datos

    GROUP BY
        fecha,
        linea_grafica,
        tipo_pago
)

SELECT
    COUNT(*) AS claves_normalizadas,

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
-- 14. DUPLICADOS EXACTOS
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

    FROM proyecto.trolebus_desglosada_stage

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
-- 15. GRANULARIDAD CANDIDATA
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

    FROM proyecto.trolebus_desglosada_stage

    GROUP BY
        BTRIM(fecha),
        BTRIM(linea),
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
-- 16. ESTRUCTURA FECHA × LINEA
--
-- Esperado:
-- 3 filas y 3 tipos_pago por clave.
-- =========================================================

WITH grupos AS (

    SELECT
        BTRIM(fecha) AS fecha,
        BTRIM(linea) AS linea,

        COUNT(*) AS filas,

        COUNT(
            DISTINCT BTRIM(tipo_pago)
        ) AS tipos_pago

    FROM proyecto.trolebus_desglosada_stage

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
-- 17. ESTADÍSTICA DE AFLUENCIA
-- =========================================================

WITH valores AS (

    SELECT
        BTRIM(afluencia)::numeric
            AS afluencia

    FROM proyecto.trolebus_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
    )
)

SELECT
    COUNT(*) AS valores_numericos,

    MIN(afluencia)
        AS minimo,

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

    MAX(afluencia)
        AS maximo,

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
-- 18. PRECISIÓN Y ESCALA OBSERVADAS DE AFLUENCIA
--
-- Este bloque ayudará a definir el tipo NUMERIC
-- de la capa TYPED sin pérdida de información.
-- =========================================================

WITH datos AS (

    SELECT
        BTRIM(afluencia) AS afluencia_txt

    FROM proyecto.trolebus_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
    )
),

perfil AS (

    SELECT
        afluencia_txt,

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
-- 19. DISTRIBUCIÓN DE ESCALA DECIMAL
-- =========================================================

WITH datos AS (

    SELECT
        BTRIM(afluencia) AS afluencia_txt

    FROM proyecto.trolebus_desglosada_stage

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
-- 20. DECIMALES POR AÑO
-- =========================================================

SELECT
    BTRIM(anio) AS anio,

    COUNT(*) AS registros_decimales

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND BTRIM(afluencia)::numeric
      <> TRUNC(BTRIM(afluencia)::numeric)

GROUP BY BTRIM(anio)

ORDER BY BTRIM(anio);


-- =========================================================
-- 21. DECIMALES POR TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,

    COUNT(*) AS registros_decimales

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND BTRIM(afluencia)::numeric
      <> TRUNC(BTRIM(afluencia)::numeric)

GROUP BY BTRIM(tipo_pago)

ORDER BY tipo_pago;


-- =========================================================
-- 22. DECIMALES POR LINEA
-- =========================================================

SELECT
    BTRIM(linea) AS linea,

    COUNT(*) AS registros_decimales,

    MIN(BTRIM(fecha)::date)
        AS primera_fecha,

    MAX(BTRIM(fecha)::date)
        AS ultima_fecha

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND pg_input_is_valid(
        BTRIM(fecha),
        'date'
      )

  AND BTRIM(afluencia)::numeric
      <> TRUNC(BTRIM(afluencia)::numeric)

GROUP BY BTRIM(linea)

ORDER BY
    registros_decimales DESC,
    linea;


-- =========================================================
-- 23. CEROS POR TIPO DE PAGO
-- =========================================================

SELECT
    BTRIM(tipo_pago) AS tipo_pago,

    COUNT(*) AS registros_cero

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND BTRIM(afluencia)::numeric = 0

GROUP BY BTRIM(tipo_pago)

ORDER BY tipo_pago;


-- =========================================================
-- 24. CEROS POR AÑO
-- =========================================================

SELECT
    BTRIM(anio) AS anio,

    COUNT(*) AS registros_cero

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )

  AND BTRIM(afluencia)::numeric = 0

GROUP BY BTRIM(anio)

ORDER BY BTRIM(anio);


-- =========================================================
-- 25. CEROS POR LINEA
-- =========================================================

SELECT
    BTRIM(linea) AS linea,

    COUNT(*) AS registros_cero,

    MIN(BTRIM(fecha)::date)
        AS primera_fecha,

    MAX(BTRIM(fecha)::date)
        AS ultima_fecha

FROM proyecto.trolebus_desglosada_stage

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

ORDER BY
    registros_cero DESC,
    linea;


-- =========================================================
-- 26. VALORES MÁS ALTOS
--
-- Solo diagnóstico.
-- Un valor alto NO implica error.
-- =========================================================

SELECT
    fecha,
    mes,
    anio,
    linea,
    tipo_pago,
    afluencia

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(
    BTRIM(afluencia),
    'numeric'
)

ORDER BY
    BTRIM(afluencia)::numeric DESC

LIMIT 20;


-- =========================================================
-- 27. OUTLIERS IQR GLOBAL
--
-- Una observación atípica NO implica error.
-- No se elimina nada.
-- =========================================================

WITH valores AS (

    SELECT
        BTRIM(afluencia)::numeric
            AS afluencia

    FROM proyecto.trolebus_desglosada_stage

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
-- 28. POSIBLE MOJIBAKE
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

FROM proyecto.trolebus_desglosada_stage;


-- =========================================================
-- 29. COBERTURA POR REPRESENTACIÓN GRÁFICA
--
-- Diagnóstico únicamente.
-- =========================================================

WITH datos AS (

    SELECT
        BTRIM(
            REGEXP_REPLACE(
                TRANSLATE(
                    REPLACE(
                        LOWER(BTRIM(linea)),
                        '_',
                        ' '
                    ),
                    'áéíóúüñ',
                    'aeiouun'
                ),
                '[[:space:]]+',
                ' ',
                'g'
            )
        ) AS linea_grafica,

        BTRIM(fecha)::date AS fecha

    FROM proyecto.trolebus_desglosada_stage

    WHERE pg_input_is_valid(
        BTRIM(fecha),
        'date'
    )
)

SELECT
    linea_grafica,

    COUNT(DISTINCT fecha)
        AS dias_con_registro,

    MIN(fecha)
        AS fecha_min,

    MAX(fecha)
        AS fecha_max

FROM datos

GROUP BY linea_grafica

ORDER BY linea_grafica;


-- =========================================================
-- 30. CONTROL FINAL
-- =========================================================

SELECT
    'STAGE_COUNT' AS prueba,

    COUNT(*)::text AS resultado,

    '65013' AS referencia,

    CASE
        WHEN COUNT(*) = 65013
        THEN 'OK'
        ELSE 'REVISAR'
    END AS estado

FROM proyecto.trolebus_desglosada_stage


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

FROM proyecto.trolebus_desglosada_stage

WHERE LOWER(BTRIM(afluencia)) = 'nan'


UNION ALL


SELECT
    'ZERO_COUNT',

    COUNT(*)::text,

    '20246',

    CASE
        WHEN COUNT(*) = 20246
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )
  AND BTRIM(afluencia)::numeric = 0


UNION ALL


SELECT
    'DECIMAL_COUNT',

    COUNT(*)::text,

    '1419',

    CASE
        WHEN COUNT(*) = 1419
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.trolebus_desglosada_stage

WHERE pg_input_is_valid(
        BTRIM(afluencia),
        'numeric'
      )
  AND BTRIM(afluencia)::numeric
      <> TRUNC(BTRIM(afluencia)::numeric)


UNION ALL


SELECT
    'LINE_REPRESENTATIONS',

    COUNT(DISTINCT BTRIM(linea))::text,

    '43',

    CASE
        WHEN COUNT(DISTINCT BTRIM(linea)) = 43
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.trolebus_desglosada_stage


UNION ALL


SELECT
    'TYPE_PAYMENT_COUNT',

    COUNT(DISTINCT BTRIM(tipo_pago))::text,

    '3',

    CASE
        WHEN COUNT(DISTINCT BTRIM(tipo_pago)) = 3
        THEN 'OK'
        ELSE 'REVISAR'
    END

FROM proyecto.trolebus_desglosada_stage;