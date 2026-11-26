WITH componentes (
    sistema, fecha, unidad_operativa, componente,
    afluencia, colision, componentes_esperados
) AS (
    -- Cada estación aporta una fila al total diario de su línea.
    -- La cantidad de estaciones puede variar con la línea y el periodo.
    SELECT 'Metro', fecha, linea::text, estacion::text,
           afluencia::numeric, es_colision_clave, NULL::integer
    FROM proyecto.metro_simple_clean

    UNION ALL

    -- Simple ya está a nivel fecha × línea. Se conservan sus filas NULL.
    SELECT 'Metrobús', fecha, linea::text, 'Total de línea',
           afluencia::numeric, false, 1
    FROM proyecto.metrobus_simple_clean

    UNION ALL

    SELECT 'RTP', fecha, servicio::text, tipo_pago::text,
           afluencia::numeric, es_colision_clave, 3
    FROM proyecto.rtp_desglosada_clean

    UNION ALL

    SELECT 'Cablebús', fecha, linea::text, tipo_pago::text,
           afluencia::numeric, es_colision_clave, 2
    FROM proyecto.cablebus_desglosada_clean

    UNION ALL

    SELECT 'Trolebús', fecha, linea::text, tipo_pago::text,
           afluencia::numeric, es_colision_clave, 3
    FROM proyecto.trolebus_desglosada_clean

    UNION ALL

    SELECT 'Tren Ligero', fecha, 'Sistema completo', tipo_pago::text,
           afluencia::numeric, es_colision_clave, 2
    FROM proyecto.tren_ligero_desglosada_clean
),
por_clave AS (
    SELECT
        sistema,
        fecha,
        unidad_operativa,
        componentes_esperados,
        COUNT(*) AS filas,
        COUNT(componente) AS componentes_identificados,
        COUNT(DISTINCT componente) AS componentes_distintos,
        COUNT(afluencia) AS componentes_con_valor,
        BOOL_OR(colision) AS colision_reportada,
        SUM(afluencia) AS suma_disponible
    FROM componentes
    GROUP BY sistema, fecha, unidad_operativa, componentes_esperados
),
perfil AS (
    SELECT
        p.*,
        MIN(fecha) FILTER (WHERE componentes_con_valor > 0)
            OVER (PARTITION BY sistema, unidad_operativa) AS primer_valor,
        colision_reportada
            OR componentes_distintos < componentes_identificados AS hay_colision
    FROM por_clave AS p
),
clasificado AS (
    SELECT
        p.*,
        CASE
            WHEN hay_colision AND componentes_con_valor < filas
                THEN 'COLISION_Y_NULL'
            WHEN hay_colision
                THEN 'COLISION'
            WHEN sistema = 'Metrobús'
             AND componentes_con_valor = 0
             AND fecha < primer_valor
                THEN 'SIN_DATO_PREVIO_AL_PRIMER_VALOR'
            WHEN componentes_con_valor < filas
                THEN 'AFLUENCIA_INCOMPLETA'
            WHEN componentes_identificados <> filas
              OR (componentes_esperados IS NOT NULL
                  AND filas <> componentes_esperados)
                THEN 'ESTRUCTURA_INESPERADA'
            ELSE 'OK'
        END AS estado_calidad
    FROM perfil AS p
),
candidato AS (
    SELECT
        fecha,
        sistema,
        unidad_operativa,
        CASE
            WHEN sistema = 'Tren Ligero' THEN 'DERIVADA_CONSTANTE'
            ELSE 'FUENTE'
        END AS origen_unidad_operativa,
        estado_calidad,
        CASE WHEN estado_calidad = 'OK' THEN suma_disponible END AS afluencia
    FROM clasificado
)
SELECT
    sistema,
    estado_calidad,
    COUNT(*) AS claves,
    COUNT(afluencia) AS con_afluencia,
    COUNT(*) FILTER (WHERE afluencia IS NULL) AS sin_afluencia,
    COUNT(*) FILTER (
        WHERE fecha IS NULL OR NULLIF(btrim(unidad_operativa), '') IS NULL
    ) AS claves_incompletas,
    COUNT(*) FILTER (
        WHERE ABS(afluencia) >= 10000000
           OR MIN_SCALE(afluencia) > 13
           OR afluencia = 'NaN'::numeric
    ) AS fuera_de_numeric_20_13
FROM candidato
GROUP BY sistema, estado_calidad
ORDER BY sistema, estado_calidad;