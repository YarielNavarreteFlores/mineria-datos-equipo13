-- Carga inicial basada en el checkpoint e610dde.
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
control AS (
    SELECT
        COUNT(*) AS claves_candidatas,
        COUNT(*) FILTER (
            WHERE ABS(afluencia) >= 10000000
               OR MIN_SCALE(afluencia) > 13
               OR afluencia = 'NaN'::numeric
        ) AS fuera_de_precision,
        NOT EXISTS (
            SELECT 1 FROM proyecto.afluencia_diaria_multisistema
        ) AS destino_vacio_al_inicio
    FROM candidato
),
insertadas AS (
    INSERT INTO proyecto.afluencia_diaria_multisistema (
        fecha, sistema, unidad_operativa, origen_unidad_operativa,
        estado_calidad, afluencia
    )
    SELECT
        c.fecha,
        c.sistema,
        c.unidad_operativa,
        CASE
            WHEN c.sistema = 'Tren Ligero' THEN 'DERIVADA_CONSTANTE'
            ELSE 'FUENTE'
        END,
        c.estado_calidad,
        c.afluencia
    FROM candidato AS c
    CROSS JOIN control AS v
    WHERE v.destino_vacio_al_inicio
      AND v.fuera_de_precision = 0
    RETURNING estado_calidad, afluencia
)
SELECT
    v.destino_vacio_al_inicio,
    v.claves_candidatas,
    v.fuera_de_precision,
    r.filas_insertadas,
    r.con_afluencia,
    r.restringidas
FROM control AS v
CROSS JOIN (
    SELECT
        COUNT(*) AS filas_insertadas,
        COUNT(afluencia) AS con_afluencia,
        COUNT(*) FILTER (WHERE estado_calidad <> 'OK') AS restringidas
    FROM insertadas
) AS r;
