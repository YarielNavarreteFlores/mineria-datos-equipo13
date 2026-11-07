/*
=========================================================
CHECKPOINT DE COMPATIBILIDAD ANALÍTICA
Metro ↔ Metrobús

Proyecto:
Inteligencia de demanda de los principales sistemas
de transporte público de la Ciudad de México.

Objetivo:
Comparar Metro y Metrobús antes de construir cualquier
integración física o modelo dimensional.

REGLAS:
- Solo lectura.
- No modificar RAW.
- No modificar Metro.
- No modificar Metrobús.
- No CREATE TABLE.
- No INSERT.
- No UPDATE.
- No DELETE.
=========================================================
*/

BEGIN TRANSACTION READ ONLY;


/* =====================================================
   1. COBERTURA GENERAL
===================================================== */

SELECT
    'Metro Simple' AS recurso,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max,
    COUNT(*) AS registros,
    COUNT(DISTINCT fecha) AS fechas,
    COUNT(DISTINCT linea) AS lineas,
    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null

FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Metro Desglosada',
    MIN(fecha),
    MAX(fecha),
    COUNT(*),
    COUNT(DISTINCT fecha),
    COUNT(DISTINCT linea),
    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    )

FROM proyecto.metro_desglosada_clean

UNION ALL

SELECT
    'Metrobús Simple',
    MIN(fecha),
    MAX(fecha),
    COUNT(*),
    COUNT(DISTINCT fecha),
    COUNT(DISTINCT linea),
    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    )

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Metrobús Desglosada',
    MIN(fecha),
    MAX(fecha),
    COUNT(*),
    COUNT(DISTINCT fecha),
    COUNT(DISTINCT linea),
    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    )

FROM proyecto.metrobus_desglosada_clean;


/* =====================================================
   2. DOMINIOS DE LÍNEA
===================================================== */

SELECT
    'Metro' AS sistema,
    linea

FROM proyecto.metro_simple_clean

GROUP BY linea

UNION ALL

SELECT
    'Metrobús',
    linea

FROM proyecto.metrobus_simple_clean

GROUP BY linea

ORDER BY sistema, linea;


/* =====================================================
   3. ETIQUETAS DE LÍNEA COINCIDENTES

   IMPORTANTE:
   Una coincidencia textual no significa que las líneas
   representen la misma entidad operativa.
===================================================== */

SELECT linea

FROM proyecto.metro_simple_clean

INTERSECT

SELECT linea

FROM proyecto.metrobus_simple_clean

ORDER BY linea;


/* =====================================================
   4. DOMINIOS DE TIPO DE PAGO
===================================================== */

SELECT
    'Metro' AS sistema,
    tipo_pago,
    COUNT(*) AS registros

FROM proyecto.metro_desglosada_clean

GROUP BY tipo_pago

UNION ALL

SELECT
    'Metrobús',
    tipo_pago,
    COUNT(*)

FROM proyecto.metrobus_desglosada_clean

GROUP BY tipo_pago

ORDER BY sistema, tipo_pago;


/* =====================================================
   5. CALIDAD DE LA MEDIDA
===================================================== */

SELECT
    'Metro Simple' AS recurso,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS nulos,

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ) AS ceros,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS outliers,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS colisiones

FROM proyecto.metro_simple_clean

UNION ALL

SELECT
    'Metro Desglosada',

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ),

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ),

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ),

    COUNT(*) FILTER (
        WHERE es_colision_clave
    )

FROM proyecto.metro_desglosada_clean

UNION ALL

SELECT
    'Metrobús Simple',

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ),

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ),

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ),

    COUNT(*) FILTER (
        WHERE es_colision_clave
    )

FROM proyecto.metrobus_simple_clean

UNION ALL

SELECT
    'Metrobús Desglosada',

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ),

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ),

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ),

    COUNT(*) FILTER (
        WHERE es_colision_clave
    )

FROM proyecto.metrobus_desglosada_clean;

COMMIT;

/* =====================================================
   6. RECONCILIACIÓN INTERNA DE METRO

   Objetivo:
   comprobar si Metro Simple coincide con la suma de
   Metro Desglosada sobre tipo_pago.

   Nivel de comparación:
   fecha × linea × estacion

   Periodo común:
   2021-01-01 → 2026-07-31

   IMPORTANTE:
   Las colisiones conocidas de Metro Simple pertenecen
   a diciembre de 2020, por lo que quedan fuera de esta
   ventana de comparación.
===================================================== */

BEGIN TRANSACTION READ ONLY;


WITH simple AS (

    SELECT
        fecha,
        linea,
        estacion,

        SUM(afluencia)::NUMERIC AS afluencia_simple

    FROM proyecto.metro_simple_clean

    WHERE fecha BETWEEN DATE '2021-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea,
        estacion
),

desglosada AS (

    SELECT
        fecha,
        linea,
        estacion,

        SUM(afluencia)::NUMERIC AS afluencia_desglosada

    FROM proyecto.metro_desglosada_clean

    WHERE fecha BETWEEN DATE '2021-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea,
        estacion
),

comparacion AS (

    SELECT

        COALESCE(
            s.fecha,
            d.fecha
        ) AS fecha,

        COALESCE(
            s.linea,
            d.linea
        ) AS linea,

        COALESCE(
            s.estacion,
            d.estacion
        ) AS estacion,

        s.afluencia_simple,

        d.afluencia_desglosada,

        s.afluencia_simple
        - d.afluencia_desglosada
            AS diferencia,

        s.fecha IS NOT NULL
            AS existe_simple,

        d.fecha IS NOT NULL
            AS existe_desglosada

    FROM simple AS s

    FULL OUTER JOIN desglosada AS d

        ON  s.fecha = d.fecha
        AND s.linea = d.linea
        AND s.estacion = d.estacion
)

SELECT

    COUNT(*) AS claves_union,

    COUNT(*) FILTER (
        WHERE existe_simple
          AND existe_desglosada
    ) AS claves_comparables,

    COUNT(*) FILTER (
        WHERE existe_simple
          AND NOT existe_desglosada
    ) AS solo_simple,

    COUNT(*) FILTER (
        WHERE NOT existe_simple
          AND existe_desglosada
    ) AS solo_desglosada,

    COUNT(*) FILTER (
        WHERE existe_simple
          AND existe_desglosada
          AND diferencia = 0
    ) AS coincidencias_exactas,

    COUNT(*) FILTER (
        WHERE existe_simple
          AND existe_desglosada
          AND diferencia <> 0
    ) AS diferencias,

    MAX(
        ABS(diferencia)
    ) FILTER (
        WHERE diferencia IS NOT NULL
    ) AS maxima_diferencia

FROM comparacion;


COMMIT;

/* =====================================================
   7. GRANULARIDAD CANDIDATA MULTISISTEMA

   Objetivo:
   evaluar si ambos sistemas pueden representarse
   analíticamente al nivel:

   fecha × sistema × linea

   Ventana estricta común:
   2021-01-01 → 2026-07-31

   IMPORTANTE:
   - No se crea ninguna tabla.
   - Metro se agrega desde estación hacia línea.
   - Metrobús ya se encuentra a nivel fecha × linea.
   - "Línea 1" de Metro y "Línea 1" de Metrobús
     NO representan la misma entidad.
===================================================== */

BEGIN TRANSACTION READ ONLY;


WITH metro_linea_dia AS (

    SELECT
        fecha,
        linea,

        SUM(afluencia)::NUMERIC
            AS afluencia,

        BOOL_OR(es_colision_clave)
            AS contiene_colision_origen

    FROM proyecto.metro_simple_clean

    WHERE fecha BETWEEN DATE '2021-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
),

metrobus_linea_dia AS (

    SELECT
        fecha,
        linea,
        afluencia,

        es_colision_clave
            AS contiene_colision_origen

    FROM proyecto.metrobus_simple_clean

    WHERE fecha BETWEEN DATE '2021-01-01'
                    AND DATE '2026-07-31'
),

candidato AS (

    SELECT
        'Metro'::TEXT
            AS sistema,

        fecha,
        linea,
        afluencia,
        contiene_colision_origen

    FROM metro_linea_dia

    UNION ALL

    SELECT
        'Metrobús'::TEXT,

        fecha,
        linea,
        afluencia,
        contiene_colision_origen

    FROM metrobus_linea_dia
)

SELECT
    sistema,

    COUNT(*) AS registros,

    COUNT(
        DISTINCT (fecha, linea)
    ) AS claves_fecha_linea,

    MIN(fecha) AS fecha_min,

    MAX(fecha) AS fecha_max,

    COUNT(DISTINCT linea)
        AS lineas,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ) AS afluencia_cero,

    COUNT(*) FILTER (
        WHERE contiene_colision_origen
    ) AS claves_con_colision_origen

FROM candidato

GROUP BY sistema

ORDER BY sistema;


COMMIT;


/* =====================================================
   8. VALIDACIÓN DE CLAVE MULTISISTEMA PRELIMINAR

   Clave candidata:
   fecha × sistema × linea

   Objetivo:
   comprobar unicidad y cobertura diaria completa
   dentro de la ventana común estricta.

   NO CREA TABLAS.
===================================================== */

BEGIN TRANSACTION READ ONLY;


WITH metro AS (

    SELECT
        'Metro'::TEXT AS sistema,
        fecha,
        linea,
        SUM(afluencia)::NUMERIC AS afluencia

    FROM proyecto.metro_simple_clean

    WHERE fecha BETWEEN DATE '2021-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
),

metrobus AS (

    SELECT
        'Metrobús'::TEXT AS sistema,
        fecha,
        linea,
        afluencia

    FROM proyecto.metrobus_simple_clean

    WHERE fecha BETWEEN DATE '2021-01-01'
                    AND DATE '2026-07-31'
),

multisistema AS (

    SELECT *
    FROM metro

    UNION ALL

    SELECT *
    FROM metrobus
),

duplicados AS (

    SELECT
        sistema,
        fecha,
        linea,
        COUNT(*) AS veces

    FROM multisistema

    GROUP BY
        sistema,
        fecha,
        linea

    HAVING COUNT(*) > 1
)

SELECT
    (SELECT COUNT(*)
     FROM multisistema)
        AS registros_totales,

    (SELECT COUNT(
        DISTINCT (sistema, fecha, linea)
     )
     FROM multisistema)
        AS claves_distintas,

    (SELECT COUNT(*)
     FROM duplicados)
        AS claves_duplicadas,

    (SELECT COUNT(DISTINCT fecha)
     FROM multisistema)
        AS fechas_distintas,

    (SELECT MIN(fecha)
     FROM multisistema)
        AS fecha_min,

    (SELECT MAX(fecha)
     FROM multisistema)
        AS fecha_max,

    (SELECT COUNT(*)
     FROM multisistema
     WHERE afluencia IS NULL)
        AS afluencia_null;


COMMIT;