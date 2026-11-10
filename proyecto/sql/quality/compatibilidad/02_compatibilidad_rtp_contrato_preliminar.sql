/*
=========================================================
CHECKPOINT DE COMPATIBILIDAD ANALÍTICA

RTP ↔ CONTRATO MULTISISTEMA PRELIMINAR

Proyecto:
Inteligencia de demanda de los principales sistemas
de transporte público de la Ciudad de México.

Objetivo de este diagnóstico:

1. determinar la ventana temporal estrictamente común
   entre Metro, Metrobús y RTP;

2. caracterizar RTP dentro de esa ventana;

3. evaluar si fecha × servicio puede producir una
   observación diaria de demanda de forma segura;

4. cuantificar el efecto de:
   - colisiones;
   - duplicados;
   - NULL;
   - tipo_pago;

5. NO asumir que servicio = linea.

REGLAS:
- Solo lectura.
- No modificar Metro.
- No modificar Metrobús.
- No modificar RTP.
- No CREATE TABLE.
- No INSERT.
- No UPDATE.
- No DELETE.
- No construir integración física.
=========================================================
*/

BEGIN TRANSACTION READ ONLY;


/* =====================================================
   1. VENTANA TEMPORAL ESTRICTAMENTE COMÚN

   Se consideran las capas CLEAN necesarias para el
   nivel diario preliminar de cada sistema.

   Metro:
   metro_simple_clean

   Metrobús:
   metrobus_simple_clean

   RTP:
   rtp_desglosada_clean
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
)

SELECT
    MAX(fecha_min) AS inicio_comun_estricto,
    MIN(fecha_max) AS fin_comun_estricto
FROM cobertura;


/* =====================================================
   2. RTP EN LA VENTANA COMÚN ESPERADA

   Según las coberturas ya validadas se espera:

   2022-01-01 → 2026-07-31

   La consulta no presupone compatibilidad de servicio
   con linea.
===================================================== */

SELECT
    COUNT(*) AS registros,

    COUNT(DISTINCT fecha)
        AS fechas_distintas,

    MIN(fecha) AS fecha_min,

    MAX(fecha) AS fecha_max,

    COUNT(DISTINCT servicio)
        AS servicios_distintos,

    COUNT(DISTINCT tipo_pago)
        AS tipos_pago_distintos,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ) AS afluencia_cero,

    COUNT(*) FILTER (
        WHERE es_colision_clave
    ) AS filas_con_colision,

    COUNT(*) FILTER (
        WHERE es_duplicado_exacto
    ) AS filas_duplicado_exacto,

    COUNT(*) FILTER (
        WHERE es_outlier_iqr_global
    ) AS outliers_origen

FROM proyecto.rtp_desglosada_clean

WHERE fecha BETWEEN DATE '2022-01-01'
                AND DATE '2026-07-31';


/* =====================================================
   3. ESTRUCTURA NATIVA fecha × servicio

   Para una combinación normal se esperan tres filas:

   Boleto
   Gratuidad
   Prepago

   IMPORTANTE:
   Esta consulta NO suma todavía la afluencia.
===================================================== */

WITH grupos AS (

    SELECT
        fecha,
        servicio,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(afluencia)
            AS valores_afluencia_disponibles,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        BOOL_OR(es_duplicado_exacto)
            AS contiene_duplicado_exacto

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio
)

SELECT
    filas,
    tipos_pago,
    COUNT(*) AS claves_fecha_servicio,

    COUNT(*) FILTER (
        WHERE contiene_colision
    ) AS claves_con_colision,

    COUNT(*) FILTER (
        WHERE contiene_duplicado_exacto
    ) AS claves_con_duplicado_exacto,

    COUNT(*) FILTER (
        WHERE valores_afluencia_disponibles < filas
    ) AS claves_con_alguna_afluencia_null

FROM grupos

GROUP BY
    filas,
    tipos_pago

ORDER BY
    filas,
    tipos_pago;


/* =====================================================
   4. CLASIFICACIÓN DE CLAVES fecha × servicio

   SEGURA ESTRUCTURALMENTE:
   - 3 filas;
   - 3 tipos de pago;
   - ninguna colisión.

   COMPLETA:
   - además, las tres medidas de afluencia están
     disponibles.

   NO se declara todavía que servicio sea equivalente
   a linea.
===================================================== */

WITH grupos AS (

    SELECT
        fecha,
        servicio,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(afluencia)
            AS valores_disponibles,

        BOOL_OR(es_colision_clave)
            AS contiene_colision

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio
)

SELECT
    COUNT(*) AS claves_fecha_servicio_totales,

    COUNT(*) FILTER (
        WHERE filas = 3
          AND tipos_pago = 3
          AND NOT contiene_colision
    ) AS claves_estructuralmente_seguras,

    COUNT(*) FILTER (
        WHERE contiene_colision
    ) AS claves_con_colision,

    COUNT(*) FILTER (
        WHERE valores_disponibles < filas
    ) AS claves_con_alguna_afluencia_null,

    COUNT(*) FILTER (
        WHERE filas = 3
          AND tipos_pago = 3
          AND NOT contiene_colision
          AND valores_disponibles = 3
    ) AS claves_seguras_y_completas

FROM grupos;


/* =====================================================
   5. CANDIDATO DE AFLUENCIA DIARIA POR SERVICIO

   ÚNICAMENTE se agregan claves previamente clasificadas
   como:

   - 3 filas;
   - 3 tipos de pago;
   - sin colisiones;
   - las tres afluencias disponibles.

   Esto evita resolver artificialmente ATENEA.

   La consulta es diagnóstica.
   NO materializa datos.
===================================================== */

WITH base AS (

    SELECT
        fecha,
        servicio,
        tipo_pago,
        afluencia,
        es_colision_clave

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'
),

clasificacion AS (

    SELECT
        fecha,
        servicio,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(afluencia)
            AS valores_disponibles,

        BOOL_OR(es_colision_clave)
            AS contiene_colision

    FROM base

    GROUP BY
        fecha,
        servicio
),

claves_seguras AS (

    SELECT
        fecha,
        servicio

    FROM clasificacion

    WHERE filas = 3
      AND tipos_pago = 3
      AND valores_disponibles = 3
      AND NOT contiene_colision
),

agregado_seguro AS (

    SELECT
        b.fecha,
        b.servicio,

        SUM(b.afluencia)::NUMERIC
            AS afluencia

    FROM base AS b

    INNER JOIN claves_seguras AS s
        ON b.fecha = s.fecha
       AND b.servicio = s.servicio

    GROUP BY
        b.fecha,
        b.servicio
)

SELECT
    COUNT(*) AS registros_candidato_seguro,

    COUNT(
        DISTINCT (fecha, servicio)
    ) AS claves_distintas,

    COUNT(DISTINCT fecha)
        AS fechas_distintas,

    COUNT(DISTINCT servicio)
        AS servicios_distintos,

    MIN(fecha) AS fecha_min,

    MAX(fecha) AS fecha_max,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null

FROM agregado_seguro;


/* =====================================================
   6. COBERTURA POR SERVICIO DEL CANDIDATO SEGURO

   Sirve para comprobar si todos los servicios poseen
   cobertura diaria comparable o si existen servicios
   temporales / parciales.
===================================================== */

WITH base AS (

    SELECT
        fecha,
        servicio,
        tipo_pago,
        afluencia,
        es_colision_clave

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'
),

clasificacion AS (

    SELECT
        fecha,
        servicio,

        COUNT(*) AS filas,
        COUNT(DISTINCT tipo_pago) AS tipos_pago,
        COUNT(afluencia) AS valores_disponibles,
        BOOL_OR(es_colision_clave) AS contiene_colision

    FROM base

    GROUP BY
        fecha,
        servicio
),

claves_seguras AS (

    SELECT
        fecha,
        servicio

    FROM clasificacion

    WHERE filas = 3
      AND tipos_pago = 3
      AND valores_disponibles = 3
      AND NOT contiene_colision
)

SELECT
    servicio,

    COUNT(*) AS dias_seguros,

    MIN(fecha) AS fecha_min,

    MAX(fecha) AS fecha_max

FROM claves_seguras

GROUP BY servicio
ORDER BY fecha_min, servicio;


COMMIT;

/*
=========================================================
7. AUDITORÍA DE CLAVES NO SEGURAS POR NULL

Objetivo:
determinar cómo se distribuyen las 131 claves
fecha × servicio que contienen al menos una afluencia
NULL dentro de la ventana común.

No modifica datos.
=========================================================
*/

BEGIN TRANSACTION READ ONLY;


/* =====================================================
   7.1 CLASIFICACIÓN EXHAUSTIVA DE CLAVES

   Comprueba si colisiones y NULL se superponen.
===================================================== */

WITH grupos AS (

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
            AS contiene_colision

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio
)

SELECT

    COUNT(*) AS claves_totales,

    COUNT(*) FILTER (
        WHERE filas = 3
          AND tipos_pago = 3
          AND componentes_null = 0
          AND NOT contiene_colision
    ) AS seguras_completas,

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
    ) AS colision_y_null

FROM grupos;


/* =====================================================
   7.2 CUÁNTOS COMPONENTES NULL TIENE CADA CLAVE

   Una clave fecha × servicio puede tener:

   1 de 3 componentes NULL
   2 de 3 componentes NULL
   3 de 3 componentes NULL
===================================================== */

WITH grupos AS (

    SELECT
        fecha,
        servicio,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio

    HAVING COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) > 0
)

SELECT
    componentes_null,

    COUNT(*) AS claves_fecha_servicio,

    SUM(componentes_null)
        AS filas_null

FROM grupos

GROUP BY componentes_null
ORDER BY componentes_null;


/* =====================================================
   7.3 NULL POR SERVICIO

   Permite determinar si los faltantes están
   concentrados en servicios concretos.
===================================================== */

WITH grupos AS (

    SELECT
        fecha,
        servicio,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio

    HAVING COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) > 0
)

SELECT
    servicio,

    COUNT(*) AS claves_con_null,

    SUM(componentes_null)
        AS componentes_null,

    MIN(fecha) AS primera_fecha,

    MAX(fecha) AS ultima_fecha

FROM grupos

GROUP BY servicio

ORDER BY
    claves_con_null DESC,
    servicio;


/* =====================================================
   7.4 NULL POR TIPO DE PAGO
===================================================== */

SELECT
    tipo_pago,

    COUNT(*) AS filas_null,

    COUNT(
        DISTINCT (fecha, servicio)
    ) AS claves_fecha_servicio_afectadas,

    MIN(fecha) AS primera_fecha,

    MAX(fecha) AS ultima_fecha

FROM proyecto.rtp_desglosada_clean

WHERE fecha BETWEEN DATE '2022-01-01'
                AND DATE '2026-07-31'

  AND afluencia IS NULL

GROUP BY tipo_pago

ORDER BY tipo_pago;


/* =====================================================
   7.5 COBERTURA TOTAL VS COBERTURA SEGURA POR SERVICIO

   Cuantifica exactamente cuántas claves de cada
   servicio quedan fuera del candidato seguro y por qué.
===================================================== */

WITH grupos AS (

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
            AS contiene_colision

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio
)

SELECT
    servicio,

    COUNT(*) AS claves_totales,

    COUNT(*) FILTER (
        WHERE filas = 3
          AND tipos_pago = 3
          AND componentes_null = 0
          AND NOT contiene_colision
    ) AS claves_seguras,

    COUNT(*) FILTER (
        WHERE componentes_null > 0
    ) AS excluidas_por_null,

    COUNT(*) FILTER (
        WHERE contiene_colision
    ) AS excluidas_por_colision,

    MIN(fecha) AS fecha_min,

    MAX(fecha) AS fecha_max

FROM grupos

GROUP BY servicio

ORDER BY
    fecha_min,
    servicio;


/* =====================================================
   7.6 EJEMPLOS DE CLAVES CON NULL

   Demuestra por qué SUM(afluencia) sin controles
   produciría totales parciales.
===================================================== */

WITH claves_null AS (

    SELECT
        fecha,
        servicio

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio

    HAVING COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) > 0
)

SELECT
    r.fecha,
    r.servicio,
    r.tipo_pago,
    r.afluencia,

    r.es_afluencia_no_disponible

FROM proyecto.rtp_desglosada_clean AS r

INNER JOIN claves_null AS k
    ON r.fecha = k.fecha
   AND r.servicio = k.servicio

ORDER BY
    r.fecha,
    r.servicio,
    r.tipo_pago

LIMIT 60;


COMMIT;









/*
=========================================================
8. EVALUACIÓN DEL CONTRATO MULTISISTEMA GENERALIZADO

Granularidad candidata:

fecha × sistema × unidad_operativa

Mapeo conceptual:

Metro:
unidad_operativa = linea

Metrobús:
unidad_operativa = linea

RTP:
unidad_operativa = servicio

IMPORTANTE:
- Diagnóstico únicamente.
- No materializa datos.
- No modifica ningún pipeline.
- RTP no calcula totales parciales.
=========================================================
*/

BEGIN TRANSACTION READ ONLY;


/* =====================================================
   8.1 CANDIDATO RTP CONSERVANDO TODAS LAS CLAVES

   Solo se calcula afluencia cuando:

   - existen 3 filas;
   - existen 3 tipos de pago;
   - no hay NULL;
   - no hay colisión.

   En cualquier otro caso:
   afluencia = NULL
   y se conserva la causa.
===================================================== */

WITH grupos AS (

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

candidato AS (

    SELECT
        fecha,

        servicio
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

    FROM grupos
)

SELECT
    COUNT(*) AS registros,

    COUNT(
        DISTINCT (fecha, unidad_operativa)
    ) AS claves_distintas,

    COUNT(*) FILTER (
        WHERE estado_calidad = 'OK'
    ) AS claves_ok,

    COUNT(*) FILTER (
        WHERE estado_calidad = 'COLISION'
    ) AS claves_colision,

    COUNT(*) FILTER (
        WHERE estado_calidad = 'AFLUENCIA_INCOMPLETA'
    ) AS claves_incompletas,

    COUNT(*) FILTER (
        WHERE estado_calidad = 'COLISION_Y_NULL'
    ) AS claves_colision_y_null,

    COUNT(*) FILTER (
        WHERE estado_calidad = 'ESTRUCTURA_INESPERADA'
    ) AS estructura_inesperada,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null

FROM candidato;


/* =====================================================
   8.2 DISTRIBUCIÓN DE ESTADOS RTP
===================================================== */

WITH grupos AS (

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
            AS contiene_colision

    FROM proyecto.rtp_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY
        fecha,
        servicio
),

clasificado AS (

    SELECT

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
    estado_calidad,
    COUNT(*) AS claves

FROM clasificado

GROUP BY estado_calidad
ORDER BY estado_calidad;


/* =====================================================
   8.3 CONSTRUCCIÓN CONCEPTUAL DE LOS TRES SISTEMAS

   NO CREA TABLA.

   Ventana común:
   2022-01-01 → 2026-07-31
===================================================== */

WITH metro AS (

    SELECT
        'Metro'::TEXT AS sistema,

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

metrobus AS (

    SELECT
        'Metrobús'::TEXT AS sistema,

        fecha,

        linea::TEXT
            AS unidad_operativa,

        afluencia::NUMERIC
            AS afluencia,

        CASE
            WHEN afluencia IS NULL
                THEN 'AFLUENCIA_INCOMPLETA'
            ELSE 'OK'
        END AS estado_calidad

    FROM proyecto.metrobus_simple_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'
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

multisistema AS (

    SELECT *
    FROM metro

    UNION ALL

    SELECT *
    FROM metrobus

    UNION ALL

    SELECT *
    FROM rtp
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

    MIN(fecha) AS fecha_min,

    MAX(fecha) AS fecha_max,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE estado_calidad <> 'OK'
    ) AS claves_con_restriccion

FROM multisistema

GROUP BY sistema
ORDER BY sistema;


/* =====================================================
   8.4 VALIDACIÓN GLOBAL DE LA CLAVE

   Clave propuesta:

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

        CASE
            WHEN afluencia IS NULL
                THEN 'AFLUENCIA_INCOMPLETA'
            ELSE 'OK'
        END AS estado_calidad

    FROM proyecto.metrobus_simple_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'
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

multisistema AS (

    SELECT *
    FROM metro

    UNION ALL

    SELECT *
    FROM metrobus

    UNION ALL

    SELECT *
    FROM rtp
),

duplicados AS (

    SELECT
        sistema,
        fecha,
        unidad_operativa,
        COUNT(*) AS veces

    FROM multisistema

    GROUP BY
        sistema,
        fecha,
        unidad_operativa

    HAVING COUNT(*) > 1
)

SELECT

    (SELECT COUNT(*)
     FROM multisistema)
        AS registros_totales,

    (
        SELECT COUNT(
            DISTINCT (
                sistema,
                fecha,
                unidad_operativa
            )
        )
        FROM multisistema
    ) AS claves_distintas,

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
        AS afluencia_null,

    (SELECT COUNT(*)
     FROM multisistema
     WHERE estado_calidad <> 'OK')
        AS claves_con_restriccion;


COMMIT;