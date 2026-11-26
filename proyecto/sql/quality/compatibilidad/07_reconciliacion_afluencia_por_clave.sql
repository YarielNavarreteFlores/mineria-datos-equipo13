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
,
origen (sistema, fecha, unidad_operativa, afluencia) AS (
    SELECT 'Metro', fecha, linea::text, afluencia::numeric
    FROM proyecto.metro_simple_clean
    UNION ALL
    SELECT 'Metrobús', fecha, linea::text, afluencia::numeric
    FROM proyecto.metrobus_simple_clean
    UNION ALL
    SELECT 'RTP', fecha, servicio::text, afluencia::numeric
    FROM proyecto.rtp_desglosada_clean
    UNION ALL
    SELECT 'Cablebús', fecha, linea::text, afluencia::numeric
    FROM proyecto.cablebus_desglosada_clean
    UNION ALL
    SELECT 'Trolebús', fecha, linea::text, afluencia::numeric
    FROM proyecto.trolebus_desglosada_clean
    UNION ALL
    SELECT 'Tren Ligero', fecha, 'Sistema completo', afluencia::numeric
    FROM proyecto.tren_ligero_desglosada_clean
),
origen_por_clave AS (
    SELECT
        sistema, fecha, unidad_operativa,
        COUNT(*) AS filas_origen,
        COUNT(*) FILTER (WHERE afluencia IS NULL) AS componentes_null,
        SUM(afluencia) AS suma_origen
    FROM origen
    CROSS JOIN ventana
    WHERE fecha BETWEEN inicio AND fin
    GROUP BY sistema, fecha, unidad_operativa
),
comparacion AS (
    SELECT
        COALESCE(o.sistema, c.sistema) AS sistema,
        o.filas_origen,
        o.componentes_null,
        o.suma_origen,
        c.sistema AS sistema_candidato,
        c.estado_calidad,
        c.afluencia AS afluencia_candidata
    FROM origen_por_clave AS o
    FULL JOIN candidato AS c USING (sistema, fecha, unidad_operativa)
)
SELECT
    sistema,
    COUNT(*) FILTER (WHERE sistema_candidato IS NULL) AS solo_en_origen,
    COUNT(*) FILTER (WHERE filas_origen IS NULL) AS solo_en_candidato,
    COUNT(*) FILTER (WHERE estado_calidad = 'OK') AS claves_ok,
    COUNT(*) FILTER (
        WHERE estado_calidad = 'OK'
          AND (
              componentes_null > 0
              OR afluencia_candidata IS NULL
              OR afluencia_candidata IS DISTINCT FROM suma_origen
          )
    ) AS claves_ok_con_diferencia,
    COUNT(*) FILTER (WHERE estado_calidad <> 'OK') AS claves_restringidas,
    COUNT(*) FILTER (
        WHERE estado_calidad <> 'OK' AND afluencia_candidata IS NOT NULL
    ) AS restringidas_con_valor
FROM comparacion
GROUP BY sistema
ORDER BY sistema;
