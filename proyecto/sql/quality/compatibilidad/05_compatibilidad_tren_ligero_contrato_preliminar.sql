/*
=========================================================
CHECKPOINT DE COMPATIBILIDAD ANALÍTICA

TREN LIGERO ↔ CONTRATO MULTISISTEMA VIGENTE

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

Trolebús:
unidad_operativa = linea

Hipótesis Tren Ligero:

La fuente NO contiene linea ni otra dimensión física
equivalente a unidad_operativa.

Se evaluará exclusivamente para la capa de integración:

unidad_operativa = 'Sistema completo'

IMPORTANTE:

'Sistema completo' es una dimensión DERIVADA de
integración.

NO es una columna publicada por la fuente.

OBJETIVOS:

1. determinar la ventana temporal estrictamente común
   entre los seis sistemas;

2. caracterizar Tren Ligero dentro de dicha ventana;

3. comprobar la estructura nativa:

   fecha × tipo_pago;

4. demostrar que cada fecha puede producir una única
   observación diaria mediante SUM(afluencia);

5. comprobar que la agregación preserva exactamente
   la afluencia;

6. evaluar si una unidad_operativa constante puede
   utilizarse como abstracción analítica;

7. comprobar la unicidad de:

   fecha × sistema × unidad_operativa;

8. evaluar nuevamente el candidato multisistema
   incorporando los seis sistemas.

REGLAS:

- Solo lectura.
- No modificar Metro.
- No modificar Metrobús.
- No modificar RTP.
- No modificar Cablebús.
- No modificar Trolebús.
- No modificar Tren Ligero.
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

    UNION ALL

    SELECT
        'Tren Ligero',
        MIN(fecha),
        MAX(fecha)
    FROM proyecto.tren_ligero_desglosada_clean
)

SELECT
    MAX(fecha_min) AS inicio_comun_estricto,
    MIN(fecha_max) AS fin_comun_estricto
FROM cobertura;


/* =====================================================
   2. TREN LIGERO DENTRO DE LA VENTANA COMÚN

   Ventana esperada:

   2022-01-01 → 2026-07-31

   1,673 días.
===================================================== */

SELECT
    COUNT(*) AS registros,

    COUNT(DISTINCT fecha)
        AS fechas_distintas,

    MIN(fecha)
        AS fecha_min,

    MAX(fecha)
        AS fecha_max,

    COUNT(DISTINCT tipo_pago)
        AS tipos_pago_distintos,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE afluencia = 0
    ) AS afluencia_cero,

    COUNT(*) FILTER (
        WHERE afluencia <> TRUNC(afluencia)
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

FROM proyecto.tren_ligero_desglosada_clean

WHERE fecha BETWEEN DATE '2022-01-01'
                AND DATE '2026-07-31';


/* =====================================================
   3. ESTRUCTURA NATIVA fecha × tipo_pago

   Esperado por fecha:

   2 filas
   2 tipos de pago:

   Gratuidad
   Prepago
===================================================== */

WITH grupos AS (

    SELECT
        fecha,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(afluencia)
            AS valores_disponibles,

        BOOL_OR(es_colision_clave)
            AS contiene_colision,

        BOOL_OR(es_duplicado_exacto)
            AS contiene_duplicado

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
)

SELECT
    filas,
    tipos_pago,

    COUNT(*) AS fechas,

    COUNT(*) FILTER (
        WHERE contiene_colision
    ) AS fechas_con_colision,

    COUNT(*) FILTER (
        WHERE contiene_duplicado
    ) AS fechas_con_duplicado,

    COUNT(*) FILTER (
        WHERE valores_disponibles < filas
    ) AS fechas_con_afluencia_incompleta

FROM grupos

GROUP BY
    filas,
    tipos_pago

ORDER BY
    filas,
    tipos_pago;


/* =====================================================
   4. CLASIFICACIÓN EXHAUSTIVA DE FECHAS

   Una fecha segura requiere:

   - 2 filas;
   - 2 tipos_pago;
   - 0 NULL;
   - 0 colisiones.
===================================================== */

WITH grupos AS (

    SELECT
        fecha,

        COUNT(*) AS filas,

        COUNT(DISTINCT tipo_pago)
            AS tipos_pago,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS componentes_null,

        BOOL_OR(es_colision_clave)
            AS contiene_colision

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
)

SELECT
    COUNT(*) AS claves_totales,

    COUNT(*) FILTER (
        WHERE filas = 2
          AND tipos_pago = 2
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
        WHERE filas <> 2
           OR tipos_pago <> 2
    ) AS estructura_inesperada

FROM grupos;


/* =====================================================
   5. CANDIDATO DIARIO TREN LIGERO

   unidad_operativa es DERIVADA.

   NO proviene de una columna de la fuente.

   Solo se produce afluencia cuando:

   - existen 2 filas;
   - existen 2 tipos_pago;
   - no existen NULL;
   - no existen colisiones.
===================================================== */

WITH grupos AS (

    SELECT
        fecha,

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

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
),

candidato AS (

    SELECT
        fecha,

        'Sistema completo'::TEXT
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
   6. COMPROBACIÓN DE UNIDAD CONSTANTE

   Debe existir exactamente:

   1 unidad_operativa

   denominada:

   Sistema completo
===================================================== */

WITH candidato AS (

    SELECT
        fecha,

        'Sistema completo'::TEXT
            AS unidad_operativa,

        SUM(afluencia)::NUMERIC
            AS afluencia

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
)

SELECT
    unidad_operativa,

    COUNT(*) AS fechas,

    MIN(fecha) AS fecha_min,

    MAX(fecha) AS fecha_max

FROM candidato

GROUP BY unidad_operativa;


/* =====================================================
   7. PRESERVACIÓN EXACTA DE AFLUENCIA

   Suma de los componentes originales
   contra suma del candidato diario.

   Diferencia esperada:

   0
===================================================== */

WITH origen AS (

    SELECT
        SUM(afluencia)::NUMERIC
            AS afluencia_origen

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'
),

candidato AS (

    SELECT
        SUM(afluencia)::NUMERIC
            AS afluencia_diaria

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
),

agregado AS (

    SELECT
        SUM(afluencia_diaria)::NUMERIC
            AS afluencia_candidato

    FROM candidato
)

SELECT
    origen.afluencia_origen,

    agregado.afluencia_candidato,

    agregado.afluencia_candidato
        - origen.afluencia_origen
        AS diferencia

FROM origen

CROSS JOIN agregado;


/* =====================================================
   8. PRESERVACIÓN POR FECHA

   Debe existir:

   0 diferencias
===================================================== */

WITH origen AS (

    SELECT
        fecha,

        SUM(afluencia)::NUMERIC
            AS afluencia_origen

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
),

candidato AS (

    SELECT
        fecha,

        'Sistema completo'::TEXT
            AS unidad_operativa,

        SUM(afluencia)::NUMERIC
            AS afluencia_candidato

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
)

SELECT
    COUNT(*) AS fechas_comparadas,

    COUNT(*) FILTER (
        WHERE origen.afluencia_origen
              IS DISTINCT FROM
              candidato.afluencia_candidato
    ) AS fechas_con_diferencia

FROM origen

JOIN candidato
  USING (fecha);


/* =====================================================
   9. UNICIDAD DEL CANDIDATO TREN LIGERO
===================================================== */

WITH candidato AS (

    SELECT
        fecha,

        'Sistema completo'::TEXT
            AS unidad_operativa,

        SUM(afluencia)::NUMERIC
            AS afluencia

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
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


/* =====================================================
   10. COMPROBACIÓN SEMÁNTICA DEL PIPELINE

   El pipeline individual NO debe contener físicamente:

   linea
   linea_original
   unidad_operativa

   Esperado:

   0
===================================================== */

SELECT
    COUNT(*) AS columnas_operativas_artificiales

FROM information_schema.columns

WHERE table_schema = 'proyecto'

  AND table_name IN (
      'tren_ligero_desglosada_stage',
      'tren_ligero_desglosada_typed',
      'tren_ligero_desglosada_clean'
  )

  AND column_name IN (
      'linea',
      'linea_original',
      'unidad_operativa'
  );


COMMIT;


/*
=========================================================
11. EVALUACIÓN MULTISISTEMA DE SEIS SISTEMAS

Contrato:

fecha × sistema × unidad_operativa

Tren Ligero:

unidad_operativa =
'Sistema completo'

DERIVADA EXCLUSIVAMENTE PARA INTEGRACIÓN.

No materializa información.
=========================================================
*/


BEGIN TRANSACTION READ ONLY;


/* =====================================================
   11.1 CANDIDATOS DE LOS SEIS SISTEMAS
===================================================== */

WITH metro AS (

    SELECT
        'Metro'::TEXT AS sistema,
        fecha,
        linea::TEXT AS unidad_operativa,

        SUM(afluencia)::NUMERIC
            AS afluencia,

        'OK'::TEXT AS estado_calidad,

        'FUENTE'::TEXT
            AS origen_unidad_operativa

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

        afluencia::NUMERIC
            AS afluencia,

        'OK'::TEXT AS estado_calidad,

        'FUENTE'::TEXT
            AS origen_unidad_operativa

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
        END AS estado_calidad,

        'FUENTE'::TEXT
            AS origen_unidad_operativa

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
        END AS estado_calidad,

        'FUENTE'::TEXT
            AS origen_unidad_operativa

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
        END AS estado_calidad,

        'FUENTE'::TEXT
            AS origen_unidad_operativa

    FROM trolebus_grupos
),

tren_ligero_grupos AS (

    SELECT
        fecha,

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

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
),

tren_ligero AS (

    SELECT
        'Tren Ligero'::TEXT
            AS sistema,

        fecha,

        'Sistema completo'::TEXT
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
        END AS estado_calidad,

        'DERIVADA_CONSTANTE'::TEXT
            AS origen_unidad_operativa

    FROM tren_ligero_grupos
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

    UNION ALL
    SELECT * FROM tren_ligero
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
    ) AS claves_con_restriccion,

    COUNT(*) FILTER (
        WHERE origen_unidad_operativa =
              'DERIVADA_CONSTANTE'
    ) AS claves_con_unidad_derivada

FROM combinado

GROUP BY sistema

ORDER BY sistema;


/* =====================================================
   12. VALIDACIÓN GLOBAL DE LA CLAVE

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

    GROUP BY fecha, linea
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

    GROUP BY fecha, servicio
),

rtp AS (

    SELECT
        'RTP'::TEXT AS sistema,
        fecha,
        servicio::TEXT AS unidad_operativa,

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

    GROUP BY fecha, linea
),

cablebus AS (

    SELECT
        'Cablebús'::TEXT AS sistema,
        fecha,
        linea::TEXT AS unidad_operativa,

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

    GROUP BY fecha, linea
),

trolebus AS (

    SELECT
        'Trolebús'::TEXT AS sistema,
        fecha,
        linea::TEXT AS unidad_operativa,

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

tren_ligero_grupos AS (

    SELECT
        fecha,

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

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
),

tren_ligero AS (

    SELECT
        'Tren Ligero'::TEXT AS sistema,
        fecha,

        'Sistema completo'::TEXT
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

    FROM tren_ligero_grupos
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

    UNION ALL
    SELECT * FROM tren_ligero
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

    MIN(fecha) AS fecha_min,

    MAX(fecha) AS fecha_max,

    COUNT(*) FILTER (
        WHERE afluencia IS NULL
    ) AS afluencia_null,

    COUNT(*) FILTER (
        WHERE estado_calidad <> 'OK'
    ) AS claves_con_restriccion

FROM combinado;


COMMIT;


/*
=========================================================
13. DECISIÓN AUTOMÁTICA TREN LIGERO

La compatibilidad individual se considera técnicamente
válida cuando:

- existen 1,673 fechas;
- todas presentan 2 filas;
- todas presentan 2 tipos_pago;
- no existen NULL;
- no existen colisiones;
- el candidato contiene 1,673 claves;
- no existen claves duplicadas;
- la afluencia se conserva;
- el pipeline individual no contiene artificialmente
  linea/unidad_operativa.

La unidad constante sigue siendo una RESTRICCIÓN
SEMÁNTICA porque se deriva en integración.
=========================================================
*/


WITH grupos AS (

    SELECT
        fecha,

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

    FROM proyecto.tren_ligero_desglosada_clean

    WHERE fecha BETWEEN DATE '2022-01-01'
                    AND DATE '2026-07-31'

    GROUP BY fecha
),

candidato AS (

    SELECT
        fecha,

        'Tren Ligero'::TEXT AS sistema,

        'Sistema completo'::TEXT
            AS unidad_operativa,

        suma_afluencia AS afluencia,

        filas,
        tipos_pago,
        componentes_null,
        contiene_colision

    FROM grupos
),

control AS (

    SELECT

        COUNT(*) AS fechas,

        COUNT(*) FILTER (
            WHERE filas = 2
              AND tipos_pago = 2
              AND componentes_null = 0
              AND NOT contiene_colision
        ) AS fechas_ok,

        COUNT(*) -
        COUNT(
            DISTINCT (
                fecha,
                sistema,
                unidad_operativa
            )
        ) AS duplicadas,

        COUNT(*) FILTER (
            WHERE afluencia IS NULL
        ) AS afluencia_null

    FROM candidato
),

columnas_artificiales AS (

    SELECT COUNT(*) AS total

    FROM information_schema.columns

    WHERE table_schema = 'proyecto'

      AND table_name IN (
          'tren_ligero_desglosada_stage',
          'tren_ligero_desglosada_typed',
          'tren_ligero_desglosada_clean'
      )

      AND column_name IN (
          'linea',
          'linea_original',
          'unidad_operativa'
      )
)

SELECT

    control.fechas,

    control.fechas_ok,

    control.duplicadas,

    control.afluencia_null,

    columnas_artificiales.total
        AS columnas_operativas_artificiales,

    CASE

        WHEN control.fechas = 1673
         AND control.fechas_ok = 1673
         AND control.duplicadas = 0
         AND control.afluencia_null = 0
         AND columnas_artificiales.total = 0

        THEN 'APROBADO CON RESTRICCIONES'

        ELSE 'NO APROBADO'

    END AS compatibilidad_tren_ligero

FROM control

CROSS JOIN columnas_artificiales;