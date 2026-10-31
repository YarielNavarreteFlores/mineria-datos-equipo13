/*
    PROYECTO SEMESTRAL - MINERÍA DE DATOS
    Sistema: Metro

    CAPA CLEAN

    Objetivos:
    - corregir representación textual;
    - homologar categorías;
    - generar variables temporales;
    - generar indicadores de calidad;
    - conservar el 100 % de los registros.

    IMPORTANTE:
    RAW, STAGE y TYPED permanecen intactas.
*/


-- =========================================================
-- 1. REINICIO CONTROLADO
-- =========================================================

DROP TABLE IF EXISTS proyecto.metro_simple_clean;
DROP TABLE IF EXISTS proyecto.metro_desglosada_clean;


-- =========================================================
-- 2. ESTRUCTURA CLEAN - SIMPLE
-- =========================================================

CREATE TABLE proyecto.metro_simple_clean (
    fecha                  DATE,
    anio                   SMALLINT,
    mes                    TEXT,
    mes_num                SMALLINT,
    dia_semana_num         SMALLINT,
    dia_semana             TEXT,
    es_fin_semana          BOOLEAN,
    linea                  TEXT,
    estacion               TEXT,
    afluencia              INTEGER,

    es_afluencia_cero      BOOLEAN,
    es_colision_clave      BOOLEAN,
    es_outlier_iqr_global  BOOLEAN,
    es_texto_corregido     BOOLEAN
);


-- =========================================================
-- 3. ESTRUCTURA CLEAN - DESGLOSADA
-- =========================================================

CREATE TABLE proyecto.metro_desglosada_clean (
    fecha                  DATE,
    anio                   SMALLINT,
    mes                    TEXT,
    mes_num                SMALLINT,
    dia_semana_num         SMALLINT,
    dia_semana             TEXT,
    es_fin_semana          BOOLEAN,
    linea                  TEXT,
    estacion               TEXT,
    tipo_pago              TEXT,
    afluencia              INTEGER,

    es_afluencia_cero      BOOLEAN,
    es_colision_clave      BOOLEAN,
    es_outlier_iqr_global  BOOLEAN,
    es_texto_corregido     BOOLEAN
);


-- =========================================================
-- 4. TRANSFORMACIÓN CLEAN - SIMPLE
-- =========================================================

WITH texto_corregido AS (
    SELECT
        fecha,
        anio,
        mes,

        CASE
            WHEN linea LIKE '%Ã%'
            THEN convert_from(
                convert_to(linea, 'LATIN1'),
                'UTF8'
            )
            ELSE linea
        END AS linea_corregida,

        CASE
            WHEN estacion LIKE '%Ã%'
            THEN convert_from(
                convert_to(estacion, 'LATIN1'),
                'UTF8'
            )
            ELSE estacion
        END AS estacion_corregida,

        afluencia,

        (
            linea LIKE '%Ã%'
            OR estacion LIKE '%Ã%'
        ) AS es_texto_corregido

    FROM proyecto.metro_simple_typed
),

normalizado AS (
    SELECT
        fecha,
        anio,
        BTRIM(mes) AS mes,

        regexp_replace(
            BTRIM(linea_corregida),
            '^L[ií]nea\s*',
            'Línea ',
            'i'
        ) AS linea,

        BTRIM(estacion_corregida) AS estacion,

        afluencia,
        es_texto_corregido

    FROM texto_corregido
),

cuartiles AS (
    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia) AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia) AS q3

    FROM normalizado
),

preparado AS (
    SELECT
        n.*,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                linea,
                estacion
        ) AS cantidad_clave,

        c.q1,
        c.q3,
        c.q3 - c.q1 AS iqr

    FROM normalizado AS n
    CROSS JOIN cuartiles AS c
)

INSERT INTO proyecto.metro_simple_clean (
    fecha,
    anio,
    mes,
    mes_num,
    dia_semana_num,
    dia_semana,
    es_fin_semana,
    linea,
    estacion,
    afluencia,
    es_afluencia_cero,
    es_colision_clave,
    es_outlier_iqr_global,
    es_texto_corregido
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

    linea,
    estacion,
    afluencia,

    afluencia = 0,

    cantidad_clave > 1,

    (
        afluencia < q1 - 1.5 * iqr
        OR
        afluencia > q3 + 1.5 * iqr
    ),

    es_texto_corregido

FROM preparado;


-- =========================================================
-- 5. TRANSFORMACIÓN CLEAN - DESGLOSADA
-- =========================================================

WITH texto_corregido AS (
    SELECT
        fecha,
        anio,
        mes,

        CASE
            WHEN linea LIKE '%Ã%'
            THEN convert_from(
                convert_to(linea, 'LATIN1'),
                'UTF8'
            )
            ELSE linea
        END AS linea_corregida,

        CASE
            WHEN estacion LIKE '%Ã%'
            THEN convert_from(
                convert_to(estacion, 'LATIN1'),
                'UTF8'
            )
            ELSE estacion
        END AS estacion_corregida,

        BTRIM(tipo_pago) AS tipo_pago,

        afluencia,

        (
            linea LIKE '%Ã%'
            OR estacion LIKE '%Ã%'
        ) AS es_texto_corregido

    FROM proyecto.metro_desglosada_typed
),

normalizado AS (
    SELECT
        fecha,
        anio,
        BTRIM(mes) AS mes,

        regexp_replace(
            BTRIM(linea_corregida),
            '^L[ií]nea\s*',
            'Línea ',
            'i'
        ) AS linea,

        BTRIM(estacion_corregida) AS estacion,

        tipo_pago,
        afluencia,
        es_texto_corregido

    FROM texto_corregido
),

cuartiles AS (
    SELECT
        percentile_cont(0.25)
            WITHIN GROUP (ORDER BY afluencia) AS q1,

        percentile_cont(0.75)
            WITHIN GROUP (ORDER BY afluencia) AS q3

    FROM normalizado
),

preparado AS (
    SELECT
        n.*,

        COUNT(*) OVER (
            PARTITION BY
                fecha,
                linea,
                estacion,
                tipo_pago
        ) AS cantidad_clave,

        c.q1,
        c.q3,
        c.q3 - c.q1 AS iqr

    FROM normalizado AS n
    CROSS JOIN cuartiles AS c
)

INSERT INTO proyecto.metro_desglosada_clean (
    fecha,
    anio,
    mes,
    mes_num,
    dia_semana_num,
    dia_semana,
    es_fin_semana,
    linea,
    estacion,
    tipo_pago,
    afluencia,
    es_afluencia_cero,
    es_colision_clave,
    es_outlier_iqr_global,
    es_texto_corregido
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

    linea,
    estacion,
    tipo_pago,
    afluencia,

    afluencia = 0,

    cantidad_clave > 1,

    (
        afluencia < q1 - 1.5 * iqr
        OR
        afluencia > q3 + 1.5 * iqr
    ),

    es_texto_corregido

FROM preparado;


-- =========================================================
-- 6. CONCILIACIÓN TYPED VS CLEAN
-- =========================================================

SELECT
    'Metro Simple' AS fuente,

    (SELECT COUNT(*)
     FROM proyecto.metro_simple_typed) AS typed,

    (SELECT COUNT(*)
     FROM proyecto.metro_simple_clean) AS clean,

    (
        (SELECT COUNT(*)
         FROM proyecto.metro_simple_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.metro_simple_typed)
    ) AS diferencia

UNION ALL

SELECT
    'Metro Desglosada',

    (SELECT COUNT(*)
     FROM proyecto.metro_desglosada_typed),

    (SELECT COUNT(*)
     FROM proyecto.metro_desglosada_clean),

    (
        (SELECT COUNT(*)
         FROM proyecto.metro_desglosada_clean)
        -
        (SELECT COUNT(*)
         FROM proyecto.metro_desglosada_typed)
    );


-- =========================================================
-- 7. VALIDAR ELIMINACIÓN DE MOJIBAKE EN CLEAN
-- =========================================================

SELECT
    'Metro Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE linea LIKE '%Ã%'
    ) AS linea_mojibake,

    COUNT(*) FILTER (
        WHERE estacion LIKE '%Ã%'
    ) AS estacion_mojibake

FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Metro Desglosada',

    COUNT(*) FILTER (
        WHERE linea LIKE '%Ã%'
    ),

    COUNT(*) FILTER (
        WHERE estacion LIKE '%Ã%'
    )

FROM proyecto.metro_desglosada_clean;


-- =========================================================
-- 8. REGISTROS DONDE SE CORRIGIÓ TEXTO
-- =========================================================

SELECT
    'Metro Simple' AS fuente,
    COUNT(*) FILTER (
        WHERE es_texto_corregido
    ) AS registros_corregidos
FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Metro Desglosada',
    COUNT(*) FILTER (
        WHERE es_texto_corregido
    )
FROM proyecto.metro_desglosada_clean;


-- =========================================================
-- 9. FLAGS DE CALIDAD
-- =========================================================

SELECT
    'Metro Simple' AS fuente,

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ) AS afluencias_cero,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS filas_con_colision,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS posibles_outliers

FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Metro Desglosada',

    COUNT(*) FILTER (
        WHERE es_afluencia_cero
    ),

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ),

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    )

FROM proyecto.metro_desglosada_clean;


-- =========================================================
-- 10. CATEGORÍAS DE LÍNEA DESPUÉS DE NORMALIZAR
-- =========================================================

SELECT DISTINCT
    linea
FROM proyecto.metro_simple_clean
ORDER BY linea;


SELECT DISTINCT
    linea
FROM proyecto.metro_desglosada_clean
ORDER BY linea;


-- =========================================================
-- 11. TIPO DE PAGO DESPUÉS DE LIMPIEZA
-- =========================================================

SELECT
    tipo_pago,
    COUNT(*) AS registros,
    SUM(afluencia) AS afluencia_total

FROM proyecto.metro_desglosada_clean

GROUP BY tipo_pago

ORDER BY tipo_pago;