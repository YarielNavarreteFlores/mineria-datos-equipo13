/*
=========================================================
CHECKPOINT DE COMPATIBILIDAD ANALÍTICA

TROLEBÚS ↔ CONTRATO MULTISISTEMA VIGENTE

Proyecto:
Inteligencia de demanda de los principales sistemas
de transporte público de la Ciudad de México.

Contrato vigente:

fecha × sistema × unidad_operativa

Mapeo vigente:

Metro:
unidad_operativa = linea

Metrobús:
unidad_operativa = linea

RTP:
unidad_operativa = servicio

Cablebús:
unidad_operativa = linea

Hipótesis Trolebús:

unidad_operativa = linea

OBJETIVOS:

1. determinar la ventana temporal estrictamente común
   entre los cinco sistemas;

2. caracterizar Trolebús dentro de esa ventana;

3. comprobar que fecha × linea puede producir una
   observación diaria de demanda agregando tipo_pago;

4. comprobar que la agregación no pierde información
   ni introduce ambigüedad;

5. evaluar Trolebús dentro del contrato:

   fecha × sistema × unidad_operativa;

6. evaluar nuevamente la unicidad global del candidato
   multisistema de cinco sistemas.

REGLAS:

- Solo lectura.
- No modificar Metro.
- No modificar Metrobús.
- No modificar RTP.
- No modificar Cablebús.
- No modificar Trolebús.
- No CREATE TABLE.
- No INSERT.
- No UPDATE.
- No DELETE.
- No integración física.
=========================================================
*/


BEGIN TRANSACTION READ ONLY;


/* =====================================================
   1. VENTANA TEMPORAL ESTRICTAMENTE COMÚN
===================================================== */

WITH cobertura AS (

    SELECT
        'Metro'::TEXT AS sistema,
        MIN(fecha) AS fecha_min,
        MAX(fecha) AS fecha_max
    FROM proyecto.metro_simple_clean

    UNION ALL

    SELECT
        'Metrobús',
        MIN(fecha),
        MAX(fecha)
    FROM proyecto.metrobus_simple_clean

    UNION ALL

    SELECT
        'RTP',
        MIN(fecha),
        MAX(fecha)
    FROM proyecto.rtp_desglosada_clean

    UNION ALL

    SELECT
        'Cablebús',
        MIN(fecha),
        MAX(fecha)
    FROM proyecto.cablebus_desglosada_clean

    UNION ALL

    SELECT
        'Trolebús',
        MIN(fecha),
        MAX(fecha)
    FROM proyecto.trolebus_desglosada_clean
)

SELECT
    MAX(fecha_min) AS inicio_comun_estricto,
    MIN(fecha_max) AS fin_comun_estricto
FROM cobertura;


/* =====================================================
   2. TROLEBÚS DENTRO DE LA VENTANA COMÚN

   Ventana esperada:

   2022-01-01 → 2026-07-31
===================================================== */

SELECT
    COUNT(*) AS registros,

    COUNT(DISTINCT fecha)
        AS fechas_distintas,

    MIN(fecha)
        AS fecha_min,

    MAX(fecha)
        AS fecha_max,

    COUNT(DISTINCT linea)
        AS lineas_distintas,

    COUNT(DISTINCT tipo_pago)
        AS tipos_pago_distintos,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ) AS afluencia_cero,

    COUNT(*) FILTER (
        WHERE afluencia
              <> TRUNC(afluencia)
    ) AS afluencia_decimal,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS filas_con_colision,

    COUNT(*) FILTER (
        WHERE es_duplicado_exacto
    ) AS filas_duplicado_exacto,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS outliers_origen

FROM proyecto.trolebus_desglosada_clean

WHERE fecha BETWEEN DATE '2022-01-01'
                AND DATE '2026-07-31';


/* =====================================================
   3. ESTRUCTURA NATIVA fecha × linea

   Trolebús debe presentar:

   3 filas
   3 tipos de pago:

   Boleto
   Gratuidad
   Prepago
===================================================== */

WITH grupos AS (

    SELECT
        fecha,
        linea,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(afluencia)
            AS valores_disponibles,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        BOOL_OR(es_duplicado_exacto)
            AS contiene_duplicado

    FROM proyecto.trolebus_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
)

SELECT
    filas,
    tipos_pago,

    COUNT(*) AS claves_fecha_linea,

    COUNT(*) FILTER (
        WHERE contiene_colision
    ) AS claves_con_colision,

    COUNT(*) FILTER (
        WHERE contiene_duplicado
    ) AS claves_con_duplicado,

    COUNT(*) FILTER (
        WHERE valores_disponibles < filas
    ) AS claves_con_afluencia_incompleta

FROM grupos

GROUP BY
    filas,
    tipos_pago

ORDER BY
    filas,
    tipos_pago;


/* =====================================================
   4. CLASIFICACIÓN EXHAUSTIVA DE CLAVES TROLEBÚS

   Una clave segura requiere:

   - 3 filas;
   - 3 tipos_pago;
   - 0 NULL;
   - 0 colisiones.
===================================================== */

WITH grupos AS (

    SELECT
        fecha,
        linea,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision

    FROM proyecto.trolebus_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
)

SELECT
    COUNT(*) AS claves_totales,

    COUNT(*) FILTER (
        WHERE filas = 3
          AND tipos_pago = 3
          AND componentes_null = 0
          AND NOT contiene_colision
    ) AS claves_ok,

    COUNT(*) FILTER (
        WHERE contiene_colision
          AND componentes_null = 0
    ) AS solo_colision,

    COUNT(*) FILTER (
        WHERE NOT contiene_colision
          AND componentes_null > 0
    ) AS solo_null,

    COUNT(*) FILTER (
        WHERE contiene_colision
          AND componentes_null > 0
    ) AS colision_y_null,

    COUNT(*) FILTER (
        WHERE filas <> 3
           OR tipos_pago <> 3
    ) AS estructura_inesperada

FROM grupos;


/* =====================================================
   5. CANDIDATO DIARIO TROLEBÚS

   Solo se obtiene afluencia cuando:

   - existen 3 filas;
   - existen 3 tipos_pago;
   - no existen NULL;
   - no existen colisiones.

   No se redondean valores decimales.
===================================================== */

WITH grupos AS (

    SELECT
        fecha,
        linea,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        SUM(afluencia)::NUMERIC
            AS suma_afluencia

    FROM proyecto.trolebus_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
),

candidato AS (

    SELECT
        fecha,

        linea AS unidad_operativa,

        CASE
            WHEN filas = 3
             AND tipos_pago = 3
             AND componentes_null = 0
             AND NOT contiene_colision

            THEN suma_afluencia

            ELSE NULL

        END AS afluencia,

        CASE

            WHEN contiene_colision
             AND componentes_null > 0
                THEN 'COLISION_Y_NULL'

            WHEN contiene_colision
                THEN 'COLISION'

            WHEN componentes_null > 0
                THEN 'AFLUENCIA_INCOMPLETA'

            WHEN filas <> 3
              OR tipos_pago <> 3
                THEN 'ESTRUCTURA_INESPERADA'

            ELSE 'OK'

        END AS estado_calidad

    FROM grupos
)

SELECT
    COUNT(*) AS registros,

    COUNT(
        DISTINCT (fecha, unidad_operativa)
    ) AS claves_distintas,

    COUNT(DISTINCT fecha)
        AS fechas_distintas,

    COUNT(DISTINCT unidad_operativa)
        AS unidades_operativas,

    MIN(fecha)
        AS fecha_min,

    MAX(fecha)
        AS fecha_max,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE estado_calidad <> 'OK'
    ) AS claves_con_restriccion

FROM candidato;


/* =====================================================
   6. COBERTURA POR UNIDAD OPERATIVA TROLEBÚS
===================================================== */

WITH grupos AS (

    SELECT
        fecha,
        linea,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision

    FROM proyecto.trolebus_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
)

SELECT
    linea AS unidad_operativa,

    COUNT(*) AS claves_totales,

    COUNT(*) FILTER (
        WHERE filas = 3
          AND tipos_pago = 3
          AND componentes_null = 0
          AND NOT contiene_colision
    ) AS claves_seguras,

    MIN(fecha)
        AS fecha_min,

    MAX(fecha)
        AS fecha_max

FROM grupos

GROUP BY linea

ORDER BY linea;


/* =====================================================
   7. VALIDACIÓN DE UNICIDAD DEL CANDIDATO TROLEBÚS
===================================================== */

WITH candidato AS (

    SELECT
        fecha,
        linea AS unidad_operativa,

        SUM(afluencia)::NUMERIC
            AS afluencia

    FROM proyecto.trolebus_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
)

SELECT
    COUNT(*) AS registros_totales,

    COUNT(
        DISTINCT (fecha, unidad_operativa)
    ) AS claves_distintas,

    COUNT(*) -
    COUNT(
        DISTINCT (fecha, unidad_operativa)
    ) AS claves_duplicadas

FROM candidato;


COMMIT;


/*
=========================================================
8. EVALUACIÓN MULTISISTEMA DE CINCO SISTEMAS

Contrato:

fecha × sistema × unidad_operativa

No materializa información.
=========================================================
*/


BEGIN TRANSACTION READ ONLY;


/* =====================================================
   8.1 METRO
===================================================== */

WITH metro AS (

    SELECT
        'Metro'::TEXT
            AS sistema,

        fecha,

        linea::TEXT
            AS unidad_operativa,

        SUM(afluencia)::NUMERIC
            AS afluencia,

        'OK'::TEXT
            AS estado_calidad

    FROM proyecto.metro_simple_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
),


/* =====================================================
   8.2 METROBÚS
===================================================== */

metrobus AS (

    SELECT
        'Metrobús'::TEXT
            AS sistema,

        fecha,

        linea::TEXT
            AS unidad_operativa,

        afluencia::NUMERIC
            AS afluencia,

        'OK'::TEXT
            AS estado_calidad

    FROM proyecto.metrobus_simple_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

      AND afluencia IS NOT NULL
),


/* =====================================================
   8.3 RTP
===================================================== */

rtp_grupos AS (

    SELECT
        fecha,
        servicio,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        SUM(afluencia)::NUMERIC
            AS suma_disponible

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio
),

rtp AS (

    SELECT
        'RTP'::TEXT
            AS sistema,

        fecha,

        servicio::TEXT
            AS unidad_operativa,

        CASE
            WHEN filas = 3
             AND tipos_pago = 3
             AND componentes_null = 0
             AND NOT contiene_colision

            THEN suma_disponible

            ELSE NULL
        END AS afluencia,

        CASE

            WHEN contiene_colision
             AND componentes_null > 0
                THEN 'COLISION_Y_NULL'

            WHEN contiene_colision
                THEN 'COLISION'

            WHEN componentes_null > 0
                THEN 'AFLUENCIA_INCOMPLETA'

            WHEN filas <> 3
              OR tipos_pago <> 3
                THEN 'ESTRUCTURA_INESPERADA'

            ELSE 'OK'

        END AS estado_calidad

    FROM rtp_grupos
),


/* =====================================================
   8.4 CABLEBÚS
===================================================== */

cablebus_grupos AS (

    SELECT
        fecha,
        linea,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        SUM(afluencia)::NUMERIC
            AS suma_afluencia

    FROM proyecto.cablebus_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
),

cablebus AS (

    SELECT
        'Cablebús'::TEXT
            AS sistema,

        fecha,

        linea::TEXT
            AS unidad_operativa,

        CASE
            WHEN filas = 2
             AND tipos_pago = 2
             AND componentes_null = 0
             AND NOT contiene_colision

            THEN suma_afluencia

            ELSE NULL
        END AS afluencia,

        CASE

            WHEN contiene_colision
             AND componentes_null > 0
                THEN 'COLISION_Y_NULL'

            WHEN contiene_colision
                THEN 'COLISION'

            WHEN componentes_null > 0
                THEN 'AFLUENCIA_INCOMPLETA'

            WHEN filas <> 2
              OR tipos_pago <> 2
                THEN 'ESTRUCTURA_INESPERADA'

            ELSE 'OK'

        END AS estado_calidad

    FROM cablebus_grupos
),


/* =====================================================
   8.5 TROLEBÚS
===================================================== */

trolebus_grupos AS (

    SELECT
        fecha,
        linea,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        SUM(afluencia)::NUMERIC
            AS suma_afluencia

    FROM proyecto.trolebus_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
),

trolebus AS (

    SELECT
        'Trolebús'::TEXT
            AS sistema,

        fecha,

        linea::TEXT
            AS unidad_operativa,

        CASE
            WHEN filas = 3
             AND tipos_pago = 3
             AND componentes_null = 0
             AND NOT contiene_colision

            THEN suma_afluencia

            ELSE NULL
        END AS afluencia,

        CASE

            WHEN contiene_colision
             AND componentes_null > 0
                THEN 'COLISION_Y_NULL'

            WHEN contiene_colision
                THEN 'COLISION'

            WHEN componentes_null > 0
                THEN 'AFLUENCIA_INCOMPLETA'

            WHEN filas <> 3
              OR tipos_pago <> 3
                THEN 'ESTRUCTURA_INESPERADA'

            ELSE 'OK'

        END AS estado_calidad

    FROM trolebus_grupos
),

combinado AS (

    SELECT * FROM metro

    UNION ALL

    SELECT * FROM metrobus

    UNION ALL

    SELECT * FROM rtp

    UNION ALL

    SELECT * FROM cablebus

    UNION ALL

    SELECT * FROM trolebus
)

SELECT
    sistema,

    COUNT(*) AS registros,

    COUNT(
        DISTINCT (fecha, unidad_operativa)
    ) AS claves_distintas,

    COUNT(DISTINCT fecha)
        AS fechas_distintas,

    COUNT(DISTINCT unidad_operativa)
        AS unidades_operativas,

    MIN(fecha)
        AS fecha_min,

    MAX(fecha)
        AS fecha_max,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE estado_calidad <> 'OK'
    ) AS claves_con_restriccion

FROM combinado

GROUP BY sistema

ORDER BY sistema;


/* =====================================================
   9. VALIDACIÓN GLOBAL DE LA CLAVE

   fecha × sistema × unidad_operativa
===================================================== */

WITH metro AS (

    SELECT
        'Metro'::TEXT AS sistema,
        fecha,
        linea::TEXT AS unidad_operativa,
        SUM(afluencia)::NUMERIC AS afluencia,
        'OK'::TEXT AS estado_calidad

    FROM proyecto.metro_simple_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
),

metrobus AS (

    SELECT
        'Metrobús'::TEXT AS sistema,
        fecha,
        linea::TEXT AS unidad_operativa,
        afluencia::NUMERIC AS afluencia,
        'OK'::TEXT AS estado_calidad

    FROM proyecto.metrobus_simple_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

      AND afluencia IS NOT NULL
),

rtp_grupos AS (

    SELECT
        fecha,
        servicio,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        SUM(afluencia)::NUMERIC
            AS suma_disponible

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio
),

rtp AS (

    SELECT
        'RTP'::TEXT AS sistema,

        fecha,

        servicio::TEXT
            AS unidad_operativa,

        CASE
            WHEN filas = 3
             AND tipos_pago = 3
             AND componentes_null = 0
             AND NOT contiene_colision

            THEN suma_disponible

            ELSE NULL
        END AS afluencia,

        CASE
            WHEN contiene_colision
             AND componentes_null > 0
                THEN 'COLISION_Y_NULL'

            WHEN contiene_colision
                THEN 'COLISION'

            WHEN componentes_null > 0
                THEN 'AFLUENCIA_INCOMPLETA'

            WHEN filas <> 3
              OR tipos_pago <> 3
                THEN 'ESTRUCTURA_INESPERADA'

            ELSE 'OK'
        END AS estado_calidad

    FROM rtp_grupos
),

cablebus_grupos AS (

    SELECT
        fecha,
        linea,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        SUM(afluencia)::NUMERIC
            AS suma_afluencia

    FROM proyecto.cablebus_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
),

cablebus AS (

    SELECT
        'Cablebús'::TEXT AS sistema,

        fecha,

        linea::TEXT
            AS unidad_operativa,

        CASE
            WHEN filas = 2
             AND tipos_pago = 2
             AND componentes_null = 0
             AND NOT contiene_colision

            THEN suma_afluencia

            ELSE NULL
        END AS afluencia,

        CASE
            WHEN contiene_colision
             AND componentes_null > 0
                THEN 'COLISION_Y_NULL'

            WHEN contiene_colision
                THEN 'COLISION'

            WHEN componentes_null > 0
                THEN 'AFLUENCIA_INCOMPLETA'

            WHEN filas <> 2
              OR tipos_pago <> 2
                THEN 'ESTRUCTURA_INESPERADA'

            ELSE 'OK'
        END AS estado_calidad

    FROM cablebus_grupos
),

trolebus_grupos AS (

    SELECT
        fecha,
        linea,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        SUM(afluencia)::NUMERIC
            AS suma_afluencia

    FROM proyecto.trolebus_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        linea
),

trolebus AS (

    SELECT
        'Trolebús'::TEXT AS sistema,

        fecha,

        linea::TEXT
            AS unidad_operativa,

        CASE
            WHEN filas = 3
             AND tipos_pago = 3
             AND componentes_null = 0
             AND NOT contiene_colision

            THEN suma_afluencia

            ELSE NULL
        END AS afluencia,

        CASE
            WHEN contiene_colision
             AND componentes_null > 0
                THEN 'COLISION_Y_NULL'

            WHEN contiene_colision
                THEN 'COLISION'

            WHEN componentes_null > 0
                THEN 'AFLUENCIA_INCOMPLETA'

            WHEN filas <> 3
              OR tipos_pago <> 3
                THEN 'ESTRUCTURA_INESPERADA'

            ELSE 'OK'
        END AS estado_calidad

    FROM trolebus_grupos
),

combinado AS (

    SELECT * FROM metro

    UNION ALL

    SELECT * FROM metrobus

    UNION ALL

    SELECT * FROM rtp

    UNION ALL

    SELECT * FROM cablebus

    UNION ALL

    SELECT * FROM trolebus
)

SELECT
    COUNT(*) AS registros_totales,

    COUNT(
        DISTINCT (
            fecha,
            sistema,
            unidad_operativa
        )
    ) AS claves_distintas,

    COUNT(*) -
    COUNT(
        DISTINCT (
            fecha,
            sistema,
            unidad_operativa
        )
    ) AS claves_duplicadas,

    COUNT(DISTINCT fecha)
        AS fechas_distintas,

    MIN(fecha)
        AS fecha_min,

    MAX(fecha)
        AS fecha_max,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE estado_calidad <> 'OK'
    ) AS claves_con_restriccion

FROM combinado;


COMMIT;