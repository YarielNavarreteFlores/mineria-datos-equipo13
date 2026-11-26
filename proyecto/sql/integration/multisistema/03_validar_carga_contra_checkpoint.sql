-- Reconciliación de la tabla física con el checkpoint e610dde.
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
comparacion AS (
    SELECT
        COALESCE(c.sistema, f.sistema) AS sistema,
        c.fecha IS NOT NULL AS en_candidato,
        f.fecha IS NOT NULL AS en_tabla,
        c.afluencia IS DISTINCT FROM f.afluencia AS dif_afluencia,
        c.estado_calidad IS DISTINCT FROM f.estado_calidad AS dif_calidad,
        f.origen_unidad_operativa IS DISTINCT FROM
            CASE
                WHEN c.sistema = 'Tren Ligero' THEN 'DERIVADA_CONSTANTE'
                ELSE 'FUENTE'
            END AS dif_procedencia
    FROM candidato AS c
    FULL JOIN proyecto.afluencia_diaria_multisistema AS f
        USING (fecha, sistema, unidad_operativa)
)
SELECT
    sistema,
    COUNT(*) FILTER (WHERE en_candidato AND en_tabla) AS claves_comparadas,
    COUNT(*) FILTER (WHERE en_candidato AND NOT en_tabla) AS faltan_en_tabla,
    COUNT(*) FILTER (WHERE en_tabla AND NOT en_candidato) AS sobran_en_tabla,
    COUNT(*) FILTER (
        WHERE en_candidato AND en_tabla AND dif_afluencia
    ) AS diferencias_afluencia,
    COUNT(*) FILTER (
        WHERE en_candidato AND en_tabla AND dif_calidad
    ) AS diferencias_calidad,
    COUNT(*) FILTER (
        WHERE en_candidato AND en_tabla AND dif_procedencia
    ) AS diferencias_procedencia
FROM comparacion
GROUP BY sistema
ORDER BY sistema;
