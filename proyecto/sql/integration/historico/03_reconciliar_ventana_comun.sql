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
, ventana AS (
    SELECT MIN(fecha) AS inicio, MAX(fecha) AS fin
    FROM proyecto.afluencia_diaria_multisistema
),
historico_en_ventana AS (
    SELECT c.*
    FROM candidato AS c
    CROSS JOIN ventana AS v
    WHERE c.fecha BETWEEN v.inicio AND v.fin
),
comparacion AS (
    SELECT
        COALESCE(h.sistema, f.sistema) AS sistema,
        h.fecha IS NOT NULL AS en_historico,
        f.fecha IS NOT NULL AS en_fisica,
        h.afluencia IS DISTINCT FROM f.afluencia AS dif_afluencia,
        h.estado_calidad IS DISTINCT FROM f.estado_calidad AS dif_calidad,
        h.origen_unidad_operativa IS DISTINCT FROM f.origen_unidad_operativa
            AS dif_procedencia
    FROM historico_en_ventana AS h
    FULL JOIN proyecto.afluencia_diaria_multisistema AS f
        USING (fecha, sistema, unidad_operativa)
)
SELECT
    sistema,
    COUNT(*) FILTER (WHERE en_historico AND en_fisica) AS claves_comparadas,
    COUNT(*) FILTER (WHERE en_fisica AND NOT en_historico) AS faltan_en_historico,
    COUNT(*) FILTER (WHERE en_historico AND NOT en_fisica) AS sobran_en_historico,
    COUNT(*) FILTER (
        WHERE en_historico AND en_fisica AND dif_afluencia
    ) AS diferencias_afluencia,
    COUNT(*) FILTER (
        WHERE en_historico AND en_fisica AND dif_calidad
    ) AS diferencias_calidad,
    COUNT(*) FILTER (
        WHERE en_historico AND en_fisica AND dif_procedencia
    ) AS diferencias_procedencia
FROM comparacion
GROUP BY sistema
ORDER BY sistema;
