WITH cobertura (sistema, primera_fecha, ultima_fecha) AS (
    SELECT 'Metro', MIN(fecha), MAX(fecha)
    FROM proyecto.metro_simple_clean

    UNION ALL

    SELECT 'Metrobús', MIN(fecha), MAX(fecha)
    FROM proyecto.metrobus_simple_clean

    UNION ALL

    SELECT 'RTP', MIN(fecha), MAX(fecha)
    FROM proyecto.rtp_desglosada_clean

    UNION ALL

    SELECT 'Cablebús', MIN(fecha), MAX(fecha)
    FROM proyecto.cablebus_desglosada_clean

    UNION ALL

    SELECT 'Trolebús', MIN(fecha), MAX(fecha)
    FROM proyecto.trolebus_desglosada_clean

    UNION ALL

    SELECT 'Tren Ligero', MIN(fecha), MAX(fecha)
    FROM proyecto.tren_ligero_desglosada_clean
),

ventana AS (
    SELECT
        MAX(primera_fecha) AS inicio,
        MIN(ultima_fecha) AS fin
    FROM cobertura
    HAVING COUNT(primera_fecha) = 6
       AND COUNT(ultima_fecha) = 6
       AND MAX(primera_fecha) <= MIN(ultima_fecha)
),

-- Sistemas cuya afluencia se obtiene de componentes por tipo de pago.
componentes (
    sistema, fecha, unidad, tipo_pago, afluencia, colision, esperados
) AS (
    SELECT
        'RTP', fecha, servicio::text, tipo_pago, afluencia,
        es_colision_clave, 3
    FROM proyecto.rtp_desglosada_clean

    UNION ALL

    SELECT
        'Cablebús', fecha, linea::text, tipo_pago, afluencia,
        es_colision_clave, 2
    FROM proyecto.cablebus_desglosada_clean

    UNION ALL

    SELECT
        'Trolebús', fecha, linea::text, tipo_pago, afluencia,
        es_colision_clave, 3
    FROM proyecto.trolebus_desglosada_clean

    UNION ALL

    -- 'Sistema completo' es una unidad derivada para la integración.
    SELECT
        'Tren Ligero', fecha, 'Sistema completo'::text, tipo_pago, afluencia,
        es_colision_clave, 2
    FROM proyecto.tren_ligero_desglosada_clean
),

grupos AS (
    SELECT
        sistema,
        fecha,
        unidad,
        esperados,
        COUNT(*) AS filas,
        COUNT(DISTINCT tipo_pago) AS tipos,
        COUNT(*) FILTER (WHERE afluencia IS NULL) AS faltantes,
        BOOL_OR(colision) AS hay_colision,
        SUM(afluencia::numeric) AS suma_disponible
    FROM componentes
    CROSS JOIN ventana
    WHERE fecha BETWEEN inicio AND fin
    GROUP BY sistema, fecha, unidad, esperados
),

candidato (
    sistema, fecha, unidad_operativa, estado_calidad, afluencia
) AS (
    SELECT
        sistema,
        fecha,
        unidad,
        CASE
            WHEN hay_colision AND faltantes > 0 THEN 'COLISION_Y_NULL'
            WHEN hay_colision THEN 'COLISION'
            WHEN faltantes > 0 THEN 'AFLUENCIA_INCOMPLETA'
            WHEN filas <> esperados OR tipos <> esperados
                THEN 'ESTRUCTURA_INESPERADA'
            ELSE 'OK'
        END,
        CASE
            WHEN filas = esperados
             AND tipos = esperados
             AND faltantes = 0
             AND NOT hay_colision
                THEN suma_disponible
            ELSE NULL
        END
    FROM grupos

    UNION ALL

    SELECT
        'Metro',
        fecha,
        linea::text,
        'OK',
        SUM(afluencia)::numeric
    FROM proyecto.metro_simple_clean
    CROSS JOIN ventana
    WHERE fecha BETWEEN inicio AND fin
    GROUP BY fecha, linea

    UNION ALL

    SELECT
        'Metrobús',
        fecha,
        linea::text,
        'OK',
        afluencia::numeric
    FROM proyecto.metrobus_simple_clean
    CROSS JOIN ventana
    WHERE fecha BETWEEN inicio AND fin
      AND afluencia IS NOT NULL
)

SELECT
    sistema,
    estado_calidad,
    COUNT(*) AS claves,
    COUNT(*) FILTER (
        WHERE fecha IS NULL
           OR sistema IS NULL
           OR unidad_operativa IS NULL
    ) AS claves_incompletas,
    COUNT(*) FILTER (WHERE afluencia IS NULL) AS con_afluencia_null,
    COUNT(afluencia) AS con_afluencia_conocida,
    MAX(ABS(afluencia)) AS max_afluencia_absoluta,
    MAX(MIN_SCALE(afluencia)) AS max_decimales_necesarios,
    COUNT(*) FILTER (
        WHERE ABS(afluencia) >= 10000000
           OR MIN_SCALE(afluencia) > 13
    ) AS fuera_de_numeric_20_13
FROM candidato
GROUP BY sistema, estado_calidad
ORDER BY sistema, estado_calidad;